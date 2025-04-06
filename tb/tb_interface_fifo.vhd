library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
library work;
use work.tb_common.all;
use work.my_common.all;


entity tb_interface_fifo is

end entity tb_interface_fifo;

----------------------------------------------------------------------------------------
--SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture sim of tb_interface_fifo is 

constant CLK_PERIOD : TIME := 10 ns;

signal i_clk          : std_logic;
signal i_rst_n        : std_logic;

signal i_sl_data_data : data_bus;
signal i_sl_info_data : info_bus;
signal o_sl_data_data : data_bus;
signal o_sl_info_data : info_bus;

signal i_ms_data_data : data_bus;
signal i_ms_info_data : info_bus;
signal o_ms_data_data : data_bus;
signal o_ms_info_data : info_bus;

signal sl_push_info   : std_logic;
signal sl_push_data   : std_logic;
signal sl_next_info   : std_logic;
signal sl_next_data   : std_logic;
signal sl_emty_info   : std_logic;
signal sl_emty_data   : std_logic;
signal sl_full_info   : std_logic;
signal sl_full_data   : std_logic;

signal ms_push_info   : std_logic;
signal ms_push_data   : std_logic;
signal ms_next_info   : std_logic;
signal ms_next_data   : std_logic;
signal ms_emty_info   : std_logic;
signal ms_emty_data   : std_logic;
signal ms_full_info   : std_logic;
signal ms_full_data   : std_logic;

signal tx_sl          : std_logic;
signal rx_sl          : std_logic;
signal tx_ms          : std_logic;
signal rx_ms          : std_logic;

signal i_settings     : std_logic_array (1 to 2) (MSG_W -1 downto 0);
signal o_ready        : std_logic;

signal gen_header     : info_bus;

begin
----------------------------------------------------------------------------------------
--ANCHOR - CLK
----------------------------------------------------------------------------------------
p_clk :process
begin
  generate_clk(i_clk,CLK_PERIOD);
end process;
----------------------------------------------------------------------------------------
--SECTION - TESTCASE
----------------------------------------------------------------------------------------
p_test  : process
 variable msg_to_ms      : data_bus;
begin
  --ANCHOR - init
  wait for 1 ns;
  i_rst_n <= '0';
  i_settings(1) <= "00000101";
  i_settings(2) <= "00000000";
  rx_sl <= '1';
  rx_ms <= '1';
  wait for CLK_PERIOD*2;
  i_rst_n <= '1';
  --ANCHOR - first message
  gen_header <= create_reg0_w("00","000","00000010","00000010");
  wait for CLK_PERIOD*10;
  msg_to_ms := gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := gen_header(MSG_W * 1 - 1 downto MSG_W * 0);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := "01011010";
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := "11001001";
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  --ANCHOR - second message
  gen_header <= create_reg0_w("01","000","00000001","00000001");
  wait for CLK_PERIOD*10;
  msg_to_ms := gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := gen_header(MSG_W * 1 - 1 downto MSG_W * 0);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := "01100110";
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));

  --ANCHOR - third message - set new parameters
  gen_header <= create_reg1_w("10","000",'0','0','1','0',"001");
  wait for CLK_PERIOD*10;
  msg_to_ms := gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  
  --ANCHOR - fourth message - repeat of second
  gen_header <= create_reg0_w("01","000","00000001","00000001");
  wait for CLK_PERIOD*10;
  msg_to_ms := gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := gen_header(MSG_W * 1 - 1 downto MSG_W * 0);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := "01100110";
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  
  --ANCHOR - 5 message - set new parameters
  gen_header <= create_reg1_w("10","000",'0','1','1','0',"001");
  wait for CLK_PERIOD*10;
  msg_to_ms := gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  
  --ANCHOR - 6 message - repeat of second
  gen_header <= create_reg0_w("01","000","00000001","00000001");
  wait for CLK_PERIOD*10;
  msg_to_ms := gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := gen_header(MSG_W * 1 - 1 downto MSG_W * 0);
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));
  wait for 0 ns;
  msg_to_ms := "01100110";
  wait for 0 ns;
  uart_tx(rx_ms,msg_to_ms,(CLK_PERIOD*260));

  wait for CLK_PERIOD * 100_000_000;

end process;--!SECTION
----------------------------------------------------------------------------------------
--SECTION - INSTANCES
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--ANCHOR - FIFO INFOs
----------------------------------------------------------------------------------------
module_fifo_INFO_0 : entity work.module_fifo_regs_no_flags
  generic map (
    g_WIDTH => 24,
    g_DEPTH => 32
  )
  port map (
    i_rst_sync => (not i_rst_n),
    i_clk =>      i_clk,
    i_wr_en =>    ms_push_info,
    i_wr_data =>  o_ms_info_data,
    o_full =>     ms_full_info,
    i_rd_en =>    sl_next_info,
    o_rd_data =>  i_sl_info_data,
    o_empty =>    sl_emty_info
  );
  module_fifo_INFO_1 : entity work.module_fifo_regs_no_flags
  generic map (
    g_WIDTH => 24,
    g_DEPTH => 32
  )
  port map (
    i_rst_sync => (not i_rst_n),
    i_clk => i_clk,
    i_wr_en => sl_push_info,
    i_wr_data => o_sl_info_data,
    o_full => sl_full_info,
    i_rd_en => ms_next_info,
    o_rd_data => i_ms_info_data,
    o_empty => ms_emty_info
  );
  ----------------------------------------------------------------------------------------
  --ANCHOR - FIFO DATAs
  ----------------------------------------------------------------------------------------
  module_fifo_DATA_0 : entity work.module_fifo_regs_no_flags
  generic map (
    g_WIDTH => 8,
    g_DEPTH => 512
  )
  port map (
    i_rst_sync => (not i_rst_n),
    i_clk => i_clk,
    i_wr_en => ms_push_data,
    i_wr_data => o_ms_data_data,
    o_full => ms_full_data,
    i_rd_en => sl_next_data,
    o_rd_data => i_sl_data_data,
    o_empty => sl_emty_data
  );
  module_fifo_DATA_1 : entity work.module_fifo_regs_no_flags
  generic map (
    g_WIDTH => 8,
    g_DEPTH => 512
  )
  port map (
    i_rst_sync => (not i_rst_n),
    i_clk => i_clk,
    i_wr_en => sl_push_data,
    i_wr_data => o_sl_data_data,
    o_full => sl_full_data,
    i_rd_en => ms_next_data,
    o_rd_data => i_ms_data_data,
    o_empty => ms_emty_data
  );
  ----------------------------------------------------------------------------------------
  --ANCHOR - MAIN INTERFACE
  ----------------------------------------------------------------------------------------
  main_ctrl_inst : entity work.main_ctrl
  port map (
    i_clk => i_clk,
    i_rst_n => i_rst_n,
    i_i_data_fifo_data => i_ms_data_data,
    i_i_data_fifo_ready => (not ms_emty_data),
    o_i_data_fifo_next => ms_next_data,
    o_o_data_fifo_data => o_ms_data_data,
    i_o_data_fifo_ready => (not ms_full_data),
    o_o_data_fifo_next => ms_push_data,
    i_i_info_fifo_data => i_ms_info_data,
    i_i_info_fifo_ready => (not ms_emty_info),
    o_i_info_fifo_next => ms_next_info,
    o_o_info_fifo_data => o_ms_info_data,
    i_o_info_fifo_ready => (not ms_full_info),
    o_o_info_fifo_next => ms_push_info,
    i_settings => i_settings,
    o_ready => o_ready,
    comm_wire_0 => tx_ms,
    comm_wire_1 => rx_ms
  );
  ----------------------------------------------------------------------------------------
  --ANCHOR - SLAVE INTERFACE
  ----------------------------------------------------------------------------------------
  uart_ctrl_inst : entity work.uart_ctrl
  generic map (
    MSG_W => MSG_W,
    SMPL_W => SMPL_W,
    START_OFFSET => START_OFFSET,
    MY_ID => "000"
  )
  port map (
    i_clk => i_clk,
    i_rst_n => i_rst_n,
    i_en => '1',
    i_i_data_fifo_data => i_sl_data_data,
    i_i_data_fifo_ready => (not sl_emty_data),
    o_i_data_fifo_next => sl_next_data,
    o_o_data_fifo_data => o_sl_data_data,
    i_o_data_fifo_ready => (not sl_full_data),
    o_o_data_fifo_next => sl_push_data,
    i_i_info_fifo_data => i_sl_info_data,
    i_i_info_fifo_ready => (not sl_emty_info),
    o_i_info_fifo_next => sl_next_info,
    o_o_info_fifo_data => o_sl_info_data,
    i_o_info_fifo_ready => (not sl_full_info),
    o_o_info_fifo_next => sl_push_info,
    comm_wire_0 => tx_sl,
    comm_wire_1 => tx_sl
  );

--!SECTION
end architecture;--!SECTION