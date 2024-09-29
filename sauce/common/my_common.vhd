library ieee;
use ieee.std_logic_1164.ALL;

package my_common is
  constant  MSG_W         : natural := 8;           -- message width
  constant  SMPL_W        : natural := 8;           -- rx line sample width
  constant  START_OFFSET  : natural := 10;          -- offset in clks between start and first bit
  constant  ID_W          : natural := 2;

  type std_logic_array is array (natural range <>) of std_logic_vector;

  type cfg_bus is record
    data_master       : std_logic_vector(MSG_W-1 downto 0);
    data_slave        : std_logic_vector(MSG_W-1 downto 0);
    register_select   : std_logic_vector(1 downto 0);
    slave_write_en    : std_logic;
  end record;

  type fifo_bus is record
    data      : std_logic_vector(MSG_W-1 downto 0);
    ready     : std_logic;
    step      : std_logic;
  end record;

  type info_bus is record
    data      : std_logic_vector(MSG_W+ID_W-1 downto 0);
    ready     : std_logic;
    step      : std_logic;
  end record;

  type t_bus_type is (
    t_bus_UART,
    t_bus_I2C,
    t_bus_SPI,
    t_bus_1WIRE
  );

end package my_common;
