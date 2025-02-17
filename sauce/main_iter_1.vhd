library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
library work;
use work.my_common.all;


entity main is

end entity main;

----------------------------------------------------------------------------------------
--SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture behavioral of main is 

constant CLK_PERIOD : TIME := 10 ns;

signal i_clk          : std_logic;
signal i_rst_n        : std_logic;

signal o_m_i_f_inf, i_r_o_f_inf, i_m_o_f_inf, o_r_i_f_inf, i_s_o_f_inf, o_s_i_f_inf     : info_bus;
signal o_m_i_f_dat, i_r_o_f_dat, i_m_o_f_dat, o_r_i_f_dat, i_s_o_f_dat, o_s_i_f_dat      : data_bus;

signal sl1_push_info   : std_logic;
signal sl1_push_data   : std_logic;
signal sl1_next_info   : std_logic;
signal sl1_next_data   : std_logic;
signal sl1_emty_info   : std_logic;
signal sl1_emty_data   : std_logic;
signal sl1_full_info   : std_logic;
signal sl1_full_data   : std_logic;

signal ms_push_info, ms_push_data, ms_next_info, ms_next_data, ms_emty_info, ms_emty_data, ms_full_info, ms_full_data   : std_logic;

signal rt_push_info, rt_push_data, rt_next_info, rt_next_data, rt_emty_info, rt_emty_data, rt_full_info, rt_full_data   : std_logic;

signal cl_push_info, cl_push_data, cl_next_info, cl_next_data, cl_emty_info, cl_emty_data, cl_full_info, cl_full_data   : std_logic;

signal tx_sl          : std_logic;
signal rx_sl          : std_logic;
signal tx_ms          : std_logic;
signal rx_ms          : std_logic;

signal i_settings     : std_logic_array (1 to 2) (MSG_W -1 downto 0);
signal o_ready        : std_logic;

signal gen_header     : info_bus;
signal msg_to_ms      : data_bus;

signal r_i_out_en : std_logic_vector(MSG_W -1 downto 0);
signal r_i_bypass : std_logic;
signal r_o_err_rep : std_logic;

signal r_i_i_data_fifo_data : data_bus;
signal r_i_i_data_fifo_ready : out_ready;
signal r_o_i_data_fifo_next : in_pulse;
signal r_o_o_data_fifo_data : data_bus;
signal r_i_o_data_fifo_ready_0 : out_ready;
signal r_o_o_data_fifo_next_0 : in_pulse;
signal r_i_o_data_fifo_ready_1 : out_ready;
signal r_o_o_data_fifo_next_1 : in_pulse;
signal r_i_o_data_fifo_ready_2 : out_ready;
signal r_o_o_data_fifo_next_2 : in_pulse;
signal r_i_o_data_fifo_ready_3 : out_ready;
signal r_o_o_data_fifo_next_3 : in_pulse;
signal r_i_o_data_fifo_ready_4 : out_ready;
signal r_o_o_data_fifo_next_4 : in_pulse;
signal r_i_o_data_fifo_ready_5 : out_ready;
signal r_o_o_data_fifo_next_5 : in_pulse;
signal r_i_o_data_fifo_ready_6 : out_ready;
signal r_o_o_data_fifo_next_6 : in_pulse;
signal r_i_o_data_fifo_ready_7 : out_ready;
signal r_o_o_data_fifo_next_7 : in_pulse;
signal r_i_o_data_fifo_ready_X : out_ready;
signal r_o_o_data_fifo_next_X : in_pulse;
signal r_i_i_info_fifo_data : info_bus;
signal r_i_i_info_fifo_ready : out_ready;
signal r_o_i_info_fifo_next : in_pulse;
signal r_o_o_info_fifo_data : info_bus;
signal r_i_o_info_fifo_ready_0 : out_ready;
signal r_o_o_info_fifo_next_0 : in_pulse;
signal r_i_o_info_fifo_ready_1 : out_ready;
signal r_o_o_info_fifo_next_1 : in_pulse;
signal r_i_o_info_fifo_ready_2 : out_ready;
signal r_o_o_info_fifo_next_2 : in_pulse;
signal r_i_o_info_fifo_ready_3 : out_ready;
signal r_o_o_info_fifo_next_3 : in_pulse;
signal r_i_o_info_fifo_ready_4 : out_ready;
signal r_o_o_info_fifo_next_4 : in_pulse;
signal r_i_o_info_fifo_ready_5 : out_ready;
signal r_o_o_info_fifo_next_5 : in_pulse;
signal r_i_o_info_fifo_ready_6 : out_ready;
signal r_o_o_info_fifo_next_6 : in_pulse;
signal r_i_o_info_fifo_ready_7 : out_ready;
signal r_o_o_info_fifo_next_7 : in_pulse;
signal r_i_o_info_fifo_ready_X : out_ready;
signal r_o_o_info_fifo_next_X : in_pulse;

signal s_i_i_data_fifo_data : data_bus;
signal s_i_i_data_fifo_ready_X : out_ready;
signal s_o_i_data_fifo_next_X : in_pulse;
signal s_i_i_data_fifo_ready_0 : out_ready;
signal s_o_i_data_fifo_next_0 : in_pulse;
signal s_i_i_data_fifo_ready_1 : out_ready;
signal s_o_i_data_fifo_next_1 : in_pulse;
signal s_i_i_data_fifo_ready_2 : out_ready;
signal s_o_i_data_fifo_next_2 : in_pulse;
signal s_i_i_data_fifo_ready_3 : out_ready;
signal s_o_i_data_fifo_next_3 : in_pulse;
signal s_i_i_data_fifo_ready_4 : out_ready;
signal s_o_i_data_fifo_next_4 : in_pulse;
signal s_i_i_data_fifo_ready_5 : out_ready;
signal s_o_i_data_fifo_next_5 : in_pulse;
signal s_i_i_data_fifo_ready_6 : out_ready;
signal s_o_i_data_fifo_next_6 : in_pulse;
signal s_i_i_data_fifo_ready_7 : out_ready;
signal s_o_i_data_fifo_next_7 : in_pulse;
signal s_o_o_data_fifo_data : data_bus;
signal s_i_o_data_fifo_ready : out_ready;
signal s_o_o_data_fifo_next : in_pulse;
signal s_i_i_info_fifo_data : info_bus;
signal s_i_i_info_fifo_ready_X : out_ready;
signal s_o_i_info_fifo_next_X : in_pulse;
signal s_i_i_info_fifo_ready_0 : out_ready;
signal s_o_i_info_fifo_next_0 : in_pulse;
signal s_i_i_info_fifo_ready_1 : out_ready;
signal s_o_i_info_fifo_next_1 : in_pulse;
signal s_i_i_info_fifo_ready_2 : out_ready;
signal s_o_i_info_fifo_next_2 : in_pulse;
signal s_i_i_info_fifo_ready_3 : out_ready;
signal s_o_i_info_fifo_next_3 : in_pulse;
signal s_i_i_info_fifo_ready_4 : out_ready;
signal s_o_i_info_fifo_next_4 : in_pulse;
signal s_i_i_info_fifo_ready_5 : out_ready;
signal s_o_i_info_fifo_next_5 : in_pulse;
signal s_i_i_info_fifo_ready_6 : out_ready;
signal s_o_i_info_fifo_next_6 : in_pulse;
signal s_i_i_info_fifo_ready_7 : out_ready;
signal s_o_i_info_fifo_next_7 : in_pulse;
signal s_o_o_info_fifo_data : info_bus;
signal s_i_o_info_fifo_ready : out_ready;
signal s_o_o_info_fifo_next : in_pulse;



begin
----------------------------------------------------------------------------------------
--SECTION - INSTANCES
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--ANCHOR - FIFO from master to router
----------------------------------------------------------------------------------------
module_fifo_INFO_MtoF : entity work.module_fifo_regs_no_flags
  generic map (
    g_WIDTH => 24,
    g_DEPTH => 32
  )
  port map (
    i_rst_sync => (not i_rst_n),
    i_clk =>      i_clk,
    i_wr_en =>    ms_push_info,
    i_wr_data =>  o_m_i_f_inf,
    o_full =>     ms_full_info,
    i_rd_en =>    rt_next_info,
    o_rd_data =>  i_r_o_f_inf,
    o_empty =>    rt_emty_info
  );

  module_fifo_DATA_MtoF : entity work.module_fifo_regs_no_flags
  generic map (
    g_WIDTH => 8,
    g_DEPTH => 512
  )
  port map (
    i_rst_sync => (not i_rst_n),
    i_clk => i_clk,
    i_wr_en => ms_push_data,
    i_wr_data => o_m_i_f_dat,
    o_full => ms_full_data,
    i_rd_en => rt_next_data,
    o_rd_data => i_r_o_f_dat,
    o_empty => rt_emty_data
  );
  
  ----------------------------------------------------------------------------------------
  --ANCHOR - FIFO from router to master
  ----------------------------------------------------------------------------------------
  
  module_fifo_INFO_FtoM : entity work.module_fifo_regs_no_flags
  generic map (
    g_WIDTH => 24,
    g_DEPTH => 32
  )
  port map (
    i_rst_sync => (not i_rst_n),
    i_clk => i_clk,
    i_wr_en => sl1_push_info,
    i_wr_data => o_r_i_f_inf,
    o_full => sl1_full_info,
    i_rd_en => ms_next_info,
    o_rd_data => i_m_o_f_inf,
    o_empty => ms_emty_info
  );

  module_fifo_DATA_FtoM : entity work.module_fifo_regs_no_flags
  generic map (
    g_WIDTH => 8,
    g_DEPTH => 512
  )
  port map (
    i_rst_sync => (not i_rst_n),
    i_clk => i_clk,
    i_wr_en => sl1_push_data,
    i_wr_data => o_r_i_f_dat,
    o_full => sl1_full_data,
    i_rd_en => ms_next_data,
    o_rd_data => i_m_o_f_dat,
    o_empty => ms_emty_data
  );

  ----------------------------------------------------------------------------------------
  --ANCHOR - ROUTER
  ----------------------------------------------------------------------------------------

  

  router_inst : entity work.router
  port map (
    i_clk => i_clk,
    i_rst_n => i_rst_n,
    i_out_en =>               r_i_out_en,
    i_bypass =>               r_i_bypass,
    o_err_rep =>              r_o_err_rep,
    i_i_data_fifo_data =>     r_i_i_data_fifo_data,
    i_i_data_fifo_ready =>    r_i_i_data_fifo_ready,
    o_i_data_fifo_next =>     r_o_i_data_fifo_next,
    o_o_data_fifo_data =>     r_o_o_data_fifo_data,
    i_o_data_fifo_ready_0 =>  r_i_o_data_fifo_ready_0,
    o_o_data_fifo_next_0 =>   r_o_o_data_fifo_next_0,
    i_o_data_fifo_ready_1 =>  r_i_o_data_fifo_ready_1,
    o_o_data_fifo_next_1 =>   r_o_o_data_fifo_next_1,
    i_o_data_fifo_ready_2 =>  r_i_o_data_fifo_ready_2,
    o_o_data_fifo_next_2 =>   r_o_o_data_fifo_next_2,
    i_o_data_fifo_ready_3 =>  r_i_o_data_fifo_ready_3,
    o_o_data_fifo_next_3 =>   r_o_o_data_fifo_next_3,
    i_o_data_fifo_ready_4 =>  r_i_o_data_fifo_ready_4,
    o_o_data_fifo_next_4 =>   r_o_o_data_fifo_next_4,
    i_o_data_fifo_ready_5 =>  r_i_o_data_fifo_ready_5,
    o_o_data_fifo_next_5 =>   r_o_o_data_fifo_next_5,
    i_o_data_fifo_ready_6 =>  r_i_o_data_fifo_ready_6,
    o_o_data_fifo_next_6 =>   r_o_o_data_fifo_next_6,
    i_o_data_fifo_ready_7 =>  r_i_o_data_fifo_ready_7,
    o_o_data_fifo_next_7 =>   r_o_o_data_fifo_next_7,
    i_o_data_fifo_ready_X =>  r_i_o_data_fifo_ready_X,
    o_o_data_fifo_next_X =>   r_o_o_data_fifo_next_X,
    i_i_info_fifo_data =>     r_i_i_info_fifo_data,
    i_i_info_fifo_ready =>    r_i_i_info_fifo_ready,
    o_i_info_fifo_next =>     r_o_i_info_fifo_next,
    o_o_info_fifo_data =>     r_o_o_info_fifo_data,
    i_o_info_fifo_ready_0 =>  r_i_o_info_fifo_ready_0,
    o_o_info_fifo_next_0 =>   r_o_o_info_fifo_next_0,
    i_o_info_fifo_ready_1 =>  r_i_o_info_fifo_ready_1,
    o_o_info_fifo_next_1 =>   r_o_o_info_fifo_next_1,
    i_o_info_fifo_ready_2 =>  r_i_o_info_fifo_ready_2,
    o_o_info_fifo_next_2 =>   r_o_o_info_fifo_next_2,
    i_o_info_fifo_ready_3 =>  r_i_o_info_fifo_ready_3,
    o_o_info_fifo_next_3 =>   r_o_o_info_fifo_next_3,
    i_o_info_fifo_ready_4 =>  r_i_o_info_fifo_ready_4,
    o_o_info_fifo_next_4 =>   r_o_o_info_fifo_next_4,
    i_o_info_fifo_ready_5 =>  r_i_o_info_fifo_ready_5,
    o_o_info_fifo_next_5 =>   r_o_o_info_fifo_next_5,
    i_o_info_fifo_ready_6 =>  r_i_o_info_fifo_ready_6,
    o_o_info_fifo_next_6 =>   r_o_o_info_fifo_next_6,
    i_o_info_fifo_ready_7 =>  r_i_o_info_fifo_ready_7,
    o_o_info_fifo_next_7 =>   r_o_o_info_fifo_next_7,
    i_o_info_fifo_ready_X =>  r_i_o_info_fifo_ready_X,
    o_o_info_fifo_next_X =>   r_o_o_info_fifo_next_X
  );

  
  ----------------------------------------------------------------------------------------
  --ANCHOR - COLLECTOR
  ----------------------------------------------------------------------------------------
  collector_inst : entity work.collector
  port map (
    i_clk => i_clk,
    i_rst_n => i_rst_n,
    o_bypass =>               r_i_bypass,
    i_err_rep =>              r_o_err_rep,
    i_i_data_fifo_data =>     s_i_i_data_fifo_data,
    i_i_data_fifo_ready_X =>  s_i_i_data_fifo_ready_X,
    o_i_data_fifo_next_X =>   s_o_i_data_fifo_next_X,
    i_i_data_fifo_ready_0 =>  s_i_i_data_fifo_ready_0,
    o_i_data_fifo_next_0 =>   s_o_i_data_fifo_next_0,
    i_i_data_fifo_ready_1 =>  s_i_i_data_fifo_ready_1,
    o_i_data_fifo_next_1 =>   s_o_i_data_fifo_next_1,
    i_i_data_fifo_ready_2 =>  s_i_i_data_fifo_ready_2,
    o_i_data_fifo_next_2 =>   s_o_i_data_fifo_next_2,
    i_i_data_fifo_ready_3 =>  s_i_i_data_fifo_ready_3,
    o_i_data_fifo_next_3 =>   s_o_i_data_fifo_next_3,
    i_i_data_fifo_ready_4 =>  s_i_i_data_fifo_ready_4,
    o_i_data_fifo_next_4 =>   s_o_i_data_fifo_next_4,
    i_i_data_fifo_ready_5 =>  s_i_i_data_fifo_ready_5,
    o_i_data_fifo_next_5 =>   s_o_i_data_fifo_next_5,
    i_i_data_fifo_ready_6 =>  s_i_i_data_fifo_ready_6,
    o_i_data_fifo_next_6 =>   s_o_i_data_fifo_next_6,
    i_i_data_fifo_ready_7 =>  s_i_i_data_fifo_ready_7,
    o_i_data_fifo_next_7 =>   s_o_i_data_fifo_next_7,
    o_o_data_fifo_data =>     s_o_o_data_fifo_data,
    i_o_data_fifo_ready =>    s_i_o_data_fifo_ready,
    o_o_data_fifo_next =>     s_o_o_data_fifo_next,
    i_i_info_fifo_data =>     s_i_i_info_fifo_data,
    i_i_info_fifo_ready_X =>  s_i_i_info_fifo_ready_X,
    o_i_info_fifo_next_X =>   s_o_i_info_fifo_next_X,
    i_i_info_fifo_ready_0 =>  s_i_i_info_fifo_ready_0,
    o_i_info_fifo_next_0 =>   s_o_i_info_fifo_next_0,
    i_i_info_fifo_ready_1 =>  s_i_i_info_fifo_ready_1,
    o_i_info_fifo_next_1 =>   s_o_i_info_fifo_next_1,
    i_i_info_fifo_ready_2 =>  s_i_i_info_fifo_ready_2,
    o_i_info_fifo_next_2 =>   s_o_i_info_fifo_next_2,
    i_i_info_fifo_ready_3 =>  s_i_i_info_fifo_ready_3,
    o_i_info_fifo_next_3 =>   s_o_i_info_fifo_next_3,
    i_i_info_fifo_ready_4 =>  s_i_i_info_fifo_ready_4,
    o_i_info_fifo_next_4 =>   s_o_i_info_fifo_next_4,
    i_i_info_fifo_ready_5 =>  s_i_i_info_fifo_ready_5,
    o_i_info_fifo_next_5 =>   s_o_i_info_fifo_next_5,
    i_i_info_fifo_ready_6 =>  s_i_i_info_fifo_ready_6,
    o_i_info_fifo_next_6 =>   s_o_i_info_fifo_next_6,
    i_i_info_fifo_ready_7 =>  s_i_i_info_fifo_ready_7,
    o_i_info_fifo_next_7 =>   s_o_i_info_fifo_next_7,
    o_o_info_fifo_data =>     s_o_o_info_fifo_data,
    i_o_info_fifo_ready =>    s_i_o_info_fifo_ready,
    o_o_info_fifo_next =>     s_o_o_info_fifo_next
  );

  ----------------------------------------------------------------------------------------
  --ANCHOR - MAIN INTERFACE
  ----------------------------------------------------------------------------------------
  main_ctrl_inst : entity work.main_ctrl
  port map (
    i_clk => i_clk,
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
    i_settings => i_settings,
    o_ready => o_ready,
    comm_wire_0 => tx_ms,
    comm_wire_1 => rx_ms
  );


  ----------------------------------------------------------------------------------------
  --ANCHOR - SLAVE INTERFACE 1
  ----------------------------------------------------------------------------------------
  uart_ctrl_inst1 : entity work.uart_ctrl
  generic map (
    MSG_W => MSG_W,
    SMPL_W => SMPL_W,
    START_OFFSET => START_OFFSET,
    MY_ID => "000"
  )
  port map (
    i_clk => i_clk,
    i_rst_n => i_rst_n,
    i_en => '1',
    i_i_data_fifo_data => i_s_o_f_dat,
    i_i_data_fifo_ready => (not sl1_emty_data),
    o_i_data_fifo_next => sl1_next_data,
    o_o_data_fifo_data => o_s_i_f_dat,
    i_o_data_fifo_ready => (not sl1_full_data),
    o_o_data_fifo_next => sl1_push_data,
    i_i_info_fifo_data => i_s_o_f_inf,
    i_i_info_fifo_ready => (not sl1_emty_info),
    o_i_info_fifo_next => sl1_next_info,
    o_o_info_fifo_data => o_s_i_f_inf,
    i_o_info_fifo_ready => (not sl1_full_info),
    o_o_info_fifo_next => sl1_push_info,
    comm_wire_0 => tx_sl,
    comm_wire_1 => tx_sl
  );

--!SECTION
end architecture;--!SECTION