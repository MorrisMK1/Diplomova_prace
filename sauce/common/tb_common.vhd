library ieee;
use ieee.std_logic_1164.ALL;

library work;
use work.my_common.all;

package tb_common is
  function std_logic_vector_to_string(signal_in: std_logic_vector)return string;

  procedure generate_clk ( signal clk : out std_logic; constant period_ns : time);

  procedure signal_strb  ( signal sig : out std_logic; constant period_ns : time; constant ACTIVE : STD_LOGIC := '1');

  procedure sim_fifo_out (signal data_fifo : out STD_LOGIC_VECTOR; signal ready : out out_ready; constant data_to_send : in std_logic_vector);

  procedure sim_fifo_in ( signal data_fifo : in  STD_LOGIC_VECTOR; signal ready : in  in_pulse; signal received_data : out std_logic_vector; constant CLK_PER : in time);



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
  constant data_to_send : in std_logic_vector
  ) is
begin
  data_fifo <= data_to_send;
  ready <= '1';  

end procedure;

procedure sim_fifo_in ( 
  signal data_fifo : in  STD_LOGIC_VECTOR; 
  signal ready : in  in_pulse; 
  signal received_data : out std_logic_vector; 
  constant CLK_PER : in time
) is
begin

    wait until ready = '1';

    received_data <= data_fifo;

end procedure;

end package body;