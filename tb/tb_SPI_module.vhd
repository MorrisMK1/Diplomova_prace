
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_common.all;
use work.my_common.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_SPI_module is
  generic (
    runner_cfg : string
  );
end;

architecture bench of tb_SPI_module is
  -- Clock period
  constant clk_period : time := 10 ns;
  -- Generics
  constant SMPL_W : natural := 8;
  constant START_OFFSET : natural := 10;
  constant MY_ID : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0) := "000";
  -- Ports 
  signal clk_100MHz : std_logic;
  signal i_rst_n : std_logic;
  signal i_en : std_logic;
  signal i_i_info_write : std_logic;
  signal i_i_info_data : info_bus;
  signal i_o_info_full : std_logic;
  signal i_i_data_write : std_logic;
  signal i_i_data_data : data_bus;
  signal i_o_data_full : std_logic;
  signal o_i_info_next : std_logic;
  signal o_o_info_data : info_bus;
  signal o_o_info_empty : std_logic;
  signal o_i_data_next : std_logic;
  signal o_o_data_data : data_bus;
  signal o_o_data_empty : std_logic;
  signal MISO : std_logic;
  signal MOSI : std_logic;
  signal SCLK : std_logic;
  signal o_CS : std_logic_vector(MSG_W - 1 downto 0);


  signal slv_reg_i, slv_reg_o :std_logic_vector(MSG_W-1 downto 0);
  signal slv_data : std_logic_array(3 downto 0)(MSG_W-1 downto 0);

----------------------------------------------------------------------------------------
--ANCHOR - SPI SLAVE DEF
----------------------------------------------------------------------------------------
procedure SPI_Slave(
  signal clk      : in std_logic;           
  signal sclk     : in std_logic;           
  signal mosi     : in std_logic;           
  signal miso     : out std_logic;          
  signal cs       : in std_logic;           
  signal rx_buffer: out std_logic_vector(7 downto 0); 
  signal tx_buffer: in std_logic_vector(7 downto 0)   
) is
  variable bit_count  : integer := 0;
  variable rx_temp    : std_logic_vector(7 downto 0) := (others => '0');
  variable tx_temp    : std_logic_vector(7 downto 0) := (others => '0');
  variable miso_reg     : std_logic := '0';
begin
  if cs = '0' then  -- Aktivní čipová selekce
      if rising_edge(sclk) then
          -- Příjem dat přes MOSI
          rx_temp(7 - bit_count) := mosi;
          bit_count := bit_count + 1;
          
          if bit_count = 8 then
              bit_count := 0;
              rx_buffer <= rx_temp;  -- Přijatá data uložena do výstupního bufferu
              tx_temp := tx_buffer;  -- Načtení dat k odeslání do dočasného registru
          end if;
      elsif falling_edge(sclk) then
          -- Odesílání dat přes MISO
          miso_reg := tx_temp(7 - bit_count);
      end if;
  else
      bit_count := 0;  -- Resetování při neaktivním čipovém výběru
      miso_reg := 'Z'; -- High impedance, když je slave neaktivní
  end if;
  miso <= miso_reg;  -- Nastavení výstupního signálu MISO
end procedure;

procedure SPI_SLAVE_byte (
  signal MISO: out std_logic;
  signal MOSI: in std_logic;
  signal SCLK: in std_logic;
  signal CS: in std_logic;
  constant data_i: in std_logic_vector;
  signal data_o: out std_logic_vector
) is
begin
  data_o <= x"00";
  for i in MSG_W * 2 - 1 downto 0 loop
    wait until SCLK'event;
    if (SCLK = '1') then
      data_o(i/2) <= MOSI;
    else
      MISO <= data_i(i/2);
    end if;

  end loop;
end procedure;

begin

----------------------------------------------------------------------------------------
--ANCHOR - DUT
----------------------------------------------------------------------------------------
SPI_module_DUT : entity work.SPI_module
  generic map (
    ID => MY_ID
  )
  port map (
    i_clk => clk_100MHz,
    i_rst_n => i_rst_n,
    i_en => i_en,
    i_i_info_write => i_i_info_write,
    i_i_info_data => i_i_info_data,
    i_o_info_full => i_o_info_full,
    i_i_data_write => i_i_data_write,
    i_i_data_data => i_i_data_data,
    i_o_data_full => i_o_data_full,
    o_i_info_next => o_i_info_next,
    o_o_info_data => o_o_info_data,
    o_o_info_empty => o_o_info_empty,
    o_i_data_next => o_i_data_next,
    o_o_data_data => o_o_data_data,
    o_o_data_empty => o_o_data_empty,
    MISO => MISO,
    MOSI => MOSI,
    SCLK => SCLK,
    o_CS => o_CS
  );


----------------------------------------------------------------------------------------
--ANCHOR - SLAVE
----------------------------------------------------------------------------------------
p_slave : process
  variable slv_state, slv_reg_pos : natural := 0;
  variable slv_tg                 : std_logic_vector(3 downto 0);
begin
  if TRUE then
    wait for clk_period;
    if i_rst_n = '0' then
      slv_state := 0;
      slv_data(3) <= x"DE";
      slv_data(2) <= x"AD";
      slv_data(1) <= x"BE";
      slv_data(0) <= x"EF";
      slv_reg_i <= x"00";
    elsif (o_CS(1) = '0') then
      case slv_state is
      
        when 0 =>
          for i in MSG_W * 2 - 1 downto 0 loop
            wait until SCLK'event;
            if (SCLK = '1') then
              slv_reg_o(i/2) <= MOSI;
            else
              MISO <= slv_reg_i(i/2);
            end if;
            
          end loop;
          wait for 0 fs;
          slv_tg := slv_reg_o(3 downto 0);
          if (slv_reg_o(MSG_W-1 downto 4) = "1001") then  -- reading
            slv_state := 1;
          elsif (slv_reg_o(MSG_W-1 downto 4) = "0110") then  -- writing
            slv_state := 2;
          end if;

        when 1 =>
          for i in 3 downto 0 loop
            if (slv_tg(i) = '1') then
              for x in MSG_W * 2 - 1 downto 0 loop
                wait until SCLK'event;
                if (SCLK = '1') then
                  slv_reg_o(x/2) <= MOSI;
                else
                  MISO <= slv_data(i)(x/2);
                end if;
                
              end loop;
            end if;
          end loop;
          slv_state := 0;

        when 2 =>
          for i in 3 downto 0 loop
            if (slv_tg(i) = '1') then
              for x in MSG_W * 2 - 1 downto 0 loop
                wait until SCLK'event;
                if (SCLK = '1') then
                  slv_reg_o(x/2) <= MOSI;
                else
                  MISO <= slv_reg_i(x/2);
                end if;
                
              end loop;
              wait for 0 fs;
              slv_data(i) <= slv_reg_o;
            end if;
          end loop;
          slv_state := 0;
        
        when others =>
          slv_state := 0;

      end case;
    end if;
  end if;
end process;


----------------------------------------------------------------------------------------
--ANCHOR - TESTS
----------------------------------------------------------------------------------------
  p_main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("BASIC_COMM") then
        info("Running basic commtest");
        wait for 0 fs;
        o_i_data_next   <= '0';
        o_i_info_next   <= '0';
        i_i_data_write  <= '0';
        i_i_info_write  <= '0';
        i_i_data_data   <= (others => '0');
        i_i_info_data   <= (others => '0');
        i_rst_n <= '0';
        i_en <= '1';
        wait for clk_period * 2;
        i_rst_n <= '1';
        i_i_data_data <= x"9F";
        wait for clk_period;
        i_i_data_write <= '1';
        wait for clk_period;
        i_i_data_data <= x"99";
        wait for clk_period;
        i_i_data_write <= '0';
        i_i_info_write <= '1';
        i_i_info_data  <= "000100000000000100000000";
        wait for clk_period;
        i_i_info_data  <= create_reg0_w("01",'0',"000",x"01",x"05");
        wait for clk_period;
        i_i_info_write <= '0';
        wait until (o_o_info_empty = '0');
        wait for clk_period * 100000;
        o_i_data_next <= '1';
        check(0 = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & "0" & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        wait for clk_period;
        check(unsigned(slv_data(3)) = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & to_string(to_integer(unsigned(slv_data(3)))) & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        wait for clk_period;        
        check(unsigned(slv_data(2)) = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & to_string(to_integer(unsigned(slv_data(2)))) & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        wait for clk_period;
        check(unsigned(slv_data(1)) = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & to_string(to_integer(unsigned(slv_data(1)))) & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        wait for clk_period;
        check(unsigned(slv_data(0)) = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & to_string(to_integer(unsigned(slv_data(0)))) & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        o_i_info_next <= '1';
        wait for clk_period;
        o_i_info_next <= '0';
        o_i_data_next <= '0';
        i_i_info_write<= '1';
        i_i_info_data  <= create_reg0_w("10",'0',"000",x"01",x"03");
        wait for clk_period;
        i_i_info_write <= '0';
        wait until (o_o_info_empty = '0');
        wait for clk_period * 10000;
        o_i_data_next <= '1';
        check(0 = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & "0" & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        wait for clk_period;
        check(unsigned(slv_data(3)) = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & to_string(to_integer(unsigned(slv_data(3)))) & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        wait for clk_period;  
        check(unsigned(slv_data(0)) = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & to_string(to_integer(unsigned(slv_data(0)))) & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        o_i_info_next <= '1';
        wait for clk_period;
        o_i_info_next <= '0';
        o_i_data_next <= '0';     

        i_i_data_write <= '1';
        i_i_data_data <= "01101100";
        wait for clk_period;
        i_i_data_data <= x"DE";
        wait for clk_period;
        i_i_data_data <= x"AF";
        wait for clk_period;
        i_i_data_data <= x"9F";
        wait for clk_period;
        i_i_data_write <= '0';
        i_i_info_write <= '1'; 
        i_i_info_data  <= create_reg0_w("11",'0',"000",x"03",x"00");
        wait for clk_period;
        i_i_info_data  <= create_reg0_w("00",'0',"000",x"01",x"05");
        wait for clk_period;
        i_i_info_write <= '0';
        wait until (o_o_info_empty = '0');
        wait for clk_period * 10000;
        o_i_data_next <= '1';
        check(0 = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & "0" & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        wait for clk_period;
        check(unsigned(slv_data(3)) = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & to_string(to_integer(unsigned(slv_data(3)))) & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        wait for clk_period;        
        check(unsigned(slv_data(2)) = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & to_string(to_integer(unsigned(slv_data(2)))) & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        wait for clk_period;
        check(unsigned(slv_data(1)) = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & to_string(to_integer(unsigned(slv_data(1)))) & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        wait for clk_period;
        check(unsigned(slv_data(0)) = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & to_string(to_integer(unsigned(slv_data(0)))) & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
        o_i_info_next <= '1';
        wait for clk_period;
        o_i_info_next <= '0';
        o_i_data_next <= '0';


        test_runner_cleanup(runner);
        
      elsif run("test_0") then
        info("Hello world test_0");
        wait for 100 * clk_period;
        test_runner_cleanup(runner);
      end if;
    end loop;
  end process p_main;

----------------------------------------------------------------------------------------
--ANCHOR - CLK
----------------------------------------------------------------------------------------
p_clk :process
begin
  generate_clk(clk_100MHz,CLK_PERIOD);
end process;

end;