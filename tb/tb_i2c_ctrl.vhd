library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_common.all;
use work.my_common.all;


LIBRARY VUNIT_LIB;
CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

entity tb_i2c_ctrl is
  generic (runner_cfg : string);
 end entity tb_i2c_ctrl;

architecture sim of tb_i2c_ctrl is
  constant CLK_PERIOD : time := 10 ns; -- Clock period (10 MHz)

  signal clk : std_logic := '0'; -- Clock signal
  signal valid : std_logic := '0'; -- Indicates valid data received
  signal rst_n  : std_logic := '0';
  signal flags  : std_logic_vector(7 downto 0); -- Data byte received via UART)



  signal i_i_data_fifo_data   : data_bus;
  signal i_i_data_fifo_empty  : std_logic;
  signal o_i_data_fifo_next   : std_logic;
  signal o_o_data_fifo_data   : data_bus;
  signal i_o_data_fifo_full   : std_logic;
  signal o_o_data_fifo_next   : std_logic;
  signal i_i_info_fifo_data   : info_bus;
  signal i_i_info_fifo_empty  : std_logic;
  signal o_i_info_fifo_next   : std_logic;
  signal o_o_info_fifo_data   : info_bus;
  signal i_o_info_fifo_full   : std_logic;
  signal o_o_info_fifo_next   : std_logic;

  signal sda, scl : std_logic;
  signal i_interrupt, o_interrupt  : std_logic;

  signal read_req, slave_write : std_logic;
  signal slave_reg, slave_reg_i : std_logic_vector(MSG_W - 1 downto 0);

begin
  sda <= 'H';
  scl <= 'H';
  flags <= o_o_info_fifo_data(MSG_W-1 downto 0);
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
--#ANCHOR - Transmission
----------------------------------------------------------------------------------------
  -- transmission test
  p_i2c_test : process
  begin
    test_runner_setup(runner, runner_cfg);
    wait for 0 fs;
    rst_n <= '0';
    i_interrupt <= '0';
    i_i_info_fifo_empty <= '1';
    i_o_data_fifo_full <= '0';
    wait for CLK_PERIOD;
    rst_n <= '1';
    i_i_info_fifo_data <= create_reg0_w("00",std_logic_vector(to_unsigned(1,3)),"00000100","00000000");
    i_i_info_fifo_empty <= '0';
    i_i_data_fifo_empty <= '0';
    i_i_data_fifo_data <= "00000100";
    wait until (o_i_data_fifo_next = '1'); 
    i_i_data_fifo_data <= x"F1";
    i_i_info_fifo_empty <= '1';
    wait until rising_edge(clk);
    wait until (o_i_data_fifo_next = '1'); 
    i_i_data_fifo_data <= x"E2";
    wait until rising_edge(clk);
    wait until (o_i_data_fifo_next = '1');
    i_i_data_fifo_data <= x"D3";
    wait until rising_edge(clk);
    wait until (o_i_data_fifo_next = '1'); --FIXME - turns on empty signal too late
    

    wait for 1 ms;
    --FIXME - does not work properly
    i_i_info_fifo_data <= create_reg0_w("00",std_logic_vector(to_unsigned(1,3)),"00000001","00000010");
    i_i_info_fifo_empty <= '0';
    i_i_data_fifo_empty <= '0';
    i_i_data_fifo_data <= "00000101";
    wait until (o_i_info_fifo_next = '1');
    i_i_info_fifo_empty <= '1';
    i_i_data_fifo_empty <= '1';

    wait for 3 ms;

    -- Ukončení simulace        test_runner_cleanup(runner);
    test_runner_cleanup(runner);
  end process p_i2c_test;


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
--#ANCHOR - DUT
----------------------------------------------------------------------------------------
  i2c_ctrl_DUT : entity work.i2c_ctrl
  generic map (
    SMPL_W => SMPL_W,
    START_OFFSET => START_OFFSET,
    MY_ID => "001"
  )
  port map (
    clk => clk,
    i_rst_n => rst_n,
    i_en => '1',
    i_i_data_fifo_data => i_i_data_fifo_data,
    i_i_data_fifo_empty => i_i_data_fifo_empty,
    o_i_data_fifo_next => o_i_data_fifo_next,
    o_o_data_fifo_data => o_o_data_fifo_data,
    i_o_data_fifo_full => i_o_data_fifo_full,
    o_o_data_fifo_next => o_o_data_fifo_next,
    i_i_info_fifo_data => i_i_info_fifo_data,
    i_i_info_fifo_empty => i_i_info_fifo_empty,
    o_i_info_fifo_next => o_i_info_fifo_next,
    o_o_info_fifo_data => o_o_info_fifo_data,
    i_o_info_fifo_full => i_o_info_fifo_full,
    o_o_info_fifo_next => o_o_info_fifo_next,
    scl => scl,
    sda => sda,
    i_interrupt => i_interrupt,
    o_interrupt => o_interrupt
  );

  end architecture;