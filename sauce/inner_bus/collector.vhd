library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.numeric_std_unsigned.all;

library work;
  use work.my_common.all;

----------------------------------------------------------------------------------------
-- #ANCHOR - ENTITY
----------------------------------------------------------------------------------------

entity collector is
  port (
    
    i_clk                   : in    std_logic;
    i_rst_n                 : in    std_logic;

    i_bypass                : in    std_logic;
    o_err_rep               : out   std_logic;

    i_i_data_fifo_data      : in    data_bus;
    i_i_data_fifo_ready_X   : in    out_ready;
    o_i_data_fifo_next_X    : out   in_pulse;
    i_i_data_fifo_ready_0   : in    out_ready;
    o_i_data_fifo_next_0    : out   in_pulse;
    i_i_data_fifo_ready_1   : in    out_ready;
    o_i_data_fifo_next_1    : out   in_pulse;
    i_i_data_fifo_ready_2   : in    out_ready;
    o_i_data_fifo_next_2    : out   in_pulse;
    i_i_data_fifo_ready_3   : in    out_ready;
    o_i_data_fifo_next_3    : out   in_pulse;
    i_i_data_fifo_ready_4   : in    out_ready;
    o_i_data_fifo_next_4    : out   in_pulse;
    i_i_data_fifo_ready_5   : in    out_ready;
    o_i_data_fifo_next_5    : out   in_pulse;
    i_i_data_fifo_ready_6   : in    out_ready;
    o_i_data_fifo_next_6    : out   in_pulse;
    i_i_data_fifo_ready_7   : in    out_ready;
    o_i_data_fifo_next_7    : out   in_pulse;

    o_o_data_fifo_data      : out   data_bus;
    i_o_data_fifo_ready     : in    out_ready;
    o_o_data_fifo_next      : out   in_pulse;

    i_i_info_fifo_data      : in    info_bus;
    i_i_info_fifo_ready_X   : in    out_ready;
    o_i_info_fifo_next_X    : out   in_pulse;
    i_i_info_fifo_ready_0   : in    out_ready;
    o_i_info_fifo_next_0    : out   in_pulse;
    i_i_info_fifo_ready_1   : in    out_ready;
    o_i_info_fifo_next_1    : out   in_pulse;
    i_i_info_fifo_ready_2   : in    out_ready;
    o_i_info_fifo_next_2    : out   in_pulse;
    i_i_info_fifo_ready_3   : in    out_ready;
    o_i_info_fifo_next_3    : out   in_pulse;
    i_i_info_fifo_ready_4   : in    out_ready;
    o_i_info_fifo_next_4    : out   in_pulse;
    i_i_info_fifo_ready_5   : in    out_ready;
    o_i_info_fifo_next_5    : out   in_pulse;
    i_i_info_fifo_ready_6   : in    out_ready;
    o_i_info_fifo_next_6    : out   in_pulse;
    i_i_info_fifo_ready_7   : in    out_ready;
    o_i_info_fifo_next_7    : out   in_pulse;

    o_o_info_fifo_data      : out   info_bus;
    i_o_info_fifo_ready     : in    out_ready;
    o_o_info_fifo_next      : out   in_pulse

  );
end entity collector;

----------------------------------------------------------------------------------------
--SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture behavioral of collector is

  type fsm_selector is(
    st_selector_idle,
    st_selector_search,
    st_selector_data,
    st_selector_head,
    st_selector_report,
    st_selector_bypass
  );

  signal src_info_ready   : std_logic;
  signal src_info_next    : std_logic;

  signal src_data_ready   : std_logic;
  signal src_data_next    : std_logic;

  signal target           : std_ulogic_vector(2 downto 0);


begin
  ----------------------------------------------------------------------------------------
  -- #ANCHOR - PIN ASSIGMENT
  ----------------------------------------------------------------------------------------

  src_info_ready <= i_i_info_fifo_ready_0 when (target = 0) else
                    i_i_info_fifo_ready_1 when (target = 1) else
                    i_i_info_fifo_ready_2 when (target = 2) else
                    i_i_info_fifo_ready_3 when (target = 3) else
                    i_i_info_fifo_ready_4 when (target = 4) else
                    i_i_info_fifo_ready_5 when (target = 5) else
                    i_i_info_fifo_ready_6 when (target = 6) else
                    i_i_info_fifo_ready_7 ;

  src_data_ready <= i_i_data_fifo_ready_0 when (target = 0) else
                    i_i_data_fifo_ready_1 when (target = 1) else
                    i_i_data_fifo_ready_2 when (target = 2) else
                    i_i_data_fifo_ready_3 when (target = 3) else
                    i_i_data_fifo_ready_4 when (target = 4) else
                    i_i_data_fifo_ready_5 when (target = 5) else
                    i_i_data_fifo_ready_6 when (target = 6) else
                    i_i_data_fifo_ready_7 ;

  o_i_info_fifo_next_0 <= src_info_next when (target = 0) else '0';
  o_i_info_fifo_next_1 <= src_info_next when (target = 1) else '0';
  o_i_info_fifo_next_2 <= src_info_next when (target = 2) else '0';
  o_i_info_fifo_next_3 <= src_info_next when (target = 3) else '0';
  o_i_info_fifo_next_4 <= src_info_next when (target = 4) else '0';
  o_i_info_fifo_next_5 <= src_info_next when (target = 5) else '0';
  o_i_info_fifo_next_6 <= src_info_next when (target = 6) else '0';
  o_i_info_fifo_next_7 <= src_info_next when (target = 7) else '0';

  o_i_data_fifo_next_0 <= src_data_next when (target = 0) else '0';
  o_i_data_fifo_next_1 <= src_data_next when (target = 1) else '0';
  o_i_data_fifo_next_2 <= src_data_next when (target = 2) else '0';
  o_i_data_fifo_next_3 <= src_data_next when (target = 3) else '0';
  o_i_data_fifo_next_4 <= src_data_next when (target = 4) else '0';
  o_i_data_fifo_next_5 <= src_data_next when (target = 5) else '0';
  o_i_data_fifo_next_6 <= src_data_next when (target = 6) else '0';
  o_i_data_fifo_next_7 <= src_data_next when (target = 7) else '0';

  ----------------------------------------------------------------------------------------
-- #ANCHOR - MAIN PROCESS
----------------------------------------------------------------------------------------
p_main  : process (i_clk) is

  begin

  end process;


end architecture; --!SECTION 
