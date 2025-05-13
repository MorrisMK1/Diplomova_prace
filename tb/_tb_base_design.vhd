library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library work;
use work.my_common.all;
use work.tb_common.all;

LIBRARY VUNIT_LIB;
CONTEXT VUNIT_LIB.VUNIT_CONTEXT;

entity tb_base_design is
  generic (runner_cfg : string);
end entity tb_base_design;

----------------------------------------------------------------------------------------
--SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture sim of tb_base_design is 

constant CLK_PERIOD : TIME := 10 ns;

signal i_clk          : std_logic;
signal i_rst_n        : std_logic;

signal tx_sl1, tx_sl2 : std_logic;
signal tx_ms          : std_logic;
signal rx_ms          : std_logic;

signal MISO_4, MOSI_4, SCLK_4 :std_logic;
signal o_CS_4         : std_logic_vector(7 downto 0);
signal MISO_5, MOSI_5, SCLK_5 :std_logic;
signal o_CS_5         : std_logic_vector(7 downto 0);

signal scl_3, sda_3, i2c_3_inter:std_logic;

signal i_settings     : std_logic_array (1 to 2) (MSG_W -1 downto 0);

signal gen_header     : info_bus;
signal message        : std_logic_array(0 to 255) (MSG_W -1 downto 0);


constant I2C_SLAVE_ADDR : std_logic_vector(6 downto 0) := "1010101";
signal read_req, slave_write         : std_logic;
signal slave_reg, slave_reg_i        : std_logic_vector(7 downto 0) := "00000000";

begin
----------------------------------------------------------------------------------------
--ANCHOR - CLK
----------------------------------------------------------------------------------------
p_clk :process
begin
  generate_clk(i_clk,CLK_PERIOD);
end process;
----------------------------------------------------------------------------------------
--ANCHOR - uart monitor
----------------------------------------------------------------------------------------
p_uart_print :process
  variable ret_msg        : data_bus;
begin
  uart_rx(tx_ms,ret_msg, 1.085 us);
end process;
----------------------------------------------------------------------------------------
--SECTION - TESTCASE
----------------------------------------------------------------------------------------
MISO_4 <= '1';
p_test  : process
  variable loop_cnt   : unsigned(MSG_W - 1 downto 0);
  variable msg_val    : std_logic_vector(MSG_W-1 downto 0);
begin
  --ANCHOR - init
  test_runner_setup(runner, runner_cfg);
  while test_suite loop
    if run("base_test") then
      wait for 1 ns;
      i_rst_n <= '0';
      i_settings(1) <= "00000111";
      i_settings(2) <= "10000000";
      rx_ms <= '1';
      scl_3 <= 'H';
      sda_3 <= 'H';
      for i in 0 to 255 loop
        message(i) <= (others => '0');
      end loop;
      wait for CLK_PERIOD*2;
      i_rst_n <= '1';
      wait for CLK_PERIOD*1;
      uart_tx_message(rx_ms,(104.167 us),"00001000" & i_settings(1) & x"00",message);
      info("Uart test - main config 1");
      wait for CLK_PERIOD*1;
      uart_tx_message(rx_ms,(1.085 us),"00010000" & i_settings(2) & x"00",message);
      info("Uart test - main config 2");
      wait for CLK_PERIOD*1;
      uart_tx_message(rx_ms,(1.085 us),"00011000" & x"D5" & x"00",message);
      info("Uart test - main config 3");
      for i in 1 to 2 loop
        info("Starting loop " & to_string(i));
        uart_tx_message(rx_ms,(1.085 us),"000010110000001000000000",message);
        --ANCHOR - first message
        info("Uart test - send and recieve message start");
        wait for CLK_PERIOD*1;
        message(0) <= "01011010";
        message(1) <= "11001001";
        wait for CLK_PERIOD*1;
        uart_tx_message(rx_ms,(1.085 us),create_reg0_w("00",std_logic_vector(to_unsigned(i,3)),"00000010","00000010"),message);
        info("Uart test - send and recieve message sent");

        --ANCHOR - second message
        info("Uart test 2 - send and recieve message start");
        wait for CLK_PERIOD*1;
        message(0) <= "01100110";
        wait for CLK_PERIOD*1;
        uart_tx_message(rx_ms,(1.085 us),create_reg0_w("01",std_logic_vector(to_unsigned(i,3)),"00000001","00000001"),message);
        info("Uart test 2 - send and recieve message sent");
      
        --ANCHOR - third message - set new parameters
        info("Uart test 3 - change settings start");
        wait for CLK_PERIOD*1;
        uart_tx_message(rx_ms,(1.085 us),create_reg1_w("10",std_logic_vector(to_unsigned(i,3)),'0','0','1','0',"001"),message);
        info("Uart test 3 - change settings sent");

        --ANCHOR - fourth message - repeat of second
        info("Uart test 4 - send and recieve message start");
        wait for CLK_PERIOD*1;
        message(0) <= "01100110";
        wait for CLK_PERIOD*1;
        uart_tx_message(rx_ms,(1.085 us),create_reg0_w("01",std_logic_vector(to_unsigned(i,3)),"00000001","00000001"),message);
        info("Uart test 4 - send and recieve message sent");

        --ANCHOR - 5 message - set new parameters
        info("Uart test 5 - change settings start");
        wait for CLK_PERIOD*1;
        uart_tx_message(rx_ms,(1.085 us),create_reg1_w("10",std_logic_vector(to_unsigned(i,3)),'0','1','1','0',"111"),message);
        info("Uart test 5 - change settings sent");

        --ANCHOR - 6 message - large message
        info("Uart test 6 - large message start");
        wait for CLK_PERIOD;
        message(0) <=  "01100110";
        for loop_cnt in 1 to 20 loop
          message(loop_cnt) <= std_logic_vector(to_unsigned(loop_cnt,MSG_W));
        end loop;
        wait for CLK_PERIOD;
        uart_tx_message(rx_ms,(1.085 us),create_reg0_w("01",std_logic_vector(to_unsigned(i,3)),"00010100","00010100"),message);
      end loop;
      --wait for  60 ms; --CLK_PERIOD * 100_000_000;
      wait until ((tx_sl1'stable(1.2 ms)) and (tx_sl2'stable(1.2 ms)));
      test_runner_cleanup(runner);
      --!SECTION
    elsif run("overfill_info") then --SECTION - overfill info test
      wait for 1 ns;
      i_rst_n <= '0';
      i_settings(1) <= "00000111";
      i_settings(2) <= "10000000";
      rx_ms <= '1';
      scl_3 <= 'H';
      sda_3 <= 'H';
      for i in 0 to 255 loop
        message(i) <= (others => '0');
      end loop;
      wait for CLK_PERIOD*2;
      i_rst_n <= '1';
      wait for CLK_PERIOD*1;
      uart_tx_message(rx_ms,(104.167 us),"00001000" & i_settings(1) & x"00",message);
      info("Uart test - main config 1");
      wait for CLK_PERIOD*1;
      uart_tx_message(rx_ms,(1.085 us),"00010000" & i_settings(2) & x"00",message);
      info("Uart test - main config 2");
      wait for CLK_PERIOD*1;
      uart_tx_message(rx_ms,(1.085 us),"00011000" & x"DD" & x"00",message);
      info("Uart test - main config 3");
      gen_header <= create_reg0_w("00",'0',"011","00001010","00000000");
      for i in 70 downto 0 loop
        info("Sending msg: "& to_string(71 - i) & "/71");
        wait for 0 ns;
        msg_val :=  gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
        wait for 0 ns;
        uart_tx(rx_ms,msg_val,(1.085 us));
        wait for 0 ns;
        msg_val :=  gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
        wait for 0 ns;
        uart_tx(rx_ms,msg_val,(1.085 us));
        wait for 0 ns;
        msg_val :=  gen_header(MSG_W * 1 - 1 downto MSG_W * 0);
        wait for 0 ns;
        uart_tx(rx_ms,msg_val,(1.085 us));
        wait for 0 ns;
        for x in 0 to 9 loop
          msg_val :=  std_logic_vector(to_unsigned(x+16*x,8));
          wait for 0 ns;
          uart_tx(rx_ms,msg_val,(1.085 us));
          wait for 0 ns;
        end loop; 
      end loop;
      --!SECTION
      
      test_runner_cleanup(runner);
      
    elsif run("timeout") then --SECTION - timeout
      wait for 1 ns;
      i_rst_n <= '0';
      i_settings(1) <= "00000111";
      i_settings(2) <= "10000000";
      rx_ms <= '1';
      scl_3 <= 'H';
      sda_3 <= 'H';
      for i in 0 to 255 loop
        message(i) <= (others => '0');
      end loop;
      wait for CLK_PERIOD*2;
      i_rst_n <= '1';
      wait for CLK_PERIOD*1;
      uart_tx_message(rx_ms,(104.167 us),"00001000" & i_settings(1) & x"00",message);
      msg_val := "01010110";
      wait for CLK_PERIOD*1;
      uart_tx(rx_ms,msg_val,(1.085 us));
      wait for 2 us;
      wait until tx_ms'stable(20 us);
      test_runner_cleanup(runner);--!SECTION

    
    elsif run("data_fail") then --SECTION - data trasfer failed
      wait for 1 ns;
      i_rst_n <= '0';
      i_settings(1) <= "00000111";
      i_settings(2) <= "10000000";
      rx_ms <= '1';
      scl_3 <= 'H';
      sda_3 <= 'H';
      for i in 0 to 255 loop
        message(i) <= (others => '0');
      end loop;
      wait for CLK_PERIOD*2;
      i_rst_n <= '1';
      wait for CLK_PERIOD*1;
      uart_tx_message(rx_ms,(104.167 us),"00001000" & i_settings(1) & x"00",message);
      info("Uart test - main config 1");
      wait for CLK_PERIOD*1;
      uart_tx_message(rx_ms,(1.085 us),"00010000" & i_settings(2) & x"00",message);
      info("Uart test - main config 2");
      wait for CLK_PERIOD*1;
      uart_tx_message(rx_ms,(1.085 us),"00011000" & x"DD" & x"00",message);
      info("Uart test - main config 3");
      gen_header <= create_reg0_w("00",'0',"011","00001010","00000000");
        wait for 0 ns;
        msg_val :=  gen_header(MSG_W * 3 - 1 downto MSG_W * 2);
        wait for 0 ns;
        uart_tx(rx_ms,msg_val,(1.085 us));
        wait for 0 ns;
        msg_val :=  gen_header(MSG_W * 2 - 1 downto MSG_W * 1);
        wait for 0 ns;
        uart_tx(rx_ms,msg_val,(1.085 us));
        wait for 0 ns;
        msg_val :=  gen_header(MSG_W * 1 - 1 downto MSG_W * 0);
        wait for 0 ns;
        uart_tx(rx_ms,msg_val,(1.085 us));
        wait for 0 ns;
        for x in 0 to 7 loop
          msg_val :=  std_logic_vector(to_unsigned(x+16*x,8));
          wait for 0 ns;
          uart_tx(rx_ms,msg_val,(1.085 us));
          wait for 0 ns;
        end loop; 
      --!SECTION
      wait for 2 us;
      wait until tx_ms'stable(50 us);
      
      test_runner_cleanup(runner);
      
    end if;
  end loop;

end process;--!SECTION
----------------------------------------------------------------------------------------
--ANCHOR - DUT
----------------------------------------------------------------------------------------

main_inst : entity work.main_v2
  port map (
    i_clk_100MHz => i_clk,
    i_rst_n => i_rst_n,
    --i_settings => i_settings,
    main_tx => tx_ms,
    main_rx => rx_ms,
    slv1_tx => tx_sl1,
    slv1_rx => tx_sl1,
    slv2_tx => tx_sl2,
    slv2_rx => tx_sl2,
    MISO_4  => MISO_4,
    MOSI_4  => MOSI_4,
    SCLK_4  => SCLK_4,
    o_CS_4  => o_CS_4,
    MISO_5  => MISO_5,
    MOSI_5  => MOSI_5,
    SCLK_5  => SCLK_5,
    o_CS_5  => o_CS_5,
    slv3_tx => scl_3,      
    slv3_rx => sda_3,      
    slv3_sup_in =>i2c_3_inter,
    slv2_sup_in =>'0',
    slv1_sup_in =>'0'
  );

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
    scl => scl_3,
    sda => sda_3,
    clk => i_clk,
    rst => not (i_rst_n),
    read_req => read_req,
    data_to_master => slave_reg,
    data_valid => slave_write,
    data_from_master => slave_reg_i
  );

end architecture;--!SECTION