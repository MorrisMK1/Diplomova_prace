library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
library work;
  use work.my_common.all;


entity SPI_module is
  generic (
    ID : std_logic_vector(2 downto 0);
    GEN_TYPE: string  := "DEFAULT" --NOTE - types: "DEFAULT", "XILINX"
  );
  port(
    i_clk           : in std_logic;
    i_rst_n         : in std_logic;
    i_en            : in std_logic;

    i_i_info_write  : in std_logic;
    i_i_info_data   : in info_bus;
    i_o_info_full   : out std_logic;

    i_i_data_write  : in std_logic;
    i_i_data_data   : in data_bus;
    i_o_data_full   : out std_logic;

    o_i_info_next   : in std_logic;
    o_o_info_data   : out info_bus;
    o_o_info_empty  : out std_logic;

    o_i_data_next   : in std_logic;
    o_o_data_data   : out data_bus;
    o_o_data_empty  : out std_logic;

    MISO            : in std_logic;
    MOSI            : out std_logic;
    SCLK            : out std_logic;
    o_CS            : out std_logic_vector(MSG_W - 1 downto 0);

    o_busy          : out std_logic

  );
end entity SPI_module;

----------------------------------------------------------------------------------------
--SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture behavioral of SPI_module is 

signal sl_next_info, sl_emty_info, sl_next_data, sl_push_info, sl_full_info, sl_push_data, sl_full_data, sl_empty_data : std_logic;

signal sl_info_in, sl_info_out : info_bus;
signal sl_data_in, sl_data_out : data_bus;

signal rst, last_en : std_logic;

begin
rst <= (not i_rst_n) when last_en = i_en else '1';
last_en <= i_en;

----------------------------------------------------------------------------------------
--ANCHOR - FIFO from router to slave
----------------------------------------------------------------------------------------
module_fifo_INFO_SLV1_i : entity work.FIFO_wrapper
  generic map (
    g_WIDTH => MSG_W * 3,
    g_DEPTH => 32,
    GEN_TYPE => GEN_TYPE
  )
  port map (
    i_rst_sync => rst,
    i_clk => i_clk,
    i_wr_en =>  i_i_info_write,
    i_wr_data =>i_i_info_data,
    o_full =>   i_o_info_full,
    i_rd_en =>  sl_next_info,
    o_rd_data =>sl_info_in,
    o_empty =>  sl_emty_info
  );

module_fifo_DATA_SLV1_i : entity work.FIFO_wrapper
  generic map (
    g_WIDTH => MSG_W,
    g_DEPTH => 512,
    GEN_TYPE => GEN_TYPE
  )
  port map (
    i_rst_sync => rst,
    i_clk => i_clk,
    i_wr_en =>  i_i_data_write,
    i_wr_data =>i_i_data_data,
    o_full =>   i_o_data_full,
    i_rd_en =>  sl_next_data,
    o_rd_data =>sl_data_in,
    o_empty =>  sl_empty_data
  );

----------------------------------------------------------------------------------------
--ANCHOR - FIFO from slave to collector
----------------------------------------------------------------------------------------
module_fifo_INFO_SLV1_o : entity work.FIFO_wrapper
  generic map (
    g_WIDTH => MSG_W * 3,
    g_DEPTH => 32,
    GEN_TYPE => GEN_TYPE
  )
  port map (
    i_rst_sync => rst,
    i_clk =>      i_clk,
    i_wr_en =>    sl_push_info,
    i_wr_data =>  sl_info_out,
    o_full =>     sl_full_info,
    i_rd_en =>    o_i_info_next,
    o_rd_data =>  o_o_info_data,
    o_empty =>    o_o_info_empty
  );

module_fifo_DATA_SLV1_o : entity work.FIFO_wrapper
  generic map (
    g_WIDTH => MSG_W,
    g_DEPTH => 512,
    GEN_TYPE => GEN_TYPE
  )
  port map (
    i_rst_sync => rst,
    i_clk => i_clk,
    i_wr_en =>   sl_push_data,
    i_wr_data => sl_data_out,
    o_full =>    sl_full_data,
    i_rd_en =>   o_i_data_next,
    o_rd_data => o_o_data_data,
    o_empty =>   o_o_data_empty
  );

  ----------------------------------------------------------------------------------------
  --ANCHOR - SLAVE INTERFACE
  ----------------------------------------------------------------------------------------
  SPI_ctrl_inst : entity work.SPI_ctrl
  generic map (
    SMPL_W => SMPL_W,
    START_OFFSET => START_OFFSET,
    MY_ID => ID
  )
  port map (
    clk_100MHz => i_clk,
    i_rst_n => i_rst_n,
    i_en => i_en,
    i_i_data_fifo_data => sl_data_in,
    i_i_data_fifo_empty =>sl_empty_data,
    o_i_data_fifo_next => sl_next_data,
    o_o_data_fifo_data => sl_data_out,
    i_o_data_fifo_full => sl_full_data,
    o_o_data_fifo_next => sl_push_data,
    i_i_info_fifo_data => sl_info_in,
    i_i_info_fifo_empty =>sl_emty_info,
    o_i_info_fifo_next => sl_next_info,
    o_o_info_fifo_data => sl_info_out,
    i_o_info_fifo_full => sl_full_info,
    o_o_info_fifo_next => sl_push_info,
    MISO => MISO,
    MOSI => MOSI,
    SCLK => SCLK,
    o_CS => o_CS,
    o_busy => o_busy
  );



end architecture; --!SECTION