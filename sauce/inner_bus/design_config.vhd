library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_unsigned.all;

library work;
  use work.my_common.all;

----------------------------------------------------------------------------------------
-- #ANCHOR - ENTITY
----------------------------------------------------------------------------------------
entity design_config is
  port (
    clk   : in std_logic;
    rst_n : in std_logic;

    i_i_data_fifo_data      : in  data_bus;
    i_i_data_fifo_write     : in  out_ready;
    o_i_data_fifo_blck      : out in_pulse;

    o_o_data_fifo_data      : out data_bus;
    i_o_data_fifo_read      : in  out_ready;
    o_o_data_fifo_blck      : out in_pulse;
  
    i_i_info_fifo_data      : in  info_bus;
    i_i_info_fifo_write     : in  out_ready;
    o_i_info_fifo_blck      : out in_pulse;

    o_o_info_fifo_data      : out info_bus;
    i_o_info_fifo_read      : in  out_ready;
    o_o_info_fifo_blck      : out in_pulse;
    
    o_settings_main         : out   std_logic_array (1 to 2) (MSG_W-1 downto 0);
    o_enable_interfaces     : out   std_logic_vector (MSG_W-1 downto 0)
  
  );
end entity;

----------------------------------------------------------------------------------------
-- #SECTION - Design
----------------------------------------------------------------------------------------

architecture rtl of design_config is
  
  signal r_registers    : std_logic_array (1 to 3) (MSG_W-1 downto 0);

  
  attribute MARK_DEBUG : string;

  attribute MARK_DEBUG of r_registers : signal is "TRUE";

begin
  
  -- data are to be ignored 
  o_i_data_fifo_blck <= '0';   -- just sink any incoming data (they are ignored)
  o_o_data_fifo_blck <= '0';   -- output data just zeros in case of fault
  o_o_data_fifo_data <= (others => '0') ;
  o_enable_interfaces <= r_registers(3);
  o_settings_main <= r_registers (1 to 2);

  
----------------------------------------------------------------------------------------
--#ANCHOR - Config manager
----------------------------------------------------------------------------------------
p_cfg_manager : process (clk)
variable register_selection : natural range 0 to 3;
begin
register_selection := to_integer(unsigned(inf_reg(i_i_info_fifo_data)));
if rising_edge(clk) then 
  if (rst_n = '0') then
    for i in 1 to 3 loop
      r_registers(i) <= (others => '0');
    end loop;
    o_o_info_fifo_data <= (others => '0');
    o_o_info_fifo_blck <= '1';
    o_i_info_fifo_blck <= '0';
  elsif (o_o_info_fifo_blck = '1') then
    if i_i_info_fifo_write = '1' then
      if inf_ret(i_i_info_fifo_data) = '1' then -- this is reading do not write
        o_o_info_fifo_data <= inf_id(i_i_info_fifo_data) & "0" & inf_reg(i_i_info_fifo_data) & "000" & r_registers(register_selection) & x"00";
        o_o_info_fifo_blck <= '0';
        o_i_info_fifo_blck <= '1';
      else
        r_registers(register_selection) <= inf_size(i_i_info_fifo_data);
      end if;
    end if;
  else
    if (i_o_info_fifo_read = '1') then
      o_o_info_fifo_blck <= '1';
      o_i_info_fifo_blck <= '0';
    end if;
  end if;
end if;
end process p_cfg_manager;

end architecture;--!SECTION