
library ieee;
  use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
library work;
use work.my_common.all;

----------------------------------------------------------------------------------------
-- #ANCHOR - ENTITY
----------------------------------------------------------------------------------------
entity universal_ctrl is
  generic (
    constant  MSG_W         : natural := 8;             -- message width
    constant  SMPL_W        : natural := 8;             -- rx line sample width
    constant  START_OFFSET  : natural := 10;            -- offset in clks between start and first bit
    constant  BUS_MODE      : t_bus_type := t_bus_UART; -- type of bus
    constant  MY_ID         : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0) := "000"
  );
  port (
    i_clk                   : in  std_logic;
    i_rst_n                 : in  std_logic;
    i_en                    : in  std_logic := '1';
    
    i_data                  : inout fifo_bus;         -- input bus from fifo

    o_data                  : inout fifo_bus;         -- output bus to fifo

    i_info_bus              : inout info_bus;         -- input information bus

    o_info_bus              : inout info_bus;         -- output information bus

    comm_wire_0             : inout std_logic := 'Z';
    comm_wire_1             : inout std_logic := 'Z';
    SPI_device_sel          : out STD_LOGIC_VECTOR(MSG_W-1 downto 0) := (others => 'Z')
  );
end universal_ctrl;

----------------------------------------------------------------------------------------
--#SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture behavioral of universal_ctrl is

  type t_downstr_state is (
    t_downstr_IDLE,
    t_downstr_CHECK,
    t_downstr_REGS,
    t_downstr_DATA
  );
  type t_upstr_state is (
    t_upstr_IDLE,
    t_upstr_DATA,
    t_upstr_REGS,
    t_upstr_CHECK
  );

  signal r_registers    : std_logic_array (1 to 3) (MSG_W-1 downto 0);
  signal flags          : std_logic_vector(MSG_W-1 downto 0);

  signal msg_i_vld      : std_logic;
  signal msg_o_vld      : std_logic;
  signal msg_i_dat      : STD_LOGIC_VECTOR(MSG_W-1 downto 0);
  signal msg_o_dat      : STD_LOGIC_VECTOR(MSG_W-1 downto 0);
  signal msg_i_rdy      : std_logic;
  signal out_busy       : std_logic;

  signal clk_div        : std_logic_vector(15 downto 0);

  signal inf_rdy_strb   : std_logic;
  signal inf_reg        : STD_LOGIC_VECTOR(2*MSG_W-1 downto 0);

  signal reg_op         : STD_LOGIC_VECTOR(2*MSG_W-1 downto 0);
  signal reg_op_rdy_strb: std_logic;

  signal rst_n          : std_logic;
  signal clk_en         : std_logic;
  signal en_rst         : std_logic;

  signal upstrm_cmd     : STD_LOGIC_VECTOR(2*MSG_W-1 downto 0);
  signal upstrm_cmd_vld : std_logic;

  signal timeout_reg    : std_logic_vector(15 downto 0);
  signal timeout_s      : std_logic;
  signal timeout_rst    : std_logic;

  alias clk_div_sel     : UNSIGNED  is r_registers(1)(3 downto 0);
  alias set_0           : std_logic is r_registers(1)(4);
  alias set_1           : std_logic is r_registers(1)(5);
  alias set_2           : std_logic is r_registers(1)(6);
  alias set_3           : std_logic is r_registers(1)(7);

  alias rst_r           : std_logic is r_registers(2)(0);
  alias err_rep         : std_logic is r_registers(2)(1);
  alias stat_rep        : std_logic is r_registers(2)(2);
begin
----------------------------------------------------------------------------------------
--#ANCHOR - Config signals
----------------------------------------------------------------------------------------
rst_n <= i_rst_n and not rst_r and not en_rst;
clk_en <= i_clk and i_en;

----------------------------------------------------------------------------------------
--#ANCHOR - Auto reset after enable
----------------------------------------------------------------------------------------
p_en_autorst  : process (i_clk)
  variable last_en    : std_logic;
begin
  if rising_edge(i_clk) then
    if i_rst_n = '0' then
      en_rst <= '0';
    elsif i_en = '0' then
      en_rst <= '1';
    elsif last_en = i_en then
      en_rst <= '0';
    end if;
    last_en := i_en;
  end if;
end process;

----------------------------------------------------------------------------------------
--#ANCHOR - Config manager
----------------------------------------------------------------------------------------
p_cfg_manager : process (clk_en)
  variable register_selection : natural range 0 to 3;
  variable data_reg_op        : std_logic_vector(MSG_W-1 downto 0);
  variable id_reg_op          : std_logic_vector(USER_ID_W-1 downto 0);
  variable reg_reg_op         : std_logic_vector(1 downto 0);
  variable read_reg_op        : std_logic;
begin
  if rising_edge(clk_en) then
    inf_rdy_strb <= '0';
    reg_reg_op := reg_op(12 downto 11);
    register_selection := to_integer(unsigned(reg_reg_op));
    data_reg_op := reg_op(7 downto 0);
    id_reg_op := reg_op(15 downto 14);
    read_reg_op := reg_op(13);
    if (rst_n = '0') then
      for i in 1 to 3 loop
        r_registers(i) <= (others => '0');
      end loop;
      inf_reg <= (others => '0');
    else
      if reg_op_rdy_strb = '1' then
        if read_reg_op = '0' and (reg_reg_op(0) xor reg_reg_op(1)) = '1' then
          r_registers(register_selection) <= data_reg_op;
        end if;
        if read_reg_op = '1' then
          inf_reg <= id_reg_op & "0" & reg_reg_op & MY_ID & r_registers(register_selection);
          inf_rdy_strb <= '1';
        end if;
        if register_selection = 3 then
          r_registers(3) <= (others => '0') ;
        end if;
      end if;
    end if;
    for i in flags'range loop
      if flags(i) = '1' then
        r_registers(3)(i) <= '1';
      end if;
    end loop;
  end if;
end process p_cfg_manager;

----------------------------------------------------------------------------------------
--#ANCHOR - Timeout counter
----------------------------------------------------------------------------------------
p_timeout : process (clk_en)
begin
  if rising_edge (clk_en) then
    if (clk_div(14 downto 0) & "0") = timeout_reg then
      timeout_s <= '1';
    else
      timeout_s <= '0';
    end if;
    if (timeout_rst = '1') then
      timeout_reg <= (others => '0');
    elsif timeout_s = '0'then
      timeout_reg <= timeout_reg + 1;
    end if;
  end if;
end process;
----------------------------------------------------------------------------------------
--#SECTION - STREAM CONTROL
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--#ANCHOR - DOWNSTREAM (from fifo)
----------------------------------------------------------------------------------------
p_downstream  : process (clk_en)
  variable st_downstr:  t_downstr_state := t_downstr_IDLE;
  variable data_cnt : natural range 0 to 255  := 0;
  variable last_out_state : STD_LOGIC;
begin
  if rising_edge(clk_en) then
    reg_op_rdy_strb <= '0';
    i_data.step <= '0';
    i_info_bus.step <= '0';
    upstrm_cmd_strb <= '0';
    msg_i_rdy <= '0';
    if (rst_n = '0')then
      st_downstr <= t_downstr_IDLE;
      reg_reg_op <= (others => '0');
      data_cnt <= 0;
      last_out_state <= '0';
    else
      case( st_downstr ) is
        when t_downstr_IDLE =>
          data_cnt <= 0;
          if i_info_bus.ready = '1' then
            st_downstr <= t_downstr_CHECK;
          end if;
        when t_downstr_CHECK =>
          if i_info_bus.data(12 downto 11) /= "00" then
            reg_op <= i_info_bus.data;
            st_downstr <= t_downstr_REGS;
          else
            upstrm_cmd <= i_info_bus.data(15 downto 8) & i_data.data;
            data_cnt <= unsigned(i_info_bus.data(7 downto 0));
            st_downstr <= t_downstr_DATA;
            if i_info_bus.data(13) = '1' then
              i_data.step <= '1';
            end if;
          end if;
        when t_downstr_REGS =>
          reg_op_rdy_strb <= '1';
          i_info_bus.step <= '1';
          st_downstr <= t_downstr_IDLE;
        when t_downstr_DATA =>
          upstrm_cmd_vld <= '1';
          if data_cnt > 0 then
            if out_busy = '0' then
              if i_data.ready = '1' then
                data_cnt := data_cnt - 1;
                msg_i_dat <= i_data.data;
                msg_i_rdy <= '1';
              end if;
            elsif last_out_state = '0' then
              i_data.step <= '1';
            end if;
            last_out_state := out_busy;
          elsif out_busy = '0' then
            st_downstr := t_downstr_IDLE;
          end if;
        when others =>
        st_downstr := t_downstr_IDLE;
      end case ;
    end if;
  end if;
end process;
----------------------------------------------------------------------------------------
--#ANCHOR - UPSTREAM (to fifo)
----------------------------------------------------------------------------------------
p_upstream  : process (clk_en)
  variable st_upstr:  t_upstr_state := t_upstr_IDLE;
  variable data_cnt : natural range 0 to 255  := 0;
  variable last_out_state : STD_LOGIC;
  variable cmd      : STD_LOGIC_VECTOR(2*MSG_W-1 downto 0);
begin
  if rising_edge(clk_en) then
    o_info_bus.ready <= '0';
    timeout_rst <= '0';
    o_data.step <= '0';
    flags(7) <= '0';
    if rst_n = '0' then
      st_upstr := t_upstr_IDLE;
      data_cnt := 0;
    else
      case st_upstr is
        when t_upstr_IDLE =>
          data_cnt := 0;
          if (inf_rdy_strb = '1') then
            st_upstr := t_upstr_REGS;
            cmd := inf_reg;
          elsif (upstrm_cmd_vld = '1') then
            st_upstr := t_upstr_DATA;
            cmd := upstrm_cmd;
            data_cnt := upstrm_cmd(7 downto 0);
            timeout_rst <= '1';
          end if;
        when t_upstr_REGS =>
          o_info_bus.data <= cmd;
          o_info_bus.ready <= '1';
          st_upstr := t_upstr_IDLE;
        when t_upstr_DATA =>
          if data_cnt > 0 then
            if timeout_s = '1' then
              st_upstr <= t_upstr_CHECK;
              flags(7) <= '1';
            end if;
            if msg_o_vld = '1' then
              timeout_rst <= '1';
              o_data.data <= msg_o_dat;
              o_data.step <= '1';
            end if;
          else
            st_upstr <= t_upstr_CHECK;
          end if;
        when t_upstr_CHECK =>
            if r_registers(3) = x"00" then
              o_info_bus.data <= (cmd and "11011111");
              o_info_bus.ready <= '1';
            elsif err_rep = '1' then
              o_info_bus.data <= (cmd(15 downto 8) & r_registers(3));
              o_info_bus.ready <= '1';
            end if;
            st_upstr := t_upstr_IDLE;
        when others =>
          st_upstr := t_upstr_IDLE;
      end case;
    end if;
  end if;
end process p_upstream;

--#!SECTION
----------------------------------------------------------------------------------------
--#SECTION - BUS CONTROLLER GENERATION
----------------------------------------------------------------------------------------
  g_interface : case BUS_MODE generate
----------------------------------------------------------------------------------------
--#ANCHOR - UART
----------------------------------------------------------------------------------------
    when t_bus_UART =>
    p_clk_div_sel : process
    begin
      case( clk_div_sel ) is
        when 0 =>
          clk_div <=x"208D";
        when 1 =>
          clk_div <=x"1047";
        when 2 =>
          clk_div <=x"823";
        when 3 =>
          clk_div <=x"412";
        when 4 =>
          clk_div <=x"209";
        when 5 =>
          clk_div <=x"104";
        when 6 =>
          clk_div <=x"AE";
        when 7 =>
          clk_div <=x"57";
      end case ;
    end process;

    uart_rx_inst : entity work.uart_rx
    generic map (
      MSG_W => MSG_W,
      SMPL_W => SMPL_W,
      START_OFFSET => START_OFFSET
    )
    port map (
      i_clk => clk_en,
      i_rst_n => rst_n,
      i_rx => comm_wire_0,
      i_start_pol => set_1,
      i_par_en => set_0,
      i_par_type => set_2,
      i_clk_div => unsigned(clk_div),
      o_msg => msg_o_dat,
      o_msg_vld_strb => msg_o_vld,
      o_err_noise_strb => flags(0),
      o_err_frame_strb => flags(1),
      o_err_par_strb => flags(2)
    );
  
    uart_tx_inst : entity work.uart_tx
    generic map (
      MSG_W => MSG_W,
      SMPL_W => SMPL_W
    )
    port map (
      i_clk => clk_en,
      i_rst_n => rst_n,
      i_msg => msg_i_dat,
      i_msg_vld  => msg_i_rdy,
      i_start_pol => set_1,
      i_par_en => set_0,
      i_par_type => set_2,
      i_clk_div => unsigned(clk_div),
      o_tx => comm_wire_1,
      o_busy => out_busy
    );
  
    when others =>
    
  end generate; --#!SECTION


end architecture; --#!SECTION