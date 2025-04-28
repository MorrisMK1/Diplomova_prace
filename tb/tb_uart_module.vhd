
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_common.all;
use work.my_common.all;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_uart_module is
  generic (
    runner_cfg : string
  );
end;

architecture bench of tb_uart_module is
  -- Clock period
  constant clk_period : time := 10 ns;
  -- Generics
  constant SMPL_W : natural := 8;
  constant START_OFFSET : natural := 10;
  constant MY_ID : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0) := "000";
  -- Ports
  signal i_clk : std_logic;
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
  signal slv_tx : std_logic;
  signal slv_rx : std_logic;
  signal slv_tx_rdy : std_logic;
  signal slv_rx_rdy : std_logic;


  signal UART_BAUD_PERIOD  : time := 104.167 us;

  signal data_byte_received,data_byte_sent     : data_bus;
  signal valid_rx,valid_tx,tx_done             : std_logic;
  

  procedure uart_tx(
    signal clk : in std_logic;
    signal tx : out std_logic;
    signal data_byte : in std_logic_vector(7 downto 0);
    signal valid : in std_logic;
    signal done  : out std_logic
  ) is
    variable data : std_logic_vector(7 downto 0);
  begin
    done  <=  '0';
    tx <= '1';
    --wait until valid = '1';
    data := data_byte;

    tx <= '0';
    
    for i in 0 to 7 loop
      wait for UART_BAUD_PERIOD; 
      tx <= data(i) ;
    end loop;

    wait for UART_BAUD_PERIOD;

    tx <= '1';
    wait for UART_BAUD_PERIOD;
    done <= '1';
  end procedure;
begin


  ----------------------------------------------------------------------------------------
  --#ANCHOR - CLOCK
  ----------------------------------------------------------------------------------------
  -- Clock generation
  clocking : process
  begin
    wait for 0 fs;
    i_clk <= '0';
    wait for CLK_PERIOD / 2;
    while true loop
      i_clk <= not i_clk;
      wait for CLK_PERIOD / 2;
    end loop;
  end process clocking;

  ----------------------------------------------------------------------------------------
--#ANCHOR - Recieving
----------------------------------------------------------------------------------------
  p_uart_rx : process
  begin
    valid_rx <= '0';

    wait until slv_tx = '0';
    wait for UART_BAUD_PERIOD/2;
    
    for i in 0 to 7 loop
      wait for UART_BAUD_PERIOD;
      data_byte_received(i) <= slv_tx; 
    end loop;


    wait for UART_BAUD_PERIOD;
    

    if slv_tx = '1' then
      valid_rx <= '1';
    else
      valid_rx <= '0';
    end if;
    wait for 1 * clk_period;

  end process p_uart_rx;


----------------------------------------------------------------------------------------
--#ANCHOR - DUT
----------------------------------------------------------------------------------------
uart_module_inst : entity work.uart_module
  generic map (
    ID => MY_ID
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
    slv_tx => slv_tx,
    slv_rx => slv_rx,
    slv_tx_rdy => slv_tx_rdy,
    slv_rx_rdy => slv_rx_rdy
  );


----------------------------------------------------------------------------------------
--#ANCHOR - Tests
----------------------------------------------------------------------------------------
  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_send") then
        info("Send test start");
        wait for 0 fs;
        i_rst_n <= '0';
        i_en <= '1';
        o_i_data_next <= '0';
        o_i_info_next <= '0';
        i_i_data_write <= '0';
        i_i_info_write <= '0';
        slv_tx_rdy <= '1';
        i_i_data_data <= (others => '0') ;
        i_i_info_data <= (others => '0') ;
        wait for clk_period * 1;
        i_rst_n <= '1';

        info("Inserting data");
        i_i_data_write <= '1';
        for i in 15 downto 0 loop
          i_i_data_data <= std_logic_vector(to_unsigned(5*i,MSG_W));
          wait for clk_period;
        end loop;
        i_i_data_write <= '0';
        info("Inserting info");
        i_i_info_write <= '1';
        i_i_info_data <= create_reg0_w("00",'0',"000",x"10",x"00");
        wait for clk_period;
        i_i_info_write <= '0';
        info("Capturing");

        for i in 15 downto 0 loop
          wait until valid_rx = '1';
          check(data_byte_received = std_logic_vector(to_unsigned(5*i,MSG_W)), "Wrong data recieved:"& to_string(data_byte_received) & " : " & to_string(std_logic_vector(to_unsigned(5*i,MSG_W))));
          info("Check " & to_string(i+1) & " / 16 done.");
          wait until valid_rx = '0';
        end loop;


        test_runner_cleanup(runner);
        
      elsif run("test_send_blocked") then
        info("Send blocked test start");
        wait for 0 fs;
        i_rst_n <= '0';
        i_en <= '1';
        o_i_data_next <= '0';
        slv_tx_rdy <= '1';
        o_i_info_next <= '0';
        i_i_data_write <= '0';
        i_i_info_write <= '0';
        i_i_data_data <= (others => '0') ;
        i_i_info_data <= (others => '0') ;
        wait for clk_period * 1;
        i_rst_n <= '1';

        info("Inserting data");
        i_i_data_write <= '1';
        for i in 15 downto 0 loop
          i_i_data_data <= std_logic_vector(to_unsigned(5*i,MSG_W));
          wait for clk_period;
        end loop;
        i_i_data_write <= '0';
        info("tx_ready disable");
        slv_tx_rdy <= '0';
        info("Enable ready signals");
        i_i_info_write <= '1';
        i_i_info_data <= "000100000110000000000000"; -- set ready singnals to enabled
        wait for clk_period;
        info("Inserting info");
        i_i_info_data <= create_reg0_w("00",'0',"000",x"10",x"00");
        wait for clk_period;
        i_i_info_write <= '0';
        info("Evaluating");

        wait until (slv_tx = '0') for 1 ms;

        check(slv_tx = '1', "Wrong data recieved:");
        info("Block passed, unblocking");
        slv_tx_rdy <= '1';



        for i in 15 downto 0 loop
          wait until valid_rx = '1';
          check(data_byte_received = std_logic_vector(to_unsigned(5*i,MSG_W)), "Wrong data recieved:"& to_string(data_byte_received) & " : " & to_string(std_logic_vector(to_unsigned(5*i,MSG_W))));
          info("Check " & to_string(i+1) & " / 16 done.");
          wait until valid_rx = '0';
        end loop;


        test_runner_cleanup(runner);
      elsif run("test_recieve") then
        info("Recieve test start");
        wait for 0 fs;
        i_rst_n <= '0';
        i_en <= '1';
        o_i_data_next <= '0';
        slv_tx_rdy <= '1';
        o_i_info_next <= '0';
        i_i_data_write <= '0';
        i_i_info_write <= '0';
        i_i_data_data <= (others => '0') ;
        i_i_info_data <= (others => '0') ;
        wait for clk_period * 1;
        i_rst_n <= '1';
        info("Enabling ready signals");
        i_i_info_write <= '1';
        i_i_info_data <= "000100000010000000000000"; -- set ready singnals to enabled
        wait for clk_period;
        i_i_info_write <= '0';

        info("Sending data");
        valid_tx <= '1';
        for i in 15 downto 0 loop
          data_byte_sent <= std_logic_vector(to_unsigned(5 * i,MSG_W));
          wait for clk_period;
          uart_tx(i_clk,slv_rx,data_byte_sent,valid_tx,tx_done);
          --wait for UART_BAUD_PERIOD;
          info("Sent packet: " & to_string(16-i) & "/16");
        end loop;
        valid_tx <= '0';

        wait until (o_o_info_empty = '0') for 1 ms;
        check((o_o_info_empty = '0'), "NO data recieved");
        
        wait until falling_edge(i_clk);
        o_i_data_next <= '1';
        for i in 15 downto 0 loop
          check(o_o_data_data = std_logic_vector(to_unsigned(5*i,MSG_W)), "Wrong data recieved:"& to_string(o_o_data_data) & " : " & to_string(std_logic_vector(to_unsigned(5*i,MSG_W))));
          info("Check " & to_string(i+1) & " / 16 done.");
          --if (i = 0 ) then
          --  o_i_data_next <= '0';
          --end if;
          wait for clk_period;
        end loop;
        o_i_data_next <= '0';

        test_runner_cleanup(runner);
    
      elsif run("test_info_overfill") then
        info("Recieve test info overfill start");
        wait for 0 fs;
        i_rst_n <= '0';
        i_en <= '1';
        o_i_data_next <= '0';
        slv_tx_rdy <= '1';
        o_i_info_next <= '0';
        i_i_data_write <= '0';
        i_i_info_write <= '0';
        i_i_data_data <= (others => '0') ;
        i_i_info_data <= (others => '0') ;
        wait for clk_period * 1;
        i_rst_n <= '1';
        info("Enabling ready signals");
        i_i_info_write <= '1';
        i_i_info_data <= "000100000010000000000000"; -- set ready singnals to enabled
        wait for clk_period;
        i_i_info_write <= '0';
  
        info("Sending data");
        valid_tx <= '1';
        for i in 32 downto 0 loop
          data_byte_sent <= std_logic_vector(to_unsigned(5 * i,MSG_W));
          wait for clk_period;
          uart_tx(i_clk,slv_rx,data_byte_sent,valid_tx,tx_done);
          info("Sent packet: " & to_string(33-i) & "/33");
          wait for UART_BAUD_PERIOD * 10; -- delay to trigger timeouts
        end loop;
        valid_tx <= '0';
  
        wait until (o_o_info_empty = '0') for 1 ms;
        check((o_o_info_empty = '0'), "NO data recieved");
        check((slv_rx_rdy = '0'), "Overfill did not stop transfer");


        test_runner_cleanup(runner);
      end if;
    end loop;
  end process main;


end;