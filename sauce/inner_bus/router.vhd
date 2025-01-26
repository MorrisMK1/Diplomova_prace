library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.numeric_std_unsigned.all;

library work;
  use work.my_common.all;

----------------------------------------------------------------------------------------
-- #ANCHOR - ENTITY
----------------------------------------------------------------------------------------

entity router is
  port (
    
    i_clk                   : in    std_logic;
    i_rst_n                 : in    std_logic;

    i_bypass                : in    std_logic;
    o_err_rep               : out   std_logic;

    i_i_data_fifo_data      : in    data_bus;
    i_i_data_fifo_ready     : in    out_ready;
    o_i_data_fifo_next      : out   in_pulse;

    o_o_data_fifo_data      : out   data_bus;
    i_o_data_fifo_ready_0   : in    out_ready;
    o_o_data_fifo_next_0    : out   in_pulse;
    i_o_data_fifo_ready_1   : in    out_ready;
    o_o_data_fifo_next_1    : out   in_pulse;
    i_o_data_fifo_ready_2   : in    out_ready;
    o_o_data_fifo_next_2    : out   in_pulse;
    i_o_data_fifo_ready_3   : in    out_ready;
    o_o_data_fifo_next_3    : out   in_pulse;
    i_o_data_fifo_ready_4   : in    out_ready;
    o_o_data_fifo_next_4    : out   in_pulse;
    i_o_data_fifo_ready_5   : in    out_ready;
    o_o_data_fifo_next_5    : out   in_pulse;
    i_o_data_fifo_ready_6   : in    out_ready;
    o_o_data_fifo_next_6    : out   in_pulse;
    i_o_data_fifo_ready_7   : in    out_ready;
    o_o_data_fifo_next_7    : out   in_pulse;
    i_o_data_fifo_ready_X   : in    out_ready;
    o_o_data_fifo_next_X    : out   in_pulse;

    i_i_info_fifo_data      : in    info_bus;
    i_i_info_fifo_ready     : in    out_ready;
    o_i_info_fifo_next      : out   in_pulse;

    o_o_info_fifo_data      : out   info_bus;
    i_o_info_fifo_ready_0   : in    out_ready;
    o_o_info_fifo_next_0    : out   in_pulse;
    i_o_info_fifo_ready_1   : in    out_ready;
    o_o_info_fifo_next_1    : out   in_pulse;
    i_o_info_fifo_ready_2   : in    out_ready;
    o_o_info_fifo_next_2    : out   in_pulse;
    i_o_info_fifo_ready_3   : in    out_ready;
    o_o_info_fifo_next_3    : out   in_pulse;
    i_o_info_fifo_ready_4   : in    out_ready;
    o_o_info_fifo_next_4    : out   in_pulse;
    i_o_info_fifo_ready_5   : in    out_ready;
    o_o_info_fifo_next_5    : out   in_pulse;
    i_o_info_fifo_ready_6   : in    out_ready;
    o_o_info_fifo_next_6    : out   in_pulse;
    i_o_info_fifo_ready_7   : in    out_ready;
    o_o_info_fifo_next_7    : out   in_pulse;
    i_o_info_fifo_ready_X   : in    out_ready;
    o_o_info_fifo_next_X    : out   in_pulse

  );
end entity router;

----------------------------------------------------------------------------------------
--SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture behavioral of router is

  type fsm_router is(
    st_router_idle,
    st_router_target,
    st_router_data,
    st_router_head,
    st_router_report,
    st_router_bypass
  );

  signal st_router  : fsm_router;
  signal data_cnt   : unsigned(MSG_W-1 downto 0);
  signal bypass     : std_logic;
  signal next_data  : std_logic;
  signal next_info  : std_logic;
  signal header     : info_bus;
  
  signal target           : STD_ULOGIC_VECTOR(2 downto 0);
  signal tg_info_push     : std_logic;
  signal tg_info_ready    : std_logic;
  signal tg_data_push     : std_logic;
  signal tg_data_ready    : std_logic;

  begin
----------------------------------------------------------------------------------------
-- #ANCHOR - PIN ASSIGMENT
----------------------------------------------------------------------------------------

  o_o_info_fifo_next_X <= i_i_info_fifo_ready;
  o_i_info_fifo_next <= i_o_info_fifo_ready_X when bypass else next_info;

  o_o_data_fifo_next_X <= i_i_data_fifo_ready;
  o_i_data_fifo_next <= i_o_data_fifo_ready_X when bypass else next_data;

  o_o_data_fifo_data <= i_i_data_fifo_data;
  o_o_info_fifo_data <= i_i_info_fifo_data;

  tg_info_ready <=i_o_info_fifo_ready_0 when (target = 0) else
                  i_o_info_fifo_ready_1 when (target = 1) else
                  i_o_info_fifo_ready_2 when (target = 2) else
                  i_o_info_fifo_ready_3 when (target = 3) else
                  i_o_info_fifo_ready_4 when (target = 4) else
                  i_o_info_fifo_ready_5 when (target = 5) else
                  i_o_info_fifo_ready_6 when (target = 6) else
                  i_o_info_fifo_ready_7;

  tg_data_ready <=i_o_data_fifo_ready_0 when (target = 0) else
                  i_o_data_fifo_ready_1 when (target = 1) else
                  i_o_data_fifo_ready_2 when (target = 2) else
                  i_o_data_fifo_ready_3 when (target = 3) else
                  i_o_data_fifo_ready_4 when (target = 4) else
                  i_o_data_fifo_ready_5 when (target = 5) else
                  i_o_data_fifo_ready_6 when (target = 6) else
                  i_o_data_fifo_ready_7;

  o_o_info_fifo_next_0 <= tg_info_push when (target = 0) else '0';
  o_o_info_fifo_next_1 <= tg_info_push when (target = 1) else '0';
  o_o_info_fifo_next_2 <= tg_info_push when (target = 2) else '0';
  o_o_info_fifo_next_3 <= tg_info_push when (target = 3) else '0';
  o_o_info_fifo_next_4 <= tg_info_push when (target = 4) else '0';
  o_o_info_fifo_next_5 <= tg_info_push when (target = 5) else '0';
  o_o_info_fifo_next_6 <= tg_info_push when (target = 6) else '0';
  o_o_info_fifo_next_7 <= tg_info_push when (target = 7) else '0';

  o_o_data_fifo_next_0 <= tg_data_push when (target = 0) else '0';
  o_o_data_fifo_next_1 <= tg_data_push when (target = 1) else '0';
  o_o_data_fifo_next_2 <= tg_data_push when (target = 2) else '0';
  o_o_data_fifo_next_3 <= tg_data_push when (target = 3) else '0';
  o_o_data_fifo_next_4 <= tg_data_push when (target = 4) else '0';
  o_o_data_fifo_next_5 <= tg_data_push when (target = 5) else '0';
  o_o_data_fifo_next_6 <= tg_data_push when (target = 6) else '0';
  o_o_data_fifo_next_7 <= tg_data_push when (target = 7) else '0';

----------------------------------------------------------------------------------------
-- #ANCHOR - MAIN PROCESS
----------------------------------------------------------------------------------------
  p_main  : process (i_clk) is

  begin
    if (i_rst_n = '0') then
      st_router <= st_router_idle;
      data_cnt <= to_unsigned(0,MSG_W);
      bypass <= '0';
      next_data <= '0';
      next_info <= '0';
      tg_info_push  <= '0';
      tg_data_push  <= '0';
      o_err_rep <= '0';
    elsif (rising_edge(i_clk)) then
      tg_info_push  <= '0';
      tg_data_push  <= '0';
      next_data <= '0';
      next_info <= '0';
      bypass <= '0';
      case(st_router) is
        when st_router_idle =>
          o_err_rep <= '0';
          if (i_i_info_fifo_ready = '1') then
            next_info <= '1';
            st_router <= st_router_target;
          end if;
        when st_router_target =>
          header <= i_i_info_fifo_data;
          target <= i_i_info_fifo_data(MSG_W * 2 + 2 downto MSG_W * 2);
          if (i_i_info_fifo_data(MSG_W * 2 + 5) = '0' and i_i_info_fifo_data(MSG_W * 1 - 1 downto 0) /= 0) then
            st_router <= st_router_report;
          else
            st_router <= st_router_data;
            data_cnt <= to_unsigned(0,MSG_W);
            next_data <= '1';
          end if;
        when st_router_data =>
          if (data_cnt < unsigned(header(MSG_W * 2 -1 downto MSG_W * 1))) then
            if (tg_data_ready = '1' and i_i_data_fifo_ready = '1')then
              next_data <= '1';
              tg_data_push <= '1';
              data_cnt <= data_cnt + 1;
            end if;
          else
            st_router <= st_router_head;
          end if;
        when st_router_head =>
          if (tg_info_ready = '1') then
            tg_info_push <= '1';
            st_router <= st_router_idle;
          end if;
        when st_router_report =>
          bypass <= '1';
          o_err_rep <= '1';
          if (i_bypass = '1') then
            st_router <= st_router_bypass;
          end if;
        when st_router_bypass =>
          bypass <= '1';
          if (i_bypass = '0') then
            st_router <= st_router_idle;
          end if;
        when others =>
          st_router <= st_router_idle;
      end case;

    end if;
  end process;

end architecture; --!SECTION