library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
library work;
use work.tb_common.all;
use work.my_common.all;

entity tb_uart is
end entity tb_uart;

architecture sim of tb_uart is

  constant UART_BAUD_PERIOD : time := 104.166 us; -- Period for 9600 baud rate with a 10 MHz clock
  constant CLK_PERIOD : time := 100 ns; -- Clock period (10 MHz)

  signal clk : std_logic := '0'; -- Clock signal
  signal tx : std_logic := '1';  -- UART TX signal (idle state '1')
  signal data_byte : std_logic_vector(7 downto 0); -- Data byte to transmit  
  signal rx : std_logic := '1';  -- UART RX signal (idle state '1')
  signal data_byte_received : std_logic_vector(7 downto 0); -- Data byte received via UART
  signal valid : std_logic := '0'; -- Indicates valid data received
  signal rst_n  : std_logic := '0';
  signal par_en  : std_logic := '0';
  signal par_type  : std_logic := '0';
  signal par_st  : std_logic := '0';
  signal clk_div  : unsigned(15 downto 0):= to_unsigned(UART_BAUD_PERIOD/CLK_PERIOD,16);
  signal flags  : std_logic_vector(7 downto 0); -- Data byte received via UART)
  signal msg_o_dat  : std_logic_vector(7 downto 0);
  signal msg_i_dat : std_logic_vector(7 downto 0);
  signal msg_o_vld : std_logic  := '0';
  signal msg_i_rdy : std_logic;
  signal out_busy : std_logic;


  procedure uart_tx(
    signal clk : in std_logic;
    signal tx : out std_logic;
    data : in std_logic_vector(7 downto 0)
  ) is
  begin
    -- Start bit (LOW)
    tx <= '0';
    wait for UART_BAUD_PERIOD;

    -- Data bits (LSB first)
    for i in 0 to 7 loop
      tx <= data(i);
      wait for UART_BAUD_PERIOD;
    end loop;

    -- Stop bit (HIGH)
    tx <= '1';
    wait for UART_BAUD_PERIOD;
  end procedure;
  
  
  procedure uart_rx(
    signal clk : in std_logic;
    signal rx : in std_logic;
    signal data_byte : out std_logic_vector(7 downto 0);
    signal valid : out std_logic
  ) is
  begin
    -- Čeká na start bit (LOW)
    wait until rx = '0';
    wait for UART_BAUD_PERIOD / 2; -- Align to the middle of the start bit
    
    -- Přijímá data bity (LSB first)
    for i in 0 to 7 loop
      wait for UART_BAUD_PERIOD; -- Wait for the next data bit
      data_byte(i) <= rx; -- Capture the data bit
    end loop;

    -- Čeká na stop bit (HIGH)
    wait for UART_BAUD_PERIOD;
    
    -- Označí, že data byla úspěšně přijata
    if rx = '1' then
      valid <= '1';
    else
      valid <= '0'; -- Stop bit nebyl validní
    end if;
  end procedure;

begin
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
  -- UART transmission test
  p_uart_tx : process
  begin
    wait for 10 us;
    rst_n <= '1';
    msg_i_dat <= "01010101";
    msg_i_rdy <= '1';
    data_byte <= "01010101"; -- Data byte to send via UART
    wait until out_busy = '1' for 1 us;
    msg_i_rdy <= '0';
    uart_tx(clk, tx, data_byte); -- Call the UART transmit procedure
    wait for 1 ms; -- Wait some time
    msg_i_dat <= "00110011";
    msg_i_rdy <= '1';
    data_byte <= "00110011"; -- Data byte to send via UART
    wait until out_busy = '1' for 1 us;
    msg_i_rdy <= '0';
    uart_tx(clk, tx, data_byte); -- Call the UART transmit procedure
    wait for 1 ms; -- Wait some time
    msg_i_dat <= "11000011";
    msg_i_rdy <= '1';
    data_byte <= "11000011"; -- Data byte to send via UART
    wait until out_busy = '1' for 1 us;
    msg_i_rdy <= '0';
    uart_tx(clk, tx, data_byte); -- Call the UART transmit procedure
    wait for 1 ms; -- Wait some time
    
    -- Ukončení simulace
    std.env.stop(0);
  end process p_uart_tx;

----------------------------------------------------------------------------------------
--#ANCHOR - Recieving
----------------------------------------------------------------------------------------
  -- UART receiving test
  p_uart_rx : process
    variable message      : STRING(1 to 8);
  begin
    -- Inicializace
    valid <= '0';

    -- Zavolání přijímací procedury
    uart_rx(clk, rx, data_byte_received, valid);

    if valid = '1' then
      message := std_logic_vector_to_string(data_byte_received);
      report "Data received: " & message;
    else
      report "Invalid UART data received!";
    end if;
  end process p_uart_rx;


  uart_rx_inst : entity work.uart_rx
  generic map (
    MSG_W => MSG_W,
    SMPL_W => SMPL_W,
    START_OFFSET => START_OFFSET
  )
  port map (
    i_clk => clk,
    i_rst_n => rst_n,
    i_rx => tx,
    i_start_pol => par_st,
    i_par_en => par_en,
    i_par_type => par_type,
    i_clk_div => unsigned(clk_div),
    o_msg => msg_o_dat,
    o_msg_vld_strb => msg_o_vld,
    o_err_noise_strb => flags(0),
    o_err_frame_strb => flags(1),
    o_err_par_strb => flags(2)
  );
  
  
  uart_tx_inst : entity work.uart_tx
  generic map (
    MSG_W => MSG_W,
    SMPL_W => SMPL_W
  )
  port map (
    i_clk => clk,
    i_rst_n => rst_n,
    i_msg => msg_i_dat,
    i_msg_vld  => msg_i_rdy,
    i_start_pol => par_st,
    i_par_en => par_en,
    i_par_type => par_type,
    i_clk_div => unsigned(clk_div),
    o_tx => rx,
    o_busy => out_busy
  );
  
end architecture sim;