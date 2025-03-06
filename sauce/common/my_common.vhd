library ieee;
use ieee.std_logic_1164.ALL;

package my_common is
  constant  MSG_W         : natural := 8;           -- message width
  constant  SMPL_W        : natural := 8;           -- rx line sample width
  constant  START_OFFSET  : natural := 10;          -- offset in clks between start and first bit
  constant  USER_ID_W     : natural := 2;
  constant  BUS_ID_W      : natural := 3;
  constant  ZERO_BIT      : std_logic := '0';
  constant  HIGH_BIT      : std_logic := '1';

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

  function inf_id(info:info_bus)return std_logic_vector;
  function inf_tg(info:info_bus)return std_logic_vector;
  function inf_reg(info:info_bus)return std_logic_vector;
  function inf_ret(info:info_bus)return std_logic;
  function inf_size(info:info_bus)return std_logic_vector;

end package my_common;

package body my_common is

  function inf_id(info:info_bus)return std_logic_vector is
    variable ret_val : std_logic_vector (1 downto 0);
  begin
    ret_val := info(MSG_W * 2 + 7 downto MSG_W * 2 + 6);
    return ret_val;
  end function;

  function inf_tg(info:info_bus)return std_logic_vector is
    variable ret_val : std_logic_vector (2 downto 0);
  begin
    ret_val := info(MSG_W * 2 + 2 downto MSG_W * 2);
    return ret_val;
  end function;

  function inf_reg(info:info_bus)return std_logic_vector is
    variable ret_val : std_logic_vector (1 downto 0);
  begin
    ret_val := info(MSG_W * 2 + 4 downto MSG_W * 2 + 3);
    return ret_val;
  end function;

  function inf_ret(info:info_bus)return std_logic is
  begin
    return info(MSG_W * 2 + 5);
  end function;

  function inf_size(info:info_bus)return std_logic_vector is
    variable ret_val : std_logic_vector (MSG_W - 1 downto 0);
  begin
    ret_val := info(MSG_W * 2 - 1 downto MSG_W * 1);
    return ret_val;
  end function;


end package body;