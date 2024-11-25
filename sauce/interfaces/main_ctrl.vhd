library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.NUMERIC_STD_UNSIGNED.all;
library work;
use work.my_common.all;

----------------------------------------------------------------------------------------
-- #ANCHOR - ENTITY
----------------------------------------------------------------------------------------
entity main_ctrl is
  port (
    i_clk   : in std_logic;
    i_rst_n : in std_logic;

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

    i_settings              : in  std_logic_array (1 to 2) (MSG_W-1 downto 0);
    o_flags                 : out std_logic_vector(MSG_W-1 downto 0);

    comm_wire_0             : inout std_logic := 'Z';
    comm_wire_1             : inout std_logic := 'Z'
  );
end entity;

architecture behavioral of main_ctrl is

  type fsm_reciever is (
    st_reciever_idle,
    st_reciever_h_info,
    st_reciever_h_data,
    st_reciever_h_back,
    st_reciever_data
  );

  signal start_pol        : std_logic;
  signal par_en           : std_logic;
  signal par_type         : std_logic;
  signal clk_div          : unsigned(15 downto 0);
  signal o_msg            : std_logic_vector(MSG_W-1 downto 0);
  signal o_msg_vld_strb   : std_logic;
  signal o_busy_rx        : std_logic;
  signal o_err_noise_strb : std_logic;
  signal o_err_frame_strb : std_logic;
  signal o_err_par_strb   : std_logic;

  signal i_msg            : std_logic_vector(MSG_W-1 downto 0);
  signal i_msg_vld        : std_logic;
  signal o_busy_tx        : std_logic;

  signal timeout_s        : std_logic;

  alias clk_div_sel       : std_logic_vector(2 downto 0) is i_settings(1)(2 downto 0);
  alias auto_flag_rep     : std_logic is i_settings(1)(3);
  alias parity_en         : std_logic is i_settings(1)(5);
  alias parity_odd        : std_logic is i_settings(1)(6);

  alias timeout_val       : std_logic_vector(4 downto 0) is i_settings(2)(4 downto 0);
  alias timeout_en        : std_logic is i_settings(2)(5);
  alias allow_unexp_msg   : std_logic is i_settings(2)(6);


begin

----------------------------------------------------------------------------------------
--#ANCHOR - Timeout counter
----------------------------------------------------------------------------------------
p_timeout : process (i_clk)
  variable step : natural range 0 to 1048575;
  variable offset : std_logic_vector(clk_div'length downto 0);
begin
  -- timeout is counted from last recieved byte (if no bytes yet recieved it is timed by last send byte)
  if rising_edge (i_clk) then
    offset := ("0" & clk_div) when parity_en = '1' else (clk_div & "0");
    if to_integer(unsigned(timeout_val)) = timeout_reg + 1 then
      timeout_s <= timeout_en or allow_unexp_msg;
    else
      timeout_s <= '0';
    end if;
    if (timeout_rst = '1') then
      timeout_reg <= (others => '0');
      step := 0;
    elsif timeout_s = '0' then
      step := step + 1;
    end if;
    if step = (clk_div & "000" + offset) then
      timeout_reg <= timeout_reg + not sync_up; -- this way it will wait till all data is send before starting timeout on recieved data
      step := 0;
    end if;
  end if;
end process;

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

----------------------------------------------------------------------------------------
--#SECTION - Data input logic
----------------------------------------------------------------------------------------
p_reciever : process (i_clk)
  variable st_reciever : fsm_reciever := st_reciever_idle;
begin
  if i_rst_n = '0' then
    st_reciever <= idle;
    o_o_info_fifo_data <= (others => '0');
    o_o_data_fifo_data <= (others => '0');
  else
    o_o_data_fifo_next <= '0';
    o_o_info_fifo_next <= '0';
    case( st_reciever ) is
      when st_reciver_idle =>
        if o_busy_rx = '1' then
          st_reciever <= st_reciever_h_info;
        end if;
      when st_reciever_h_info =>
        if o_msg_vld_strb = '1' then

        end if;
      when st_reciever_h_data =>
      when st_reciever_h_back =>
      when st_reciever_data =>
    
      when others =>
    
    end case ;
  end if;
end process; --#!SECTION

  uart_tx_inst : entity work.uart_tx
  generic map (
    MSG_W => MSG_W,
    SMPL_W => SMPL_W
  )
  port map (
    i_clk => i_clk,
    i_rst_n => i_rst_n,
    i_msg => i_msg,
    i_msg_vld => i_msg_vld,
    i_start_pol => start_pol,
    i_par_en => par_en,
    i_par_type => par_type,
    i_clk_div => clk_div,
    o_tx => comm_wire_0,
    o_busy => o_busy_tx
  );

uart_rx_inst : entity work.uart_rx
generic map (
  MSG_W => MSG_W,
  SMPL_W => SMPL_W,
  START_OFFSET => START_OFFSET
)
port map (
  i_clk => i_clk,
  i_rst_n => i_rst_n,
  i_rx => comm_wire_1,
  i_start_pol => start_pol,
  i_par_en => par_en,
  i_par_type => par_type,
  i_clk_div => clk_div,
  o_msg => o_msg,
  o_msg_vld_strb => o_msg_vld_strb,
  o_busy => o_busy_rx,
  o_err_noise_strb => o_err_noise_strb,
  o_err_frame_strb => o_err_frame_strb,
  o_err_par_strb => o_err_par_strb
);


end architecture;







