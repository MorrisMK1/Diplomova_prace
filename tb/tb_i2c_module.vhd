
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.my_common.all;
use work.tb_common.all;


library vunit_lib;
context vunit_lib.vunit_context;

entity tb_i2c_module is
  generic (
    runner_cfg : string
  );
end;

architecture bench of tb_i2c_module is
  -- Clock period
  constant clk_period : time := 10 ns;
  -- Generics
  constant ID : std_logic_vector(2 downto 0) := (others => '0');
  constant GEN_TYPE : string := "DEFAULT";
  -- Ports
  signal i_clk : std_logic := '0';
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
  signal scl : std_logic;
  signal sda : std_logic;
  signal i_interrupt : std_logic;
  signal o_interrupt : std_logic;

  
  constant I2C_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0000010";
  signal read_req, slave_write         : std_logic;
  signal slave_reg, slave_reg_i, slave_reg_o        : std_logic_vector(7 downto 0) := "00000000";

begin

  i2c_module_inst : entity work.i2c_module
  generic map (
    ID => ID,
    GEN_TYPE => GEN_TYPE
  )
  port map (
    i_clk => i_clk,
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
    scl => scl,
    sda => sda,
    i_interrupt => i_interrupt,
    o_interrupt => o_interrupt
  );
  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_wr") then
        info("Starting send test");
        wait for 0 fs;
        i_rst_n <= '0';
        i_en <= '1';
        i_interrupt <= '0';
        wait for clk_period * 1;
        i_rst_n <= '1';
        i_i_data_write <= '1';
        i_i_data_data <= I2C_SLAVE_ADDR & "0";
        wait for clk_period;
        i_i_data_data <= "10011001";
        wait for clk_period;
        for i in 0 to 35 loop
          i_i_data_data <= std_logic_vector(to_unsigned(i,MSG_W));
          wait for clk_period;
        end loop;
        i_i_data_write <= '0';
        i_i_info_write <= '1';
        i_i_info_data <= create_reg0_w("00","000",x"25",x"00");
        wait for clk_period;
        i_i_info_write <= '0';

        wait until scl'stable(1 ms);
        
        test_runner_cleanup(runner);
        
      elsif run("test_rd") then
        info("Starting read test");

        wait for 0 fs;
        i_rst_n <= '0';
        i_en <= '1';
        i_interrupt <= '0';
        wait for clk_period * 1;
        i_rst_n <= '1';
        i_i_data_write <= '1';
        i_i_data_data <= I2C_SLAVE_ADDR & "1";
        wait for clk_period;
        i_i_data_write <= '0';
        i_i_info_write <= '1';
        i_i_info_data <= create_reg0_w("01","000",x"01",x"25");
        wait for clk_period;
        i_i_info_write <= '0';

        wait until scl'stable(1 ms);

        test_runner_cleanup(runner);
      elsif run("test_comm") then
        info("Starting read test");
  
        wait for 0 fs;
        i_rst_n <= '0';
        i_en <= '1';
        i_interrupt <= '0';
        o_i_data_next <= '0';
        o_i_info_next <= '0';
        wait for clk_period * 1;
        i_rst_n <= '1';
        i_i_data_write <= '1';
        i_i_data_data <= I2C_SLAVE_ADDR & "0";
        wait for clk_period;        
        i_i_data_data <= x"05";
        wait for clk_period;
        i_i_data_data <= I2C_SLAVE_ADDR & "1";
        wait for clk_period;     
        i_i_data_data <= I2C_SLAVE_ADDR & "0";
        wait for clk_period;        
        i_i_data_data <= x"19";
        wait for clk_period;
        i_i_data_data <= I2C_SLAVE_ADDR & "1";
        wait for clk_period;        
        i_i_data_write <= '0';
        i_i_info_write <= '1';
        i_i_info_data <= create_reg0_w("00","000",x"02",x"00");
        wait for clk_period;
        i_i_info_data <= create_reg0_w("01","000",x"01",x"0A");
        wait for clk_period;
        i_i_info_data <= create_reg0_w("10","000",x"02",x"00");
        wait for clk_period;
        i_i_info_data <= create_reg0_w("11","000",x"01",x"0F");
        wait for clk_period;
        i_i_info_write <= '0';
  
        wait until scl'stable(1 ms);
        wait until falling_edge(i_clk);
        o_i_data_next <= '1';
        for i in 5 to 14 loop
          check(i = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & to_string(i) & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
          wait for clk_period;
        end loop;
        for i in 25 to 39 loop
          check(i = unsigned(o_o_data_data), "Recieved invalid data. Expected: " & to_string(i) & " Recieved: " & to_string(to_integer(unsigned(o_o_data_data))));
          wait for clk_period;
        end loop;
        o_i_data_next <= '0';
  
        test_runner_cleanup(runner);
      end if;
    end loop;
  end process main;

  i_clk <= not i_clk after clk_period/2;
  sda <= 'H';
  scl <= 'H';

  
  ----------------------------------------------------------------------------------------
  --#ANCHOR - SLAVE SIM
  ----------------------------------------------------------------------------------------
-- I2C Slave Process
p_slave : process(i_clk)
begin
  if rising_edge(i_clk) then
    if i_rst_n = '0' then
      slave_reg <= (others => '0') ;
    else
      if (slave_write = '1') then
        slave_reg <= slave_reg_i;
      end if;
      if (read_req = '1') then
        slave_reg <= std_logic_vector(unsigned(slave_reg) + 1);
      end if;
    end if;
  end if;


end process;


I2C_minion_inst : entity work.I2C_minion
  generic map (
    MINION_ADDR => I2C_SLAVE_ADDR,
    USE_INPUT_DEBOUNCING => false,
    DEBOUNCING_WAIT_CYCLES => 4
  )
  port map (
    scl => scl,
    sda => sda,
    clk => i_clk,
    rst => not (i_rst_n),
    read_req => read_req,
    data_to_master => slave_reg,
    data_valid => slave_write,
    data_from_master => slave_reg_i
  );


end;