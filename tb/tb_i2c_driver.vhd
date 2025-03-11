library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_common.all;
use work.my_common.all;


LIBRARY VUNIT_LIB;
CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

entity tb_i2c is
  generic (runner_cfg : string);
end entity tb_i2c;

architecture sim of tb_i2c is

  constant UART_BAUD_PERIOD : time := 104.166 us; -- Period for 9600 baud rate
  constant CLK_PERIOD : time := 10 ns; -- Clock period (10 MHz)

  constant I2C_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0000010";
  signal read_req, slave_write         : std_logic;
  signal slave_reg, slave_reg_i, slave_reg_o        : std_logic_vector(7 downto 0) := "00000000";



  signal clk : std_logic  := '0';
  signal rst_n : std_logic;
  signal scl : std_logic;
  signal sda : std_logic;
  signal i_data_vld : std_logic;
  signal i_data : data_bus;
  signal i_recieve : std_logic;
  signal o_data_vld : std_logic;
  signal o_data : data_bus;
  signal i_ignore : std_logic;
  signal o_no_ack : std_logic;
  signal clk_div : std_logic_vector(MSG_W * 2 - 1 downto 0);
  signal i_en_slave : std_logic;
  signal o_busy : std_logic;
  signal o_running : std_logic;


begin
  sda <= 'H';
  scl <= 'H';

  ----------------------------------------------------------------------------------------
  --#ANCHOR - CLOCK
  ----------------------------------------------------------------------------------------
  -- Clock generation
  clocking : process
  begin
    while true loop
      clk <= not clk;
      wait for CLK_PERIOD / 2;
    end loop;
  end process clocking;

  ----------------------------------------------------------------------------------------
  --#ANCHOR - SLAVE SIM
  ----------------------------------------------------------------------------------------
-- I2C Slave Process
p_slave : process(clk)
begin
  if rising_edge(clk) then
    if rst_n = '0' then
      slave_reg <= (others => '0') ;
    else
      if (slave_write = '1') then
        slave_reg <= slave_reg_i;
      end if;
    end if;
  end if;


end process;


I2C_minion_inst : entity work.I2C_minion
  generic map (
    MINION_ADDR => "0000010",
    USE_INPUT_DEBOUNCING => false,
    DEBOUNCING_WAIT_CYCLES => 4
  )
  port map (
    scl => scl,
    sda => sda,
    clk => clk,
    rst => not (rst_n),
    read_req => read_req,
    data_to_master => slave_reg,
    data_valid => slave_write,
    data_from_master => slave_reg_i
  );

----------------------------------------------------------------------------------------
--#ANCHOR - Transmission
----------------------------------------------------------------------------------------
  -- UART transmission test
  p_master_ctrl : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait for 0 fs;
    clk_div <= std_logic_vector(to_unsigned(10,MSG_W*2));
    i_en_slave <= '0';
    i_recieve <= '0';
    i_ignore <= '0';
    rst_n <= '0';
    wait for CLK_PERIOD * 2;
    rst_n <= '1';
    wait for CLK_PERIOD * 2;
    --ANCHOR - sending test
    i_data <= I2C_SLAVE_ADDR & '0';
    i_data_vld <= '1';
    wait until (o_busy = '1') for 10 us;
    if (o_busy = '0') then
      report "ASSERT FAILURE - TB_I2C_DRIVER: ADDRESS WAS NOT SEND " severity failure;
    end if;
    i_data <= "10100101";
    wait until (o_busy = '0') for 10 us;
    wait until (o_busy = '1') for 10 us;
    if (o_busy = '0') then
      report "ASSERT FAILURE - TB_I2C_DRIVER: DATA 1 NOT SEND " severity failure;
    end if;
    wait until (o_busy = '0') for 10 us;
    if (slave_reg = i_data) then
      report "Data send succesfully";
    else
      report "Received: " & integer'image(to_integer(unsigned(slave_reg))) & "; Send: " & integer'image(to_integer(unsigned(i_data)));
    end if;
    i_data <= "01101001";
    wait until (o_busy = '0') for 10 us;
    wait until (o_busy = '1') for 10 us;
    if (o_busy = '0') then
      report "ASSERT FAILURE - TB_I2C_DRIVER: DATA 2 NOT SEND " severity failure;
    end if;
    i_data_vld <= '0';
    wait until (o_busy = '0') for 10 us;
    if (slave_reg = i_data) then
      report "Data send succesfully";
    else
      report "Received: " & integer'image(to_integer(unsigned(slave_reg))) & "; Send: " & integer'image(to_integer(unsigned(i_data)));
    end if;
    --ANCHOR - reciver testing
    wait until (o_running = '0');
    i_data <= I2C_SLAVE_ADDR & '1';
    i_data_vld <= '1';
    i_recieve <= '1';
    wait until (o_busy = '1') for 10 us;
    i_data_vld <= '0';
    if (o_busy = '0') then
      report "ASSERT FAILURE - TB_I2C_DRIVER: ADDRESS 2 WAS NOT SEND " severity failure;
    end if;
    wait until (o_busy = '0') for 10 us;
    wait until (o_busy = '1') for 10 us;
    i_recieve <= '0';
    wait until (o_data_vld = '1') for 1 ms;
    if (o_data_vld = '0') then
      report "ASSERT FAILURE - TB_I2C_DRIVER: NO DATA RECIEVED " severity failure;
    end if;
    if (slave_reg = o_data) then
      report "Data send succesfully";
    else
      report "Received: " & integer'image(to_integer(unsigned(slave_reg))) & "; Send: " & integer'image(to_integer(unsigned(o_data)));
    end if;
    wait until (o_running = '0') for 1 ms;
    if (o_running = '1') then
      report "ASSERT FAILURE - TB_I2C_DRIVER: RECIEVEING DID NOT STOP " severity failure;
    end if;
    wait for 1 us;

    -- Ukončení simulace        test_runner_cleanup(runner);
    test_runner_cleanup(runner);
  end process p_master_ctrl;

  ----------------------------------------------------------------------------------------
--#ANCHOR - DUT
----------------------------------------------------------------------------------------
  i2c_driver_DUT : entity work.i2c_driver
  port map (
    clk => clk,
    rst_n => rst_n,
    scl => scl,
    sda => sda,
    i_data_vld => i_data_vld,
    i_data => i_data,
    i_recieve => i_recieve,
    o_data_vld => o_data_vld,
    o_data => o_data,
    i_ignore => i_ignore,
    o_no_ack => o_no_ack,
    clk_div => clk_div,
    i_en_slave => i_en_slave,
    o_busy => o_busy,
    o_running => o_running
  );

  end architecture;