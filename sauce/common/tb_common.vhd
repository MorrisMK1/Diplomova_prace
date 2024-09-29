library ieee;
use ieee.std_logic_1164.ALL;

package tb_common is
  function std_logic_vector_to_string(signal_in: std_logic_vector)return string;

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
end package body;