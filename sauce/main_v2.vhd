library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
library work;
use work.my_common.all;


entity main_v2 is
  port(
    i_clk_100MHz  : in std_logic  ;
    i_rst_n       : in std_logic;

    main_tx       : out std_logic;
    main_rx       : in std_logic;

    slv1_tx       : out std_logic;
    slv1_rx       : in std_logic;
    
    slv2_tx       : inout std_logic;
    slv2_rx       : inout std_logic;
    
    scl_3         : inout std_logic;
    sda_3         : inout std_logic;
    i2c_3_inter   : inout std_logic := '0';
  
    MISO_4        : in std_logic;
    MOSI_4        : out std_logic;
    SCLK_4        : out std_logic;
    o_CS_4        : out std_logic_vector(7 downto 0)

  );
end entity main_v2;

----------------------------------------------------------------------------------------
--SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture behavioral of main_v2 is 

constant FIFO_MODE : STRING := "DEFAULT"; -- "XILINX" "DEFAULT"

signal o_m_i_f_inf, i_r_o_f_inf, i_m_o_f_inf: info_bus;
signal o_m_i_f_dat, i_r_o_f_dat, i_m_o_f_dat: data_bus;


signal ms_push_info, ms_push_data, ms_next_info, ms_next_data, ms_emty_info, ms_emty_data, ms_full_info, ms_full_data   : std_logic;

signal rt_next_info, rt_next_data, rt_emty_info, rt_emty_data   : std_logic;

signal o_ready        : std_logic;

signal settings_main : std_logic_array (1 to 2) (MSG_W-1 downto 0);
signal enable_interfaces  : data_bus;

signal r_i_bypass : std_logic;
signal r_o_err_rep : std_logic;

signal r_o_o_data_fifo_data : data_bus;
signal r_i_o_data_fifo_full_0 : out_ready;
signal r_o_o_data_fifo_next_0 : in_pulse;
signal r_i_o_data_fifo_full_1 : out_ready;
signal r_o_o_data_fifo_next_1 : in_pulse;
signal r_i_o_data_fifo_full_2 : out_ready;
signal r_o_o_data_fifo_next_2 : in_pulse;
signal r_i_o_data_fifo_full_3 : out_ready;
signal r_o_o_data_fifo_next_3 : in_pulse;
signal r_i_o_data_fifo_full_4 : out_ready;
signal r_o_o_data_fifo_next_4 : in_pulse;
signal r_i_o_data_fifo_full_5 : out_ready;
signal r_o_o_data_fifo_next_5 : in_pulse;
signal r_i_o_data_fifo_full_6 : out_ready;
signal r_o_o_data_fifo_next_6 : in_pulse;
signal r_i_o_data_fifo_full_7 : out_ready;
signal r_o_o_data_fifo_next_7 : in_pulse;
signal r_i_o_data_fifo_full_X : out_ready;
signal r_o_o_data_fifo_next_X : in_pulse;
signal r_o_o_info_fifo_data : info_bus;
signal r_i_o_info_fifo_full_0 : out_ready;
signal r_o_o_info_fifo_next_0 : in_pulse;
signal r_i_o_info_fifo_full_1 : out_ready;
signal r_o_o_info_fifo_next_1 : in_pulse;
signal r_i_o_info_fifo_full_2 : out_ready;
signal r_o_o_info_fifo_next_2 : in_pulse;
signal r_i_o_info_fifo_full_3 : out_ready;
signal r_o_o_info_fifo_next_3 : in_pulse;
signal r_i_o_info_fifo_full_4 : out_ready;
signal r_o_o_info_fifo_next_4 : in_pulse;
signal r_i_o_info_fifo_full_5 : out_ready;
signal r_o_o_info_fifo_next_5 : in_pulse;
signal r_i_o_info_fifo_full_6 : out_ready;
signal r_o_o_info_fifo_next_6 : in_pulse;
signal r_i_o_info_fifo_full_7 : out_ready;
signal r_o_o_info_fifo_next_7 : in_pulse;
signal r_i_o_info_fifo_full_X : out_ready;
signal r_o_o_info_fifo_next_X : in_pulse;

signal s_i_i_data_fifo_data_X : data_bus;
signal s_i_i_data_fifo_data_0 : data_bus;
signal s_i_i_data_fifo_data_1 : data_bus;
signal s_i_i_data_fifo_data_2 : data_bus;
signal s_i_i_data_fifo_data_3 : data_bus;
signal s_i_i_data_fifo_data_4 : data_bus;
signal s_i_i_data_fifo_data_5 : data_bus;
signal s_i_i_data_fifo_data_6 : data_bus;
signal s_i_i_data_fifo_data_7 : data_bus;
signal s_i_i_data_fifo_empty_X : out_ready;
signal s_o_i_data_fifo_next_X : in_pulse;
signal s_i_i_data_fifo_empty_0 : out_ready;
signal s_o_i_data_fifo_next_0 : in_pulse;
signal s_i_i_data_fifo_empty_1 : out_ready;
signal s_o_i_data_fifo_next_1 : in_pulse;
signal s_i_i_data_fifo_empty_2 : out_ready;
signal s_o_i_data_fifo_next_2 : in_pulse;
signal s_i_i_data_fifo_empty_3 : out_ready;
signal s_o_i_data_fifo_next_3 : in_pulse;
signal s_i_i_data_fifo_empty_4 : out_ready;
signal s_o_i_data_fifo_next_4 : in_pulse;
signal s_i_i_data_fifo_empty_5 : out_ready;
signal s_o_i_data_fifo_next_5 : in_pulse;
signal s_i_i_data_fifo_empty_6 : out_ready;
signal s_o_i_data_fifo_next_6 : in_pulse;
signal s_i_i_data_fifo_empty_7 : out_ready;
signal s_o_i_data_fifo_next_7 : in_pulse;
signal s_o_o_data_fifo_data : data_bus;
signal s_i_o_data_fifo_ready : out_ready;
signal s_o_o_data_fifo_next : in_pulse;
signal s_i_i_info_fifo_data_X : info_bus;
signal s_i_i_info_fifo_data_0 : info_bus;
signal s_i_i_info_fifo_data_1 : info_bus;
signal s_i_i_info_fifo_data_2 : info_bus;
signal s_i_i_info_fifo_data_3 : info_bus;
signal s_i_i_info_fifo_data_4 : info_bus;
signal s_i_i_info_fifo_data_5 : info_bus;
signal s_i_i_info_fifo_data_6 : info_bus;
signal s_i_i_info_fifo_data_7 : info_bus;
signal s_i_i_info_fifo_empty_X : out_ready;
signal s_o_i_info_fifo_next_X : in_pulse;
signal s_i_i_info_fifo_empty_0 : out_ready;
signal s_o_i_info_fifo_next_0 : in_pulse;
signal s_i_i_info_fifo_empty_1 : out_ready;
signal s_o_i_info_fifo_next_1 : in_pulse;
signal s_i_i_info_fifo_empty_2 : out_ready;
signal s_o_i_info_fifo_next_2 : in_pulse;
signal s_i_i_info_fifo_empty_3 : out_ready;
signal s_o_i_info_fifo_next_3 : in_pulse;
signal s_i_i_info_fifo_empty_4 : out_ready;
signal s_o_i_info_fifo_next_4 : in_pulse;
signal s_i_i_info_fifo_empty_5 : out_ready;
signal s_o_i_info_fifo_next_5 : in_pulse;
signal s_i_i_info_fifo_empty_6 : out_ready;
signal s_o_i_info_fifo_next_6 : in_pulse;
signal s_i_i_info_fifo_empty_7 : out_ready;
signal s_o_i_info_fifo_next_7 : in_pulse;
signal s_o_o_info_fifo_data : info_bus;
signal s_i_o_info_fifo_ready : out_ready;
signal s_o_o_info_fifo_next : in_pulse;

signal i2c_3_inter_inner    : std_logic;



begin

  r_i_o_data_fifo_full_5 <= ZERO_BIT;
  r_i_o_data_fifo_full_6 <= ZERO_BIT;
  r_i_o_data_fifo_full_7 <= ZERO_BIT;
  r_i_o_data_fifo_full_X <= ZERO_BIT;
  r_i_o_info_fifo_full_5 <= ZERO_BIT;
  r_i_o_info_fifo_full_6 <= ZERO_BIT;
  r_i_o_info_fifo_full_7 <= ZERO_BIT;
  r_i_o_info_fifo_full_X <= ZERO_BIT;

  s_i_i_data_fifo_data_X <= (others => ZERO_BIT); 
  s_i_i_data_fifo_data_5 <= (others => ZERO_BIT); 
  s_i_i_data_fifo_data_6 <= (others => ZERO_BIT); 
  s_i_i_data_fifo_data_7 <= (others => ZERO_BIT); 
  s_i_i_info_fifo_data_X <= (others => ZERO_BIT); 
  s_i_i_info_fifo_data_5 <= (others => ZERO_BIT); 
  s_i_i_info_fifo_data_6 <= (others => ZERO_BIT); 
  s_i_i_info_fifo_data_7 <= (others => ZERO_BIT); 

  s_i_i_data_fifo_empty_5 <= HIGH_BIT;
  s_i_i_data_fifo_empty_6 <= HIGH_BIT;
  s_i_i_data_fifo_empty_7 <= HIGH_BIT;
  s_i_i_data_fifo_empty_X <= HIGH_BIT;
  s_i_i_info_fifo_empty_5 <= HIGH_BIT;
  s_i_i_info_fifo_empty_6 <= HIGH_BIT;
  s_i_i_info_fifo_empty_7 <= HIGH_BIT;
  s_i_i_info_fifo_empty_X <= HIGH_BIT;


----------------------------------------------------------------------------------------
--SECTION - INSTANCES
----------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
--ANCHOR - ROUTER
----------------------------------------------------------------------------------------
  router_inst : entity work.router
  port map (
    i_clk => i_clk_100MHz,
    i_rst_n => i_rst_n,
    i_out_en =>               (others =>'1'),
    i_bypass =>               r_i_bypass,
    o_err_rep =>              r_o_err_rep,
    i_i_data_fifo_data =>     i_r_o_f_dat,
    i_i_data_fifo_ready =>    not(rt_emty_data),
    o_i_data_fifo_next =>     rt_next_data,
    o_o_data_fifo_data =>     r_o_o_data_fifo_data,
    i_o_data_fifo_full_0 =>  r_i_o_data_fifo_full_0,
    o_o_data_fifo_next_0 =>   r_o_o_data_fifo_next_0,
    i_o_data_fifo_full_1 =>  r_i_o_data_fifo_full_1,
    o_o_data_fifo_next_1 =>   r_o_o_data_fifo_next_1,
    i_o_data_fifo_full_2 =>  r_i_o_data_fifo_full_2,
    o_o_data_fifo_next_2 =>   r_o_o_data_fifo_next_2,
    i_o_data_fifo_full_3 =>  r_i_o_data_fifo_full_3,
    o_o_data_fifo_next_3 =>   r_o_o_data_fifo_next_3,
    i_o_data_fifo_full_4 =>  r_i_o_data_fifo_full_4,
    o_o_data_fifo_next_4 =>   r_o_o_data_fifo_next_4,
    i_o_data_fifo_full_5 =>  r_i_o_data_fifo_full_5,
    o_o_data_fifo_next_5 =>   r_o_o_data_fifo_next_5,
    i_o_data_fifo_full_6 =>  r_i_o_data_fifo_full_6,
    o_o_data_fifo_next_6 =>   r_o_o_data_fifo_next_6,
    i_o_data_fifo_full_7 =>  r_i_o_data_fifo_full_7,
    o_o_data_fifo_next_7 =>   r_o_o_data_fifo_next_7,
    o_o_data_fifo_full_X =>  r_i_o_data_fifo_full_X,
    i_o_data_fifo_next_X =>   s_o_i_data_fifo_next_X,
    i_i_info_fifo_data =>     i_r_o_f_inf,
    i_i_info_fifo_ready =>    not(rt_emty_info),
    o_i_info_fifo_next =>     rt_next_info,
    o_o_info_fifo_data =>     r_o_o_info_fifo_data,
    i_o_info_fifo_full_0 =>  r_i_o_info_fifo_full_0,
    o_o_info_fifo_next_0 =>   r_o_o_info_fifo_next_0,
    i_o_info_fifo_full_1 =>  r_i_o_info_fifo_full_1,
    o_o_info_fifo_next_1 =>   r_o_o_info_fifo_next_1,
    i_o_info_fifo_full_2 =>  r_i_o_info_fifo_full_2,
    o_o_info_fifo_next_2 =>   r_o_o_info_fifo_next_2,
    i_o_info_fifo_full_3 =>  r_i_o_info_fifo_full_3,
    o_o_info_fifo_next_3 =>   r_o_o_info_fifo_next_3,
    i_o_info_fifo_full_4 =>  r_i_o_info_fifo_full_4,
    o_o_info_fifo_next_4 =>   r_o_o_info_fifo_next_4,
    i_o_info_fifo_full_5 =>  r_i_o_info_fifo_full_5,
    o_o_info_fifo_next_5 =>   r_o_o_info_fifo_next_5,
    i_o_info_fifo_full_6 =>  r_i_o_info_fifo_full_6,
    o_o_info_fifo_next_6 =>   r_o_o_info_fifo_next_6,
    i_o_info_fifo_full_7 =>  r_i_o_info_fifo_full_7,
    o_o_info_fifo_next_7 =>   r_o_o_info_fifo_next_7,
    o_o_info_fifo_full_X =>  r_i_o_info_fifo_full_X,
    i_o_info_fifo_next_X =>   s_o_i_info_fifo_next_X
  );

----------------------------------------------------------------------------------------
--ANCHOR - COLLECTOR
----------------------------------------------------------------------------------------
  collector_inst : entity work.collector
  port map (
    i_clk => i_clk_100MHz,
    i_rst_n => i_rst_n,
    o_bypass =>               r_i_bypass,
    i_err_rep =>              r_o_err_rep,
    i_i_data_fifo_data_X =>   r_o_o_data_fifo_data,
    i_i_data_fifo_data_0 =>   s_i_i_data_fifo_data_0,
    i_i_data_fifo_data_1 =>   s_i_i_data_fifo_data_1,
    i_i_data_fifo_data_2 =>   s_i_i_data_fifo_data_2,
    i_i_data_fifo_data_3 =>   s_i_i_data_fifo_data_3,
    i_i_data_fifo_data_4 =>   s_i_i_data_fifo_data_4,
    i_i_data_fifo_data_5 =>   s_i_i_data_fifo_data_5,
    i_i_data_fifo_data_6 =>   s_i_i_data_fifo_data_6,
    i_i_data_fifo_data_7 =>   s_i_i_data_fifo_data_7,
    i_i_data_fifo_empty_X =>  s_i_i_data_fifo_empty_X,
    o_i_data_fifo_next_X =>   s_o_i_data_fifo_next_X,
    i_i_data_fifo_empty_0 =>  s_i_i_data_fifo_empty_0,
    o_i_data_fifo_next_0 =>   s_o_i_data_fifo_next_0,
    i_i_data_fifo_empty_1 =>  s_i_i_data_fifo_empty_1,
    o_i_data_fifo_next_1 =>   s_o_i_data_fifo_next_1,
    i_i_data_fifo_empty_2 =>  s_i_i_data_fifo_empty_2,
    o_i_data_fifo_next_2 =>   s_o_i_data_fifo_next_2,
    i_i_data_fifo_empty_3 =>  s_i_i_data_fifo_empty_3,
    o_i_data_fifo_next_3 =>   s_o_i_data_fifo_next_3,
    i_i_data_fifo_empty_4 =>  s_i_i_data_fifo_empty_4,
    o_i_data_fifo_next_4 =>   s_o_i_data_fifo_next_4,
    i_i_data_fifo_empty_5 =>  s_i_i_data_fifo_empty_5,
    o_i_data_fifo_next_5 =>   s_o_i_data_fifo_next_5,
    i_i_data_fifo_empty_6 =>  s_i_i_data_fifo_empty_6,
    o_i_data_fifo_next_6 =>   s_o_i_data_fifo_next_6,
    i_i_data_fifo_empty_7 =>  s_i_i_data_fifo_empty_7,
    o_i_data_fifo_next_7 =>   s_o_i_data_fifo_next_7,
    o_o_data_fifo_data =>     s_o_o_data_fifo_data,
    i_o_data_fifo_ready =>    not(s_i_o_data_fifo_ready),
    o_o_data_fifo_next =>     s_o_o_data_fifo_next,
    i_i_info_fifo_data_X =>   r_o_o_info_fifo_data,
    i_i_info_fifo_data_0 =>   s_i_i_info_fifo_data_0,
    i_i_info_fifo_data_1 =>   s_i_i_info_fifo_data_1,
    i_i_info_fifo_data_2 =>   s_i_i_info_fifo_data_2,
    i_i_info_fifo_data_3 =>   s_i_i_info_fifo_data_3,
    i_i_info_fifo_data_4 =>   s_i_i_info_fifo_data_4,
    i_i_info_fifo_data_5 =>   s_i_i_info_fifo_data_5,
    i_i_info_fifo_data_6 =>   s_i_i_info_fifo_data_6,
    i_i_info_fifo_data_7 =>   s_i_i_info_fifo_data_7,
    i_i_info_fifo_empty_X =>  s_i_i_info_fifo_empty_X,
    o_i_info_fifo_next_X =>   s_o_i_info_fifo_next_X,
    i_i_info_fifo_empty_0 =>  s_i_i_info_fifo_empty_0,
    o_i_info_fifo_next_0 =>   s_o_i_info_fifo_next_0,
    i_i_info_fifo_empty_1 =>  s_i_i_info_fifo_empty_1,
    o_i_info_fifo_next_1 =>   s_o_i_info_fifo_next_1,
    i_i_info_fifo_empty_2 =>  s_i_i_info_fifo_empty_2,
    o_i_info_fifo_next_2 =>   s_o_i_info_fifo_next_2,
    i_i_info_fifo_empty_3 =>  s_i_i_info_fifo_empty_3,
    o_i_info_fifo_next_3 =>   s_o_i_info_fifo_next_3,
    i_i_info_fifo_empty_4 =>  s_i_i_info_fifo_empty_4,
    o_i_info_fifo_next_4 =>   s_o_i_info_fifo_next_4,
    i_i_info_fifo_empty_5 =>  s_i_i_info_fifo_empty_5,
    o_i_info_fifo_next_5 =>   s_o_i_info_fifo_next_5,
    i_i_info_fifo_empty_6 =>  s_i_i_info_fifo_empty_6,
    o_i_info_fifo_next_6 =>   s_o_i_info_fifo_next_6,
    i_i_info_fifo_empty_7 =>  s_i_i_info_fifo_empty_7,
    o_i_info_fifo_next_7 =>   s_o_i_info_fifo_next_7,
    o_o_info_fifo_data =>     s_o_o_info_fifo_data,
    i_o_info_fifo_ready =>    not(s_i_o_info_fifo_ready),
    o_o_info_fifo_next =>     s_o_o_info_fifo_next
  );

----------------------------------------------------------------------------------------
--ANCHOR - FIFO from master to router
----------------------------------------------------------------------------------------
module_fifo_INFO_MtoF : entity work.FIFO_wrapper
  generic map (
    g_WIDTH => 24,
    g_DEPTH => 32,
    GEN_TYPE => FIFO_MODE
  )
  port map (
    i_rst_sync => (not i_rst_n),
    i_clk =>      i_clk_100MHz,
    i_wr_en =>    ms_push_info,
    i_wr_data =>  o_m_i_f_inf,
    o_full =>     ms_full_info,
    i_rd_en =>    rt_next_info,
    o_rd_data =>  i_r_o_f_inf,
    o_empty =>    rt_emty_info
  );

module_fifo_DATA_MtoF : entity work.FIFO_wrapper
  generic map (
    g_WIDTH => 8,
    g_DEPTH => 512,
    GEN_TYPE => FIFO_MODE
  )
  port map (
    i_rst_sync => (not i_rst_n),
    i_clk => i_clk_100MHz,
    i_wr_en => ms_push_data,
    i_wr_data => o_m_i_f_dat,
    o_full => ms_full_data,
    i_rd_en => rt_next_data,
    o_rd_data => i_r_o_f_dat,
    o_empty => rt_emty_data
  );
  
----------------------------------------------------------------------------------------
--ANCHOR - FIFO from collector to master
----------------------------------------------------------------------------------------
module_fifo_INFO_FtoM : entity work.FIFO_wrapper
  generic map (
    g_WIDTH => 24,
    g_DEPTH => 32,
    GEN_TYPE => FIFO_MODE
  )
  port map (
    i_rst_sync => (not i_rst_n),
    i_clk => i_clk_100MHz,
    i_wr_en => s_o_o_info_fifo_next,
    i_wr_data => s_o_o_info_fifo_data,
    o_full => s_i_o_info_fifo_ready,
    i_rd_en => ms_next_info,
    o_rd_data => i_m_o_f_inf,
    o_empty => ms_emty_info
  );

module_fifo_DATA_FtoM : entity work.FIFO_wrapper
  generic map (
    g_WIDTH => 8,
    g_DEPTH => 512,
    GEN_TYPE => FIFO_MODE
  )
  port map (
    i_rst_sync => (not i_rst_n),
    i_clk => i_clk_100MHz,
    i_wr_en => s_o_o_data_fifo_next,
    i_wr_data => s_o_o_data_fifo_data,
    o_full => s_i_o_data_fifo_ready,
    i_rd_en => ms_next_data,
    o_rd_data => i_m_o_f_dat,
    o_empty => ms_emty_data
  );

  ----------------------------------------------------------------------------------------
  --ANCHOR - MAIN INTERFACE
  ----------------------------------------------------------------------------------------
  main_ctrl_inst : entity work.main_ctrl_2
  port map (
    i_clk => i_clk_100MHz,
    i_rst_n => i_rst_n,
    i_i_data_fifo_data => i_m_o_f_dat,
    i_i_data_fifo_ready => (not ms_emty_data),
    o_i_data_fifo_next => ms_next_data,
    o_o_data_fifo_data => o_m_i_f_dat,
    i_o_data_fifo_ready => (not ms_full_data),
    o_o_data_fifo_next => ms_push_data,
    i_i_info_fifo_data => i_m_o_f_inf,
    i_i_info_fifo_ready => (not ms_emty_info),
    o_i_info_fifo_next => ms_next_info,
    o_o_info_fifo_data => o_m_i_f_inf,
    i_o_info_fifo_ready => (not ms_full_info),
    o_o_info_fifo_next => ms_push_info,
    i_settings => settings_main,
    o_ready => o_ready,
    tx => main_tx,
    rx => main_rx
  );

  
  ----------------------------------------------------------------------------------------
  --ANCHOR - Design Config
  ----------------------------------------------------------------------------------------
  design_config_inst : entity work.design_config
  port map (
    clk => i_clk_100MHz,
    rst_n => i_rst_n,
    i_i_data_fifo_data =>  r_o_o_data_fifo_data,
    i_i_data_fifo_write => r_o_o_data_fifo_next_0,
    o_i_data_fifo_blck =>  r_i_o_data_fifo_full_0,
    o_o_data_fifo_data =>  s_i_i_data_fifo_data_0,
    i_o_data_fifo_read =>  s_o_i_data_fifo_next_0,
    o_o_data_fifo_blck =>  s_i_i_data_fifo_empty_0,
    i_i_info_fifo_data =>  r_o_o_info_fifo_data,
    i_i_info_fifo_write => r_o_o_info_fifo_next_0,
    o_i_info_fifo_blck =>  r_i_o_info_fifo_full_0,
    o_o_info_fifo_data =>  s_i_i_info_fifo_data_0,
    i_o_info_fifo_read =>  s_o_i_info_fifo_next_0,
    o_o_info_fifo_blck =>  s_i_i_info_fifo_empty_0,
    o_settings_main => settings_main,
    o_enable_interfaces => enable_interfaces
  );


  ----------------------------------------------------------------------------------------
  --ANCHOR - SLAVE INTERFACE 1
  ----------------------------------------------------------------------------------------
  uart_module_slv1 : entity work.uart_module
  generic map(
    ID => "001",
    GEN_TYPE => FIFO_MODE
  )
  port map (
    i_clk => i_clk_100MHz,
    i_rst_n => i_rst_n,
    i_en => enable_interfaces(0),
    i_i_info_write => r_o_o_info_fifo_next_1,
    i_i_info_data => r_o_o_info_fifo_data,
    i_o_info_full => r_i_o_info_fifo_full_1,
    i_i_data_write => r_o_o_data_fifo_next_1,
    i_i_data_data => r_o_o_data_fifo_data,
    i_o_data_full => r_i_o_data_fifo_full_1,
    o_i_info_next => s_o_i_info_fifo_next_1,
    o_o_info_data => s_i_i_info_fifo_data_1,
    o_o_info_empty => s_i_i_info_fifo_empty_1,
    o_i_data_next => s_o_i_data_fifo_next_1,
    o_o_data_data => s_i_i_data_fifo_data_1,
    o_o_data_empty => s_i_i_data_fifo_empty_1,
    slv_tx => slv1_tx,
    slv_rx => slv1_rx
  );


----------------------------------------------------------------------------------------
--ANCHOR - SLAVE INTERFACE 2
----------------------------------------------------------------------------------------
uart_i2c_module_slv2 : entity work.uart_i2c_module
  generic map(
    ID => "010",
    GEN_TYPE => FIFO_MODE
  )
  port map (
    i_clk => i_clk_100MHz,
    i_rst_n => i_rst_n,
    i_en => enable_interfaces(2 downto 1),
    i_i_info_write => r_o_o_info_fifo_next_2,
    i_i_info_data => r_o_o_info_fifo_data,
    i_o_info_full => r_i_o_info_fifo_full_2,
    i_i_data_write => r_o_o_data_fifo_next_2,
    i_i_data_data => r_o_o_data_fifo_data,
    i_o_data_full => r_i_o_data_fifo_full_2,
    o_i_info_next => s_o_i_info_fifo_next_2,
    o_o_info_data => s_i_i_info_fifo_data_2,
    o_o_info_empty => s_i_i_info_fifo_empty_2,
    o_i_data_next => s_o_i_data_fifo_next_2,
    o_o_data_data => s_i_i_data_fifo_data_2,
    o_o_data_empty => s_i_i_data_fifo_empty_2,
    tx_scl => slv2_tx,
    rx_sda => slv2_rx,
    i_interrupt_tx_rdy => '1'
  );

----------------------------------------------------------------------------------------
--ANCHOR - SLAVE INTERFACE 3
----------------------------------------------------------------------------------------
  i2c_module_3 : entity work.i2c_module
  generic map (
    ID => "011",
    GEN_TYPE => FIFO_MODE
  )
  port map (
    i_clk => i_clk_100MHz,
    i_rst_n => i_rst_n,
    i_en => enable_interfaces(3),
    i_i_info_write => r_o_o_info_fifo_next_3,
    i_i_info_data => r_o_o_info_fifo_data,
    i_o_info_full => r_i_o_info_fifo_full_3,
    i_i_data_write => r_o_o_data_fifo_next_3,
    i_i_data_data => r_o_o_data_fifo_data,
    i_o_data_full => r_i_o_data_fifo_full_3,
    o_i_info_next => s_o_i_info_fifo_next_3,
    o_o_info_data => s_i_i_info_fifo_data_3,
    o_o_info_empty => s_i_i_info_fifo_empty_3,
    o_i_data_next => s_o_i_data_fifo_next_3,
    o_o_data_data => s_i_i_data_fifo_data_3,
    o_o_data_empty => s_i_i_data_fifo_empty_3,
    scl => scl_3,
    sda => sda_3,
    i_interrupt => i2c_3_inter,
    o_interrupt => i2c_3_inter_inner
  );


----------------------------------------------------------------------------------------
--ANCHOR - SLAVE INTERFACE 4
----------------------------------------------------------------------------------------
SPI_module_4 : entity work.SPI_module
generic map (
  ID => "100",
  GEN_TYPE => FIFO_MODE
)
port map (
  i_clk => i_clk_100MHz,
  i_rst_n => i_rst_n,
  i_en => enable_interfaces(4),
  i_i_info_write => r_o_o_info_fifo_next_4,
  i_i_info_data => r_o_o_info_fifo_data,
  i_o_info_full => r_i_o_info_fifo_full_4,
  i_i_data_write => r_o_o_data_fifo_next_4,
  i_i_data_data => r_o_o_data_fifo_data,
  i_o_data_full => r_i_o_data_fifo_full_4,
  o_i_info_next => s_o_i_info_fifo_next_4,
  o_o_info_data => s_i_i_info_fifo_data_4,
  o_o_info_empty => s_i_i_info_fifo_empty_4,
  o_i_data_next => s_o_i_data_fifo_next_4,
  o_o_data_data => s_i_i_data_fifo_data_4,
  o_o_data_empty => s_i_i_data_fifo_empty_4,
  MISO => MISO_4,
  MOSI => MOSI_4,
  SCLK => SCLK_4,
  o_CS => o_CS_4
);


--!SECTION
end architecture;--!SECTION