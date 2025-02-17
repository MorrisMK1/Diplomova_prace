library ieee;
  use ieee.std_logic_1164.ALL;
  use ieee.numeric_std.all;
  use ieee.std_logic_unsigned.all;

library work;
  use work.my_common.all;

package tb_common is
  function std_logic_vector_to_string(signal_in: std_logic_vector)return string;

  procedure generate_clk ( signal clk : out std_logic; constant period_ns : time);

  procedure signal_strb  ( signal sig : out std_logic; constant period_ns : time; constant ACTIVE : STD_LOGIC := '1');

  procedure sim_fifo_out (signal data_fifo : out STD_LOGIC_VECTOR; signal ready : out out_ready; signal ack : in in_pulse; constant data_to_send : in std_logic_vector);

  procedure sim_fifo_in ( signal data_fifo : in  STD_LOGIC_VECTOR; signal ready : in in_pulse; signal ack : out out_ready; signal received_data : out std_logic_vector; constant CLK_PER : in time);

  procedure uart_tx ( signal tx : out std_logic; signal clk : in std_logic; signal data : in std_logic_vector(7 downto 0); constant baud_period : time);

  procedure uart_rx ( signal rx : in std_logic; variable data : out std_logic_vector(7 downto 0); constant baud_period : time);

  function create_reg0_w (id:std_logic_vector(1 downto 0); target:std_logic_vector(2 downto 0); send_recieve_bytes : std_logic_vector(7 downto 0))return info_bus;

  function create_reg0_w ( id:std_logic_vector(1 downto 0);  target:std_logic_vector(2 downto 0);  send_bytes : std_logic_vector(7 downto 0); recieve_bytes : std_logic_vector(7 downto 0) )return info_bus;

  function create_reg1_w (id:std_logic_vector(1 downto 0); target:std_logic_vector(2 downto 0); rst : std_logic; par_L  : std_logic; par_en : std_logic; report_flg : std_logic; bitrate : std_logic_vector(2 downto 0))return info_bus;
  
  function create_reg2_w (id:std_logic_vector(1 downto 0); target:std_logic_vector(2 downto 0); unex_en : std_logic; timeout_en : std_logic; timeout : std_logic_vector(4 downto 0))return info_bus;

  function create_regX_r (id:std_logic_vector(1 downto 0); target_dev:std_logic_vector(2 downto 0);  target_reg:std_logic_vector(1 downto 0))return info_bus;

end package tb_common;

package body tb_common is

  function std_logic_vector_to_string(signal_in: std_logic_vector) return string is
    variable result : string(1 to signal_in'length); -- Výstupní string stejné délky jako vstupní vektor
  begin
    for i in signal_in'range loop
      if signal_in(i) = '1' then
        result(i+1) := '1';
      else
        result(i+1) := '0';  
      end if;
    end loop;
    return result;
  end function;

procedure generate_clk (
    signal clk : out std_logic;
    constant period_ns : time
) is
begin
    while true loop
        clk <= '1';
        wait for period_ns / 2;
        clk <= '0';
        wait for period_ns / 2;
    end loop;
end procedure generate_clk;

procedure signal_strb (
  signal sig : out std_logic;
  constant period_ns : time;
  constant ACTIVE : std_logic := '1'
) is
begin
  sig <= ACTIVE;
  wait for period_ns;
  sig <= not ACTIVE;
  wait for period_ns;
end procedure signal_strb;

procedure sim_fifo_out (
  signal data_fifo : out STD_LOGIC_VECTOR;
  signal ready : out out_ready;
  signal ack : in in_pulse;
  constant data_to_send : in std_logic_vector
  ) is
begin
  data_fifo <= data_to_send;
  ready <= '1';
  wait until ack = '1';
  ready <= '0';
  --wait until ack = '0';

end procedure;

procedure sim_fifo_in ( 
  signal data_fifo : in  STD_LOGIC_VECTOR; 
  signal ready : in  in_pulse; 
  signal ack   : out out_ready;
  signal received_data : out std_logic_vector; 
  constant CLK_PER : in time
) is
begin
    ack <= '1';
    wait until ready = '1';

    received_data <= data_fifo;
    ack <= '0';
    wait until ready = '0';

end procedure;

function create_reg0_w (
  id:std_logic_vector(1 downto 0); 
  target:std_logic_vector(2 downto 0); 
  send_recieve_bytes : std_logic_vector(7 downto 0)
  )return info_bus is
begin
  return id & "100" & target & send_recieve_bytes & send_recieve_bytes;
end function;

function create_reg0_w (
  id:std_logic_vector(1 downto 0); 
  target:std_logic_vector(2 downto 0); 
  send_bytes : std_logic_vector(7 downto 0);
  recieve_bytes : std_logic_vector(7 downto 0)
  )return info_bus is
    variable resp :std_logic;
begin
  resp := '1' when (unsigned(recieve_bytes) > 0) else '0';

  return id & resp & "00" & target & send_bytes & recieve_bytes;
end function;

function create_reg1_w (
  id:std_logic_vector(1 downto 0); 
  target:std_logic_vector(2 downto 0); 
  rst : std_logic; 
  par_L  : std_logic; 
  par_en : std_logic; 
  report_flg : std_logic; 
  bitrate : std_logic_vector(2 downto 0)
  )return info_bus is
  variable d_out : info_bus;
begin
  d_out := id & "001" & target & rst & par_L & par_en & "0" & report_flg & bitrate & x"00";
  return d_out;
end function;

function create_reg2_w (
  id:std_logic_vector(1 downto 0); 
  target:std_logic_vector(2 downto 0); 
  unex_en : std_logic; 
  timeout_en : std_logic; 
  timeout : std_logic_vector(4 downto 0)
  )return info_bus is
begin
  return id & "010" & target & "0" & unex_en & timeout_en & timeout & x"00";
end function;

function  create_regX_r (
  id:std_logic_vector(1 downto 0); 
  target_dev:std_logic_vector(2 downto 0);  
  target_reg:std_logic_vector(1 downto 0)
  )return info_bus is
begin
  return id & "1" & target_reg & target_dev & x"0000";
end function;

procedure uart_tx (
    signal tx        : out std_logic; -- UART transmit line
    signal clk       : in std_logic;  -- Clock signal
    signal data    : in std_logic_vector(7 downto 0); -- Data to transmit
    constant baud_period : time       -- Bit period for the desired baud rate
) is
begin
    -- Ensure the line is idle before transmission
    tx <= '1';
    wait until rising_edge(clk);

    -- Transmit start bit
    tx <= '0';
    wait for baud_period;

    -- Transmit each bit (LSB first)
    for i in data'range loop
        tx <= data(((data'length)-1)-i);
        wait for baud_period;
    end loop;

    -- Transmit stop bit
    tx <= '1';
    wait for baud_period;

    -- End of transmission
    tx <= '1'; -- Return to idle state
end procedure;

procedure uart_rx (
    signal rx        : in std_logic;  -- UART receive line
    variable data    : out std_logic_vector(7 downto 0); -- Received data
    constant baud_period : time       -- Bit period for the desired baud rate
) is
    constant bit_sample : time := baud_period / 2; -- Sampling at middle of the bit
begin
    -- Wait for the start bit (falling edge)
    wait until falling_edge(rx);

    -- Wait to sample at the middle of the start bit
    wait for bit_sample;

    -- Receive each bit (LSB first)
    for i in data'range loop
        wait for baud_period;
        data(i) := rx;
    end loop;

    -- Wait for the stop bit
    wait for baud_period;

    -- Optionally check the stop bit (rx should be '1')
    assert rx = '1' report "Stop bit error" severity warning;
end procedure;

end package body;