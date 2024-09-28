
library ieee;
use ieee.std_logic_1164.ALL;


package body my_common_types is
  constant  MSG_W         : natural := 8;           -- message width
  constant  SMPL_W        : natural := 8;           -- rx line sample width
  constant  START_OFFSET  : natural := 10;           -- offset in clks between start and first bit
  
  type cfg_bus is record
    data_master       :  std_logic_vector(MSG_W-1 downto 0);
    data_slave        :  std_logic_vector(MSG_W-1 downto 0);
    register_select   :  std_logic_vector(1 downto 0);
    slave_write_en    :  std_logic;
  end record;

  type fifo_bus is record
    data      : std_logic_vector(MSG_W-1 downto 0);
    ready     : std_logic;
    step      : std_logic;
  end record;
    
end package body;
