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

    o_bypass                : out   std_logic;
    i_err_rep               : in    std_logic;

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
    st_selector_start,
    st_selector_search,
    st_selector_head,
    st_selector_data,
    st_selector_report,
    st_selector_bypass
  );

  signal st_selector      : fsm_selector;

  signal src_info_ready   : std_logic;
  signal src_info_next    : std_logic;

  signal src_data_ready   : std_logic;
  signal src_data_next    : std_logic;

  signal target           : std_ulogic_vector(2 downto 0);
  signal header           : info_bus;
  signal data_cnt         : unsigned(MSG_W - 1 downto 0);


begin
  ----------------------------------------------------------------------------------------
  -- #ANCHOR - PIN ASSIGMENT
  ----------------------------------------------------------------------------------------


  o_o_data_fifo_data <= i_i_data_fifo_data;
  o_o_info_fifo_data <= i_i_info_fifo_data;

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

    if (i_rst_n = '0') then
      st_selector <= st_selector_start;
      target <= (others => '0') ;
      o_bypass <= '0';
      data_cnt <= to_unsigned(0,MSG_W);
      o_o_data_fifo_next <= '0';
      src_data_next <= '0';
    elsif (rising_edge(i_clk)) then
      o_bypass <= '0';
      o_o_data_fifo_next <= '0';
      src_data_next <= '0';
      case st_selector is

        when st_selector_start =>
          if (i_err_rep = '1') then
            st_selector <= st_selector_report;
            o_bypass <= '1';
          else
            st_selector <= st_selector_search;
          end if;

        when st_selector_search =>
          if (src_info_ready = '1') then
            st_selector <= st_selector_head;  
          else
            if (target = 7) then
              st_selector <= st_selector_start;  
            end if;
            target <= target + 1;
          end if;

        when st_selector_head =>
          header <= i_i_info_fifo_data;
          src_info_next <= '1';
          data_cnt <= to_unsigned(0,MSG_W);
          st_selector <= st_selector_data;  

        when st_selector_data =>
          if (data_cnt < unsigned(header(MSG_W * 2 -1 downto MSG_W * 1))) then
            if (i_o_data_fifo_ready = '1' and src_data_ready = '1') then
              o_o_data_fifo_next <= '1';
              src_data_next <= '1';
              data_cnt <= data_cnt + 1;
            end if;
          else
            data_cnt <= to_unsigned(0,MSG_W);
            st_selector <= st_selector_start;  
          end if;

        when st_selector_report =>
          o_bypass <= '1';
          header <= i_i_info_fifo_data;
          src_info_next <= '1';
          data_cnt <= to_unsigned(0,MSG_W);
          st_selector <= st_selector_data;  

        when st_selector_bypass =>
          o_bypass <= '1';
          if (data_cnt < unsigned(header(MSG_W * 2 -1 downto MSG_W * 1))) then
            if (i_o_data_fifo_ready = '1' and i_i_data_fifo_ready_X = '1') then
              o_i_data_fifo_next_X <= '1';
              data_cnt <= data_cnt + 1;
            end if;
          else
            data_cnt <= to_unsigned(0,MSG_W);
            o_i_info_fifo_next_X <= '1';
            st_selector <= st_selector_start;  
          end if;
          
        when others =>
          st_selector <= st_selector_start;
      end case;
    end if;

  end process;

end architecture; --!SECTION 
