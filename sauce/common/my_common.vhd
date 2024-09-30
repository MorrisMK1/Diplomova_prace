library ieee;
use ieee.std_logic_1164.ALL;

package my_common is
  constant  MSG_W         : natural := 8;           -- message width
  constant  SMPL_W        : natural := 8;           -- rx line sample width
  constant  START_OFFSET  : natural := 10;          -- offset in clks between start and first bit
  constant  USER_ID_W     : natural := 2;
  constant  BUS_ID_W      : natural := 3;

  type std_logic_array is array (natural range <>) of std_logic_vector;

  type fifo_bus is record
    data      : std_logic_vector(MSG_W-1 downto 0);
    ready     : std_logic;
    step      : std_logic;
  end record;

  type info_bus is record
    data      : std_logic_vector(MSG_W+MSG_W-1 downto 0);
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
