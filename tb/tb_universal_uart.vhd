library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
library work;
use work.tb_common.all;
use work.my_common.all;

entity tb_universal_uart is
end entity;


architecture sim of tb_universal_uart is

  constant CLK_PERIOD : TIME := 10 ns;

  constant MSG_W : natural := 8;
  constant SMPL_W : natural := 8;
  constant START_OFFSET : natural := 10;
  constant BUS_MODE : t_bus_type := t_bus_UART;
  constant MY_ID : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0) := "000";
  signal clk : std_logic;
  signal i_rst_n : std_logic := '0';
  signal i_data : fifo_bus;
  signal o_data : fifo_bus;
  signal i_info_bus : info_bus;
  signal o_info_bus : info_bus;
  signal comm_wire : std_logic;
  signal SPI_device_sel : STD_LOGIC_VECTOR(MSG_W-1 downto 0);

begin

  p_clk :process
  begin
    generate_clk(clk,CLK_PERIOD);
  end process;

  p_test  : process
  begin
    wait for 1 fs;
    i_data.data <= (others => '0');
    i_data.ready <= '0';
    o_data.step <= '0';
    i_info_bus.data <= (others => '0');
    i_info_bus.ready <= '0';
    o_info_bus.step <= '0';
    wait for CLK_PERIOD*2;
    i_rst_n <= '1';
    wait for CLK_PERIOD*10;
    std.env.stop(0);
  end process p_test;


  universal_ctrl_DUT : entity work.universal_ctrl
  generic map (
    MSG_W => MSG_W,
    SMPL_W => SMPL_W,
    START_OFFSET => START_OFFSET,
    BUS_MODE => BUS_MODE,
    MY_ID => "000"
  )
  port map (
    i_clk => clk,
    i_rst_n => i_rst_n,
    i_data => i_data,
    o_data => o_data,
    i_info_bus => i_info_bus,
    o_info_bus => o_info_bus,
    comm_wire_0 => comm_wire,
    comm_wire_1 => comm_wire,
    SPI_device_sel => SPI_device_sel
  );

end architecture;