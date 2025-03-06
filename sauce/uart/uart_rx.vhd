
--
-- uart rx module
--

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;


----------------------------------------------------------------------------------------
--#ANCHOR - ENTITY
----------------------------------------------------------------------------------------
entity uart_rx is 
  generic (
    constant  MSG_W         : natural := 8;           -- message width
    constant  SMPL_W        : natural := 8;           -- rx line sample width
    constant  START_OFFSET  : natural := 10           -- offset in clks between start and first bit
  );
  port(
    i_clk         : in  std_logic;                -- clk pin (100MHz)
    i_rst_n       : in  std_logic;                -- negative reset pin
    i_rx          : in  std_logic;                -- reciever pin

    i_start_pol   : in  std_logic := '0';         -- polarity of start bit (negative of end bit)
    i_par_en      : in  std_logic := '0';         -- parity bit enable 
    i_par_type    : in  std_logic := '0';         -- parity type (0:ODD;1:EVEN)
    i_char_len    : in  std_logic_vector(1 downto 0) := "11"; -- length of word (5 + x)

    i_clk_div     : in  unsigned(15 downto 0) := x"0300";  -- clock divisor for baudrate (def = 7.3728 MHz => ~9600)

    o_msg         : out std_logic_vector(MSG_W-1 downto 0); -- data output
    o_msg_vld_strb: out std_logic;            -- message out valid strobe signal

    o_busy        : out std_logic;

    o_err_noise_strb   : out std_logic;            -- message noise error
    o_err_frame_strb   : out std_logic;            -- message frame error
    o_err_par_strb     : out std_logic             -- message parity error
  );
end uart_rx;


----------------------------------------------------------------------------------------
--#SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture behavioral of uart_rx is
  ----------------------------------------------------------------------------------------
  --#ANCHOR SIGNAL DEFINITION
  ----------------------------------------------------------------------------------------
  type t_rx_state is(
    s_rx_IDLE,
    s_rx_DELAY,
    s_rx_RECIEVE,
    s_rx_PARITY,
    s_rx_TERMINATE
  );
  signal s_rx : t_rx_state  := s_rx_IDLE;     -- state of reciever

  signal counter_start  : std_logic;    -- start signal for clk to baud division counter
  signal counter_done   : std_logic;    -- division counter finish signal

  signal bit_cnt        : natural range 0 to MSG_W; -- message recieved bit count

  signal rx_sample      : std_logic_vector(SMPL_W-1 downto 0);  -- sample buffer of rx
  signal rx_sample_val  : std_logic;                            -- average value of rx
  signal rx_sample_stb  : std_logic;                            -- stability of rx
begin

  o_busy <= '1' when s_rx /= s_rx_IDLE else '0';
----------------------------------------------------------------------------------------
--#SECTION -  SAMPLER
----------------------------------------------------------------------------------------
p_sampler :process (i_clk)
  variable active : natural range 0 to SMPL_W;
begin
  if rising_edge(i_clk) then
    if i_rst_n = '0' then
      rx_sample <= (others => '0');
    else
      rx_sample_val <= '0';
      rx_sample_stb <= '1';
      rx_sample <= rx_sample(SMPL_W-2 downto 0) & i_rx;
      active := 0;
      for i in rx_sample'range loop
        if rx_sample(i) = '1' then
          active := active + 1;
        end if;
      end loop;
      if active > (SMPL_W / 2) then
        rx_sample_val <= '1';
      end if;
      if 1 >= abs(active-(SMPL_W / 2)) then
        rx_sample_stb <=  '0';
      end if;
    end if ;
  end if;
end process;
--#!SECTION
----------------------------------------------------------------------------------------
--#SECTION - DIVIDER (COUNTER)
----------------------------------------------------------------------------------------
p_clk_div : process (i_clk) is
  variable cnt  : unsigned(15 downto 0);
  variable div10: natural range 0 to 10;
  variable run  : BOOLEAN;
begin
  if rising_edge(i_clk) then
    if (i_rst_n = '0') then
      cnt := (others => '0');
      counter_done <= '0';
      run := false;
      div10 := 0;
    else
      if run then
        if (cnt < i_clk_div) then
          if (div10 = 10) then
            cnt := cnt + 1;
          end if;
        else 
          counter_done <= '1';
          run := false;
        end if;
        if (div10 < 10) then
          div10 := div10 + 1;
        else
          div10 := 1;
        end if;
      else
        counter_done <= '0';
        if counter_start = '1' then
          run := true;
          cnt := (others => '0');
          div10 := 0;
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
  variable msg_buffer : STD_LOGIC_VECTOR(MSG_W-1 downto 0);
  variable delay_cnt  : natural range 1 to START_OFFSET;
  variable stab_cnt   : natural range 0 to MSG_W;
  variable parity_chck: std_logic;
  variable parity_res : boolean;
begin
  if rising_edge(i_clk) then
    o_msg_vld_strb <= '0';
    o_err_noise_strb <= '0';
    o_err_frame_strb <= '0';
    o_err_par_strb <= '0';
    if i_rst_n = '0' then
      o_msg <= (others => '0');
      s_rx <= s_rx_IDLE;
      msg_buffer := (others => '0');
      counter_start <= '0';
      bit_cnt <= 0;
    else
      case s_rx is
        when s_rx_IDLE =>
          delay_cnt := 1;
          stab_cnt  := 0;
          counter_start <= '0';
          bit_cnt <= 0;
          parity_chck := i_par_type;
          if i_rx = i_start_pol then
            s_rx <= s_rx_DELAY;
          end if;
        when s_rx_DELAY =>
          if delay_cnt <START_OFFSET then
            delay_cnt := delay_cnt + 1;
          else
            counter_start <= '1';
            s_rx <= s_rx_RECIEVE;
          end if;
        when s_rx_RECIEVE =>
          parity_res := TRUE;
          if bit_cnt < (5 + to_integer(unsigned(i_char_len))) then
            if counter_done = '1' then
              msg_buffer := rx_sample_val & msg_buffer(MSG_W-1 downto 1);
              parity_chck := (rx_sample_val xor parity_chck);
              bit_cnt <= bit_cnt + 1;
              if rx_sample_stb = '1' then
                stab_cnt := stab_cnt + 1;
              end if ;
            end if;
          elsif bit_cnt < MSG_W then
            msg_buffer := '0' &  msg_buffer(MSG_W-1 downto 1);
            bit_cnt <= bit_cnt + 1;
          else
            o_msg <= msg_buffer; --TODO -  fit different size to lsb
            if i_par_en = '1' then
              s_rx <= s_rx_PARITY;
            else
              s_rx <= s_rx_TERMINATE;
            end if;
          end if;
        when s_rx_PARITY =>
          if counter_done = '1' then
            parity_res := rx_sample_val = parity_chck;
            s_rx <= s_rx_TERMINATE;
          end if;
        when s_rx_TERMINATE =>
          counter_start <= '0';
          if counter_done = '1' then
            if rx_sample_val = i_start_pol then
              o_err_frame_strb <= '1';
            end if;
            if stab_cnt < MSG_W - 1 then
              o_err_noise_strb <= '1';
            end if;
            if not parity_res then
              o_err_par_strb  <= '1';
            end if;
            o_msg_vld_strb <= '1';
            s_rx <= s_rx_IDLE;
          end if;
        when others =>
          s_rx <= s_rx_IDLE;
      end case;
    end if;
  end if;  
end process;

--#!SECTION

end behavioral; --#!SECTION 