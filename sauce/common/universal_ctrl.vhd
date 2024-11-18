
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.NUMERIC_STD_UNSIGNED.all;
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
    
    i_i_data_fifo_data      : in  data_bus;
    i_i_data_fifo_ready     : in  out_ready;
    o_i_data_fifo_next      : out in_pulse;

    o_o_data_fifo_data      : out data_bus;
    o_o_data_fifo_ready     : out out_ready;
    i_o_data_fifo_next      : in  in_pulse;
  
    i_i_info_fifo_data      : in  info_bus;
    i_i_info_fifo_ready     : in  out_ready;
    o_i_info_fifo_next      : out in_pulse;

    o_o_info_fifo_data      : out info_bus;
    o_o_info_fifo_ready     : out out_ready;
    i_o_info_fifo_next      : in  in_pulse;

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
    st_downstr_IDLE,
    st_downstr_CHECK,
    st_downstr_REGS,
    st_downstr_DATA
  );
  type t_upstr_state is (
    st_upstr_IDLE,
    st_upstr_DATA,
    st_upstr_REGS,
    st_upstr_CHECK
  );
  type t_updownstr_state is (
    st_updown_IDLE,
    st_updown_CHECK_U,
    st_updown_REGS_U,
    st_updown_DATA_U,
    st_updown_CHECK_D,
    st_updown_REGS_D,
    st_updown_DATA_D
  );

  signal r_registers    : std_logic_array (1 to 3) (MSG_W-1 downto 0);
  signal flags          : std_logic_vector(MSG_W-1 downto 0);

  signal msg_i_vld      : std_logic;
  signal msg_o_vld      : std_logic;
  signal msg_i_dat      : STD_LOGIC_VECTOR(MSG_W-1 downto 0);
  signal msg_o_dat      : STD_LOGIC_VECTOR(MSG_W-1 downto 0);
  signal out_busy       : std_logic;

  signal clk_div        : std_logic_vector(15 downto 0);

  signal inf_rdy_strb   : std_logic;
  signal inf_reg        : STD_LOGIC_VECTOR(3*MSG_W-1 downto 0);

  signal reg_op         : STD_LOGIC_VECTOR(2*MSG_W-1 downto 0);
  signal reg_op_rdy_strb: std_logic;

  signal rst_n          : std_logic;
  signal clk_en         : std_logic;
  signal en_rst         : std_logic;

  signal timeout_reg    : std_logic_vector(15 downto 0);
  signal timeout_s      : std_logic;
  signal timeout_rst    : std_logic;

  alias clk_div_sel     : std_logic_vector(2 downto 0) is r_registers(1)(2 downto 0);
  constant start_polarity  : std_logic := '0';
  alias auto_flag_rep   : std_logic is r_registers(1)(3);
  alias allow_unexp_msg : std_logic is r_registers(1)(4);
  alias interrupt_en    : std_logic is r_registers(1)(5);
  alias parity_en       : std_logic is r_registers(1)(6);
  alias timeout_en      : std_logic is r_registers(1)(7);

  alias parity_odd     : std_logic is r_registers(2)(6);
  alias rst_r           : std_logic is r_registers(2)(7);
  alias timeout_val     : std_logic_vector(5 downto 0) is r_registers(2)(5 downto 0);

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
  alias data_reg_op        : std_logic_vector(MSG_W-1 downto 0)     is reg_op(7 downto 0);
  alias id_reg_op          : std_logic_vector(USER_ID_W-1 downto 0) is reg_op(15 downto 14);
  alias reg_reg_op         : std_logic_vector(1 downto 0)           is reg_op(12 downto 11);
  alias read_reg_op        : std_logic                              is reg_op(13);
begin
  register_selection := to_integer(unsigned(reg_reg_op));
  if rising_edge(clk_en) then 
    inf_rdy_strb <= '0';
    if (i_rst_n = '0' or en_rst = '1') then
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
  variable step : natural range 0 to 1118481;
begin
  if rising_edge (clk_en) then
    if (clk_div(14 downto 0) & "0") = timeout_reg then
      timeout_s <= '1';
    else
      timeout_s <= '0';
    end if;
    if (timeout_rst = '1') then
      timeout_reg <= (others => '0');
      step := 0;
    elsif timeout_s = '0'then
      step := step + 1;
    end if;
    if step = (clk_div & x"00") then
      timeout_reg <= timeout_reg + 1;
      step := 0;
    end if;
  end if;
end process;
----------------------------------------------------------------------------------------
--#SECTION - STREAM  CONTROL GENERATION
----------------------------------------------------------------------------------------
g_duplex : if BUS_MODE = t_bus_UART or BUS_MODE = t_bus_SPI generate
----------------------------------------------------------------------------------------
--#SECTION - FULL DUPLEX
----------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
--#ANCHOR - DOWNSTREAM (from fifo)
----------------------------------------------------------------------------------------
p_downstream  : process (clk_en)
  variable st_downstr:  t_downstr_state := st_downstr_IDLE;
  variable data_cnt : natural range 0 to 255  := 0;
  variable last_out_state : STD_LOGIC;
begin
  if rising_edge(clk_en) then
    reg_op_rdy_strb <= '0';
    o_i_data_fifo_next <= '0';
    o_i_info_fifo_next <= '0';
    msg_i_vld <= '0';
    if (rst_n = '0')then
      st_downstr := st_downstr_IDLE;
      reg_op <= (others => '0');
      data_cnt := 0;
      last_out_state := '0';
      msg_i_dat <= (others => '0');
    else
      case( st_downstr ) is
        when st_downstr_IDLE =>
          data_cnt := 0;
          if i_i_info_fifo_ready = '1' then
            st_downstr := st_downstr_CHECK;
          end if;
        when st_downstr_CHECK =>
          if i_i_info_fifo_data(MSG_W*2+4 downto MSG_W*2+3) /= "00" then
            reg_op <= i_i_info_fifo_data(3 * MSG_W - 1 downto MSG_W);
            st_downstr := st_downstr_REGS;
            reg_op_rdy_strb <= '1';
          else
            data_cnt := to_integer(unsigned(i_i_info_fifo_data(7+MSG_W downto MSG_W)));
            st_downstr := st_downstr_DATA;
          end if;
            o_i_info_fifo_next <= '1';
        when st_downstr_REGS =>
          if inf_rdy_strb = '1' then
            st_downstr := st_downstr_IDLE;
          end if;
        when st_downstr_DATA =>
          if data_cnt > 0 then
            if data_cnt = to_integer(unsigned(i_i_info_fifo_data(7+MSG_W downto MSG_W))) or (out_busy = '0' and last_out_state = '1') then
              if  i_i_data_fifo_ready = '1' then
                data_cnt := data_cnt - 1;
                msg_i_dat <= i_i_data_fifo_data;
                msg_i_vld <= '1';
              end if;
            elsif last_out_state = '0' then
              o_i_data_fifo_next <= '1';
            end if;
            last_out_state := out_busy;
          elsif out_busy = '0' then
            st_downstr := st_downstr_IDLE;
          end if;
        when others =>
        st_downstr := st_downstr_IDLE;
      end case ;
    end if;
  end if;
end process;
----------------------------------------------------------------------------------------
--#ANCHOR - UPSTREAM (to fifo)
----------------------------------------------------------------------------------------
p_upstream  : process (clk_en)
  variable st_upstr:  t_upstr_state := st_upstr_IDLE;
  variable data_cnt : natural range 0 to 255  := 0;
  variable last_out_state : STD_LOGIC;
  variable cmd      : STD_LOGIC_VECTOR(2*MSG_W-1 downto 0);
begin
  if rising_edge(clk_en) then
    timeout_rst <= '0';
    o_o_data_fifo_ready <= '0';
    flags(7) <= '0';
    if rst_n = '0' then
      st_upstr := st_upstr_IDLE;
      data_cnt := 0;
      o_o_data_fifo_data <= (others => '0');
    else
      case st_upstr is
        when st_upstr_IDLE =>
          timeout_rst <= '1';
          o_o_info_fifo_ready <= '0';
          if i_i_info_fifo_ready = '1' and i_i_info_fifo_data(MSG_W*2+4 downto MSG_W*2+3) = "00" then
            data_cnt := 0;
            cmd := i_i_info_fifo_data(3*MSG_W-1 downto 2*MSG_W) &  i_i_info_fifo_data(1*MSG_W-1 downto 0*MSG_W);
            st_upstr := st_upstr_DATA;
          elsif inf_rdy_strb = '1' then
            st_upstr := st_upstr_REGS;
            o_o_info_fifo_data <= cmd & std_logic_vector(to_unsigned(0,MSG_W));
          end if;
        when st_upstr_REGS =>
          o_o_info_fifo_ready <= '1';
          st_upstr := st_upstr_IDLE;
        when st_upstr_DATA =>
          if out_busy = '1' or data_cnt < cmd(MSG_W-1 downto 0) then
            if timeout_s = '1' then
              st_upstr := st_upstr_CHECK;
              flags(7) <= '1';
            end if;
            if msg_o_vld = '1' then
              timeout_rst <= '1';
              o_o_data_fifo_data <= msg_o_dat;
              o_o_data_fifo_ready <= '1';
              data_cnt := data_cnt + 1;
            end if;
          else
            st_upstr := st_upstr_CHECK;
          end if;
        when st_upstr_CHECK =>
            if r_registers(3) = x"00" then
              o_o_info_fifo_data <= (cmd and "1101111111111111") & x"00";
            elsif auto_flag_rep = '1' then
              o_o_info_fifo_data <= (cmd(15 downto 8) & r_registers(3));
            end if;
            o_o_info_fifo_ready <= '1';
            st_upstr := st_upstr_IDLE;
        when others =>
          st_upstr := st_upstr_IDLE;
      end case;
    end if;
  end if;
end process p_upstream;

--#!SECTION
else generate
----------------------------------------------------------------------------------------
--#SECTION - HALF DUPLEX
----------------------------------------------------------------------------------------
--#!SECTION
end generate;
--#!SECTION
----------------------------------------------------------------------------------------
--#SECTION - BUS CONTROLLER GENERATION
----------------------------------------------------------------------------------------
  g_interface : case BUS_MODE generate
----------------------------------------------------------------------------------------
--#ANCHOR - UART
----------------------------------------------------------------------------------------
    when t_bus_UART =>
    p_clk_div_sel : process (clk_div_sel)
    begin
      case( to_integer(unsigned(clk_div_sel)) ) is
        when 0 =>
          clk_div <= x"208D";
        when 1 =>
          clk_div <= x"1047";
        when 2 =>
          clk_div <= x"0823";
        when 3 =>
          clk_div <= x"0412";
        when 4 =>
          clk_div <= x"0209";
        when 5 =>
          clk_div <= x"0104";
        when 6 =>
          clk_div <= x"00AE";
        when 7 =>
          clk_div <= x"0057";
        when others =>
          clk_div <= x"208D";
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
      i_start_pol => start_polarity,
      i_par_en => parity_en,
      i_par_type => parity_odd,
      i_clk_div => unsigned(clk_div),
      o_msg => msg_o_dat,
      o_msg_vld_strb => msg_o_vld,
      o_err_noise_strb => flags(7),
      o_err_frame_strb => flags(0),
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
      i_msg_vld  => msg_i_vld,
      i_start_pol => start_polarity,
      i_par_en => parity_en,
      i_par_type => parity_odd,
      i_clk_div => unsigned(clk_div),
      o_tx => comm_wire_1,
      o_busy => out_busy
    );
  
    when others =>
    
  end generate; --#!SECTION


end architecture; --#!SECTION