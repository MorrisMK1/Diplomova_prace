library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library work;
use work.my_common.all;
use work.tb_common.all;

LIBRARY VUNIT_LIB;
CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

entity tb_base_design is
  generic (runner_cfg : string);
end entity tb_base_design;

----------------------------------------------------------------------------------------
--SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture sim of tb_base_design is 

constant CLK_PERIOD : TIME := 10 ns;

signal i_clk          : std_logic;
signal i_rst_n        : std_logic;

signal tx_sl1, tx_sl2 : std_logic;
signal rx_sl1, rx_sl2 : std_logic;
signal tx_ms          : std_logic;
signal rx_ms          : std_logic;

signal MISO_4, MOSI_4, SCLK_4 :std_logic;
signal o_CS_4         : std_logic_vector(7 downto 0);

signal i_settings     : std_logic_array (1 to 2) (MSG_W -1 downto 0);

signal gen_header     : info_bus;
signal msg_to_ms      : data_bus;



begin
----------------------------------------------------------------------------------------
--ANCHOR - CLK
----------------------------------------------------------------------------------------
p_clk :process
begin
  generate_clk(i_clk,CLK_PERIOD);
end process;
----------------------------------------------------------------------------------------
--ANCHOR - uart monitor
----------------------------------------------------------------------------------------
p_uart_print :process
  variable ret_msg        : data_bus;
begin
  uart_rx(tx_ms,ret_msg, 1.085 us);
end process;
----------------------------------------------------------------------------------------
--SECTION - TESTCASE
----------------------------------------------------------------------------------------
rx_sl1 <= tx_sl1;
rx_sl2 <= tx_sl2;
p_test  : process
  variable loop_cnt   : unsigned(MSG_W - 1 downto 0);
begin
  --ANCHOR - init
  test_runner_setup(runner, runner_cfg);
  wait for 1 ns;
  i_rst_n <= '0';
  i_settings(1) <= "00000111";
  i_settings(2) <= "00000000";
  rx_ms <= '1';
  wait for CLK_PERIOD*2;
  i_rst_n <= '1';
  for i in 1 to 2 loop
    gen_header <= "000010110000001000000000";
    wait for CLK_PERIOD*10;
    msg_to_ms <= gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= gen_header(MSG_W * 1 - 1 downto MSG_W * 0);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    --ANCHOR - first message
    gen_header <= create_reg0_w("00",std_logic_vector(to_unsigned(i,3)),"00000010","00000010");
    wait for CLK_PERIOD*10;
    msg_to_ms <= gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= gen_header(MSG_W * 1 - 1 downto MSG_W * 0);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= "01011010";
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= "11001001";
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    --ANCHOR - second message
    gen_header <= create_reg0_w("01",std_logic_vector(to_unsigned(i,3)),"00000001","00000001");
    wait for CLK_PERIOD*10;
    msg_to_ms <= gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= gen_header(MSG_W * 1 - 1 downto MSG_W * 0);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= "01100110";
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));

    --ANCHOR - third message - set new parameters
    gen_header <= create_reg1_w("10",std_logic_vector(to_unsigned(i,3)),'0','0','1','0',"001");
    wait for CLK_PERIOD*10;
    msg_to_ms <= gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    
    --ANCHOR - fourth message - repeat of second
    gen_header <= create_reg0_w("01",std_logic_vector(to_unsigned(i,3)),"00000001","00000001");
    wait for CLK_PERIOD*10;
    msg_to_ms <= gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= gen_header(MSG_W * 1 - 1 downto MSG_W * 0);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= "01100110";
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    
    --ANCHOR - 5 message - set new parameters
    gen_header <= create_reg1_w("10",std_logic_vector(to_unsigned(i,3)),'0','1','1','0',"111");
    wait for CLK_PERIOD*10;
    msg_to_ms <= gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    
    --ANCHOR - 6 message - repeat of second
    gen_header <= create_reg0_w("01",std_logic_vector(to_unsigned(i,3)),"00010100","00010100");
    wait for CLK_PERIOD*10;
    msg_to_ms <= gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= gen_header(MSG_W * 1 - 1 downto MSG_W * 0);
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    wait for 0 ns;
    msg_to_ms <= "01100110";
    wait for 0 ns;
    uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    for loop_cnt in 1 to 20 loop
      wait for 0 ns;
      msg_to_ms <= std_logic_vector(to_unsigned(loop_cnt,MSG_W));
      wait for 0 ns;
      uart_tx(rx_ms,i_clk,msg_to_ms,(CLK_PERIOD*110));
    end loop;
  end loop;

  wait for  60 ms; --CLK_PERIOD * 100_000_000;
  test_runner_cleanup(runner);

end process;--!SECTION
----------------------------------------------------------------------------------------
--ANCHOR - DUT
----------------------------------------------------------------------------------------

main_inst : entity work.main
  port map (
    i_clk => i_clk,
    i_rst_n => i_rst_n,
    i_settings => i_settings,
    main_tx => tx_ms,
    main_rx => rx_ms,
    slv1_tx => tx_sl1,
    slv1_rx => rx_sl1,
    slv2_tx => tx_sl2,
    slv2_rx => rx_sl2,
    MISO_4  => MISO_4,
    MOSI_4  => MOSI_4,
    SCLK_4  => SCLK_4,
    o_CS_4  => o_CS_4
  );


end architecture;--!SECTION