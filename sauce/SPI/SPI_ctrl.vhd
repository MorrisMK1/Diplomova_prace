
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.numeric_std_unsigned.all;


library work;
  use work.my_common.all;


entity SPI_ctrl is
  generic (
    constant  SMPL_W        : natural := 8;             -- rx line sample width
    constant  START_OFFSET  : natural := 10;            -- offset in clks between start and first bit
    constant  MY_ID         : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0) := "000"
  );
  port (
    clk_100MHz              : in  std_logic;
    i_rst_n                 : in  std_logic;
    i_en                    : in  std_logic := '1';

    i_i_data_fifo_data      : in  data_bus;
    i_i_data_fifo_empty     : in  out_ready;
    o_i_data_fifo_next      : out in_pulse;

    o_o_data_fifo_data      : out data_bus;
    i_o_data_fifo_full      : in  out_ready;
    o_o_data_fifo_next      : out in_pulse;
  
    i_i_info_fifo_data      : in  info_bus;
    i_i_info_fifo_empty     : in  out_ready;
    o_i_info_fifo_next      : out in_pulse;

    o_o_info_fifo_data      : out info_bus;
    i_o_info_fifo_full      : in  out_ready;
    o_o_info_fifo_next      : out in_pulse;

    MISO                    : in  std_logic;
    MOSI                    : out std_logic;
    SCLK                    : out std_logic;
    o_interrupt             : out std_logic
  );
end entity SPI_ctrl;

architecture rtl of SPI_ctrl is

  constant MISO_DEB_BUFF_SIZE : natural := 8;
  signal i_clk_div : std_logic_vector((MSG_W * 2) - 1 downto 0);
  signal i_hold_active : std_logic;
  signal i_data_dir : std_logic;
  signal i_data : std_logic_vector(MSG_W - 1 downto 0);
  signal i_data_vld : std_logic;
  signal o_data_read : std_logic;
  signal i_data_recieve : std_logic;
  signal o_data : std_logic_vector(MSG_W - 1 downto 0);
  signal o_data_vld : std_logic;
  signal o_busy : std_logic;


begin

  SPI_driver_inst : entity work.SPI_driver
  generic map (
    MISO_DEB_BUFF_SIZE => MISO_DEB_BUFF_SIZE
  )
  port map (
    clk_100MHz => clk_100MHz,
    rst_n => i_rst_n,
    i_clk_div => i_clk_div,
    i_hold_active => i_hold_active,
    i_data_dir => i_data_dir,
    i_data => i_data,
    i_data_vld => i_data_vld,
    o_data_read => o_data_read,
    i_data_recieve => i_data_recieve,
    o_data => o_data,
    o_data_vld => o_data_vld,
    o_busy => o_busy,
    MISO => MISO,
    MOSI => MOSI,
    SCLK => SCLK
  );


end architecture;