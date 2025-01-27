
--
-- uart tx module
--

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;


----------------------------------------------------------------------------------------
--#ANCHOR - ENTITY
----------------------------------------------------------------------------------------
entity uart_tx is 
  generic (
    constant  MSG_W         : natural := 8;           -- message width
    constant  SMPL_W        : natural := 8            -- rx line sample width
  );
  port(
    i_clk         : in  std_logic;            -- clk pin
    i_rst_n       : in  std_logic;            -- negative reset pin
    i_msg         : in  std_logic_vector(MSG_W-1 downto 0); -- data input
    i_msg_vld     : in std_logic;            -- message in valid strobe signal

    i_start_pol   : in  std_logic := '0';     -- polarity of start bit (negative of end bit)
    i_par_en      : in  std_logic := '0';     -- parity bit enable 
    i_par_type    : in  std_logic := '0';     -- parity type (0:ODD;1:EVEN)

    i_clk_div     : in  unsigned(15 downto 0) := x"0300";  -- clock divisor for baudrate (def = 7.3728 MHz => ~9600)

    o_tx          : out std_logic;            -- send pin
    o_busy        : out std_logic

  );
end uart_tx;


----------------------------------------------------------------------------------------
--#SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture behavioral of uart_tx is
  ----------------------------------------------------------------------------------------
  --#ANCHOR SIGNAL DEFINITION
  ----------------------------------------------------------------------------------------
  type t_tx_state is(
    s_tx_IDLE,
    s_tx_START,
    s_tx_DATA,
    s_tx_PARITY,
    s_tx_TERMINATE,
    s_tx_TAIL
  );
  signal s_tx : t_tx_state  := s_tx_IDLE;     -- state of reciever

  signal counter_start  : std_logic;    -- start signal for clk to baud division counter
  signal counter_done   : std_logic;    -- division counter finish signal
  
  signal bit_cnt        : natural range 0 to MSG_W; -- message recieved bit count
begin

  o_busy <= '0' when s_tx = s_tx_IDLE else '1';

----------------------------------------------------------------------------------------
--#SECTION - DIVIDER (COUNTER)
----------------------------------------------------------------------------------------
p_clk_div : process (i_clk) is
    variable cnt  : unsigned(15 downto 0);
    variable run  : BOOLEAN;
  begin
    if rising_edge(i_clk) then
      if (i_rst_n = '0') then
        cnt := (others => '0');
        counter_done <= '0';
        run := false;
      else
        if run then
          if cnt < i_clk_div then
            cnt := cnt + 1;
          else
            counter_done <= '1';
            run := false;
          end if;
        else
          counter_done <= '0';
          if counter_start = '1' then
            run := true;
            cnt := (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process p_clk_div;
  --#!SECTION

  
----------------------------------------------------------------------------------------
--#SECTION - MAIN PROCESS
----------------------------------------------------------------------------------------
p_main  : process (i_clk)
  variable parity_chck: std_logic;
  variable msg_buff   : STD_LOGIC_VECTOR(MSG_W-1 downto 0);
begin
  if rising_edge(i_clk) then
    if (i_rst_n = '0') then
      o_tx <= not i_start_pol;
      bit_cnt <= 0;
      s_tx <= s_tx_IDLE;
    else
      case s_tx is
        when s_tx_IDLE =>
          o_tx <= not i_start_pol;
          counter_start <= '0';
          parity_chck := i_par_type;
          if i_msg_vld  = '1' then
            msg_buff := i_msg;
            s_tx <= s_tx_START;
          end if;
        when s_tx_START =>
          o_tx<= i_start_pol;
          counter_start<='1';
          bit_cnt <= 0;
          s_tx <= s_tx_DATA;
        when s_tx_DATA =>
          if counter_done = '1' then
            if bit_cnt < MSG_W then
              o_tx <= msg_buff(bit_cnt);
              parity_chck := (parity_chck xor msg_buff(bit_cnt));
              bit_cnt <= bit_cnt + 1;
            else
              if i_par_en = '1' then
                s_tx <= s_tx_PARITY;
              else
                s_tx <= s_tx_TERMINATE;
              end if;
            end if;
          end if;
        when s_tx_PARITY =>
        o_tx<=parity_chck;
        if counter_done = '1' then
          s_tx<=s_tx_TERMINATE;
        end if;
        when s_tx_TERMINATE =>
        o_tx<= not i_start_pol;
        if counter_done = '1' then
            s_tx <= s_tx_TAIL;
        end if;
        when s_tx_TAIL =>
          counter_start <= '0';
          if counter_done = '1' then
              s_tx <= s_tx_IDLE;
          end if;
            
        when others =>
          s_tx <= s_tx_IDLE;
      end case;
    end if;
  end if;
end process p_main;--#!SECTION
end architecture behavioral; --#!SECTION