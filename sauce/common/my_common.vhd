library ieee;
use ieee.std_logic_1164.ALL;

package my_common is
  constant  MSG_W         : natural := 8;           -- message width
  constant  SMPL_W        : natural := 8;           -- rx line sample width
  constant  START_OFFSET  : natural := 10;          -- offset in clks between start and first bit
  constant  USER_ID_W     : natural := 2;
  constant  BUS_ID_W      : natural := 3;

  type std_logic_array is array (natural range <>) of std_logic_vector;

--#NOTE - FIFO interface signal definitions
  subtype data_bus  is std_logic_vector(MSG_W-1 downto 0);
  subtype info_bus   is std_logic_vector(3*MSG_W-1 downto 0);
  subtype out_ready is std_logic;
  subtype in_pulse  is std_logic;

  type fifo_data_interface is record
  data      : data_bus;
  ready     : out_ready;
  step      : in_pulse;
  end record;

  type fifo_info_interface is record
  data      : info_bus;
  ready     : out_ready;
  step      : in_pulse;
  end record;

  type t_bus_type is (
    t_bus_UART,
    t_bus_I2C,
    t_bus_SPI,
    t_bus_1WIRE
  );

end package my_common;
