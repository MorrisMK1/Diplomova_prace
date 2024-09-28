
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

use work.my_common_types.all;

----------------------------------------------------------------------------------------
--#ANCHOR - ENTITY
----------------------------------------------------------------------------------------
entity uart_ctrl is
  generic (
    constant  MSG_W         : natural := 8;           -- message width
    constant  SMPL_W        : natural := 8;           -- rx line sample width
    constant  START_OFFSET  : natural := 10           -- offset in clks between start and first bit
  );
  port (
    i_clk                   : in  std_logic;
    i_rst_n                 : in  std_logic;
    
    i_data                  : inout fifo_bus;         -- input bus from fifo

    o_data                  : inout fifo_bus;         -- output bus to fifo

    cfg                     : inout cfg_bus;          -- configuration bus

    i_rx                    : in  std_logic;
    o_tx                    : in  std_logic

  );
end uart_ctrl;

----------------------------------------------------------------------------------------
--#SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture behavioral of uart_ctrl is

begin

  uart_rx_inst : entity work.uart_rx
  generic map (
    MSG_W => MSG_W,
    SMPL_W => SMPL_W,
    START_OFFSET => START_OFFSET
  )
  port map (
    i_clk => i_clk,
    i_rst_n => i_rst_n,
    i_rx => i_rx,
    i_start_pol => i_start_pol,
    i_par_en => i_par_en,
    i_par_type => i_par_type,
    i_clk_div => i_clk_div,
    o_msg => o_msg,
    o_msg_vld_strb => o_msg_vld_strb,
    o_err_noise_strb => o_err_noise_strb,
    o_err_frame_strb => o_err_frame_strb,
    o_err_par_strb => o_err_par_strb
  );

  uart_tx_inst : entity work.uart_tx
  generic map (
    MSG_W => MSG_W,
    SMPL_W => SMPL_W
  )
  port map (
    i_clk => i_clk,
    i_rst_n => i_rst_n,
    i_msg => i_msg,
    i_msg_vld_strb => i_msg_vld_strb,
    i_start_pol => i_start_pol,
    i_par_en => i_par_en,
    i_par_type => i_par_type,
    i_clk_div => i_clk_div,
    o_tx => o_tx,
    o_busy => o_busy
  );


end architecture; --#!SECTION