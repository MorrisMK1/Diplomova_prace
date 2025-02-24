
library ieee;
  use ieee.std_logic_1164.ALL;
  use ieee.numeric_std.all;
  use ieee.std_logic_unsigned.all;
library work;
  use work.my_common.all;

----------------------------------------------------------------------------------------
-- #ANCHOR - ENTITY
----------------------------------------------------------------------------------------
entity uart_ctrl is
  generic (
    constant  MSG_W         : natural := 8;             -- message width
    constant  SMPL_W        : natural := 8;             -- rx line sample width
    constant  START_OFFSET  : natural := 10;            -- offset in clks between start and first bit
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
    i_o_data_fifo_ready     : in  out_ready;
    o_o_data_fifo_next      : out in_pulse;
  
    i_i_info_fifo_data      : in  info_bus;
    i_i_info_fifo_ready     : in  out_ready;
    o_i_info_fifo_next      : out in_pulse;

    o_o_info_fifo_data      : out info_bus;
    i_o_info_fifo_ready     : in  out_ready;
    o_o_info_fifo_next      : out in_pulse;

    tx                      : out std_logic;
    rx                      : in std_logic := '1';

    tx_ready                : in std_logic := '1';
    rx_ready                : out std_logic
  );
end uart_ctrl;

----------------------------------------------------------------------------------------
--#SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture behavioral of uart_ctrl is

  type t_downstr_state is (
    st_downstr_IDLE,
    st_downstr_CHECK,
    st_downstr_REGS,
    st_downstr_DATA,
    st_downstr_SYNC
  );
  type t_upstr_state is (
    st_upstr_IDLE,
    st_upstr_DATA,
    st_upstr_REGS,
    st_upstr_CHECK,
    st_upstr_RPRT,
    st_upstr_SYNC
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

  signal internal_rx, internal_tx : std_logic;

  signal r_registers    : std_logic_array (1 to 3) (MSG_W-1 downto 0);
  signal flags          : std_logic_vector(MSG_W-1 downto 0);
  signal flag_rst       : std_logic;

  signal msg_i_vld      : std_logic;
  signal msg_o_vld      : std_logic;
  signal msg_i_dat      : STD_LOGIC_VECTOR(MSG_W-1 downto 0);
  signal msg_o_dat      : STD_LOGIC_VECTOR(MSG_W-1 downto 0);
  signal out_busy       : std_logic;
  signal rx_busy       : std_logic;

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

  constant start_polarity  : std_logic := '0';
  alias clk_div_sel     : std_logic_vector(2 downto 0) is r_registers(1)(2 downto 0);
  alias auto_flag_rep   : std_logic_vector(1 downto 0) is r_registers(1)(4 downto 3);
  alias parity_en       : std_logic is r_registers(1)(5);
  alias parity_odd      : std_logic is r_registers(1)(6);
  alias rst_r           : std_logic is r_registers(1)(7);

  alias timeout_val     : std_logic_vector(4 downto 0) is r_registers(2)(4 downto 0);
  alias ready_en        : std_logic is r_registers(2)(5);
  alias polarity        : std_logic is r_registers(2)(6);

  alias flg_frame       : std_logic is flags(0);
  alias flg_parity      : std_logic is flags(1);
  alias flg_undef_2     : std_logic is flags(2);
  alias flg_data_size   : std_logic is flags(3);
  alias flg_info_size   : std_logic is flags(4);
  alias flg_undef_5     : std_logic is flags(5);
  alias flg_disconnect  : std_logic is flags(6);
  alias flg_noise       : std_logic is flags(7);

begin
----------------------------------------------------------------------------------------
--#ANCHOR - Config signals
----------------------------------------------------------------------------------------
rst_n <= i_rst_n and not rst_r and not en_rst;
clk_en <= i_clk and i_en;
tx <= not internal_tx when (polarity = '1') else internal_tx ;
internal_rx <= not rx when (polarity = '1') else rx ;
flg_undef_2 <= '0'; 
flg_undef_5 <= '0'; 

----------------------------------------------------------------------------------------
--#ANCHOR - Auto reset after enable
----------------------------------------------------------------------------------------
--  generating reset pulse after enabling interface to ensure indentical start state
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
    -- internal reset from registr should not reset registers
    if (i_rst_n = '0' or en_rst = '1') then
      for i in 1 to 3 loop
        r_registers(i) <= (others => '0');
      end loop;
      inf_reg <= (others => '0');
    else
      rst_r <= '0'; -- internal reset is only a strobe
      if reg_op_rdy_strb = '1' then
        if read_reg_op = '0' and (reg_reg_op(0) xor reg_reg_op(1)) = '1' then
          r_registers(register_selection) <= data_reg_op;
        end if;
        if read_reg_op = '1' then
          inf_reg <= id_reg_op & "0" & reg_reg_op & MY_ID & r_registers(register_selection) & x"00";
          inf_rdy_strb <= '1';
        end if;
        -- register 3 will be reset after every interaction
        if register_selection = 3 then
          r_registers(3) <= (others => '0') ;
        end if;
      end if;
    end if;
    -- separate capturing of flags, they are strobed
    if flag_rst = '1' then
      r_registers(3) <= (others => '0');
    else
      for i in flags'range loop
        if flags(i) = '1' then
          r_registers(3)(i) <= '1';
        end if;
      end loop;
    end if;
  end if;
end process p_cfg_manager;

----------------------------------------------------------------------------------------
--#ANCHOR - Timeout counter
----------------------------------------------------------------------------------------
p_timeout : process (clk_en)
  variable step : natural range 0 to 1048575;
  variable offset : std_logic_vector(clk_div'length downto 0);
begin
  -- timeout is counted from last recieved byte (if no bytes yet recieved it is timed by last send byte)
  if rising_edge (clk_en) then
    --TODO - FINISH TIMEOUT
  end if;
end process;
----------------------------------------------------------------------------------------
--#SECTION - STREAM  CONTROL
----------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
--#ANCHOR - DOWNSTREAM (from fifo)
----------------------------------------------------------------------------------------
p_downstream  : process (clk_en)
  variable st_downstr:  t_downstr_state := st_downstr_IDLE;
  variable data_cnt : natural range 0 to 255  := 0;
begin
  if rising_edge(clk_en) then
    if (rst_n = '0')then
      st_downstr := st_downstr_IDLE;
      reg_op <= (others => '0');
      data_cnt := 0;
      msg_i_dat <= (others => '0');
      reg_op_rdy_strb <= '0';
      o_i_data_fifo_next <= '0';
      o_i_info_fifo_next <= '0';
      msg_i_vld <= '0';
      flg_data_size <= '0';
    else
      reg_op_rdy_strb <= '0';
      o_i_data_fifo_next <= '0';
      o_i_info_fifo_next <= '0';
      msg_i_vld <= '0';
      flg_data_size <= '0';
      case( st_downstr ) is
        when st_downstr_IDLE =>
          if (i_i_info_fifo_ready = '1' and (tx_ready = '1' or ready_en = '0')) then
            
          end if;
        when st_downstr_CHECK =>

        when st_downstr_REGS =>

        when st_downstr_DATA =>

        when st_downstr_SYNC =>

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
  variable last_in_state : STD_LOGIC;
  variable cmd      : STD_LOGIC_VECTOR(2*MSG_W-1 downto 0);
begin
  if rising_edge(clk_en) then
    timeout_rst <= '0';
    flag_rst <= '0';
    if rst_n = '0' then
      st_upstr := st_upstr_IDLE;
      data_cnt := 0;
      o_o_data_fifo_data <= (others => '0');
      o_o_info_fifo_data <= (others => '0'); 
      flag_rst <= '1';
      o_o_info_fifo_next <= '0';
      o_o_data_fifo_next <= '0';
    else
      o_o_data_fifo_next <= '0';
      o_o_info_fifo_next <= '0';
      o_o_data_fifo_data <= (others => '0');
      o_o_info_fifo_data <= (others => '0'); 
      case st_upstr is
        when st_upstr_IDLE =>

        when st_upstr_REGS =>

        when st_upstr_DATA =>

        when st_upstr_CHECK =>
        
        when st_upstr_RPRT =>
        
        when st_upstr_SYNC =>
        
        when others =>
          st_upstr := st_upstr_IDLE;
      end case;
    end if;
  end if;
end process p_upstream;

----------------------------------------------------------------------------------------
--#SECTION - UART
----------------------------------------------------------------------------------------

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
      i_rx => internal_rx,
      i_start_pol => start_polarity,
      i_par_en => parity_en,
      i_par_type => parity_odd,
      i_clk_div => unsigned(clk_div),
      o_msg => msg_o_dat,
      o_busy => rx_busy,
      o_msg_vld_strb => msg_o_vld,
      o_err_noise_strb => flg_noise,
      o_err_frame_strb => flg_frame,
      o_err_par_strb => flg_parity
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
      o_tx => internal_tx,
      o_busy => out_busy
    );
  
    

end architecture; --#!SECTION