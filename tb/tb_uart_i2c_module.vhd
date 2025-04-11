
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.my_common.all;
use work.tb_common.all;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity uart_i2c_module_tb is
  generic (
    runner_cfg : string
  );
end;

architecture bench of uart_i2c_module_tb is
  -- Clock period
  constant clk_period : time := 5 ns;
  -- Generics
  constant ID : std_logic_vector(2 downto 0) := (others => '0');
  constant GEN_TYPE : string := "DEFAULT";
  -- Ports
  signal i_clk : std_logic;
  signal i_rst_n : std_logic;
  signal i_en : std_logic_vector (1 downto 0);
  signal i_i_info_write : std_logic;
  signal i_i_info_data : info_bus;
  signal i_o_info_full : std_logic;
  signal i_i_data_write : std_logic;
  signal i_i_data_data : data_bus;
  signal i_o_data_full : std_logic;
  signal o_i_info_next : std_logic;
  signal o_o_info_data : info_bus;
  signal o_o_info_empty : std_logic;
  signal o_i_data_next : std_logic;
  signal o_o_data_data : data_bus;
  signal o_o_data_empty : std_logic;
  signal tx_scl : std_logic;
  signal rx_sda : std_logic;
  signal i_interrupt_tx_rdy : std_logic;
  signal o_interrupt_rx_rdy : std_logic;
begin

  uart_i2c_module_inst : entity work.uart_i2c_module
  generic map (
    ID => ID,
    GEN_TYPE => GEN_TYPE
  )
  port map (
    i_clk => i_clk,
    i_rst_n => i_rst_n,
    i_en => i_en,
    i_i_info_write => i_i_info_write,
    i_i_info_data => i_i_info_data,
    i_o_info_full => i_o_info_full,
    i_i_data_write => i_i_data_write,
    i_i_data_data => i_i_data_data,
    i_o_data_full => i_o_data_full,
    o_i_info_next => o_i_info_next,
    o_o_info_data => o_o_info_data,
    o_o_info_empty => o_o_info_empty,
    o_i_data_next => o_i_data_next,
    o_o_data_data => o_o_data_data,
    o_o_data_empty => o_o_data_empty,
    tx_scl => tx_scl,
    rx_sda => rx_sda,
    i_interrupt_tx_rdy => i_interrupt_tx_rdy,
    o_interrupt_rx_rdy => o_interrupt_rx_rdy
  );
  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then
        info("Hello world test_alive");
        wait for 100 * clk_period;
        test_runner_cleanup(runner);
        
      elsif run("test_0") then
        info("Hello world test_0");
        wait for 100 * clk_period;
        test_runner_cleanup(runner);
      end if;
    end loop;
  end process main;

-- clk <= not clk after clk_period/2;

end;