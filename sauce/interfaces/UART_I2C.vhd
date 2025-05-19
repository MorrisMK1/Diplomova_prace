library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_unsigned.all;

library work;
  use work.my_common.all;

----------------------------------------------------------------------------------------
--ANCHOR - entity
----------------------------------------------------------------------------------------
entity UART_I2C is
  generic (
    constant  SMPL_W        : natural := 8;             -- rx line sample width
    constant  START_OFFSET  : natural := 10;            -- offset in clks between start and first bit
    constant  MY_ID         : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0) := "000"
  );
	port (
		clk   : in std_logic;
		i_rst_n : in std_logic;
		i_en                    : in  std_logic_vector(1 downto 0) := "10";

		i_i_data_fifo_data      : in  data_bus;
		i_i_data_fifo_empty     : in  out_ready;
		o_i_data_fifo_next      : out in_pulse;

		o_o_data_fifo_data      : out data_bus;
		i_o_data_fifo_full      : in  out_ready;
		o_o_data_fifo_next      : out in_pulse;
	
		i_i_info_fifo_data      : in  info_bus;
		i_i_info_fifo_empty     : in  out_ready;
		o_i_info_fifo_next      : out in_pulse;

		o_o_info_fifo_data      : out info_bus;
		i_o_info_fifo_full      : in  out_ready;
		o_o_info_fifo_next      : out in_pulse;

		tx_scl                  : inout std_logic := 'Z';
		rx_sda                  : inout std_logic := 'Z';
		i_interrupt_tx_rdy      : in  std_logic;
		o_interrupt_rx_rdy      : out std_logic;

    o_busy          : out std_logic
		
	);
end entity;


----------------------------------------------------------------------------------------
--ANCHOR - architecture
----------------------------------------------------------------------------------------
architecture rtl of UART_I2C is	

	signal tx,	rx,	i_sda,	i_scl,	o_sda,	o_scl,	tx_ready,	rx_ready,	i_interrupt,	o_interrupt, en_i2c, en_uart	: std_logic;

  signal o_i_data_fifo_next_i2c, o_i_data_fifo_next_uart : std_logic;
  signal o_o_data_fifo_data_i2c, o_o_data_fifo_data_uart : data_bus;
  signal o_o_data_fifo_next_i2c, o_o_data_fifo_next_uart : std_logic;
  
  signal o_i_info_fifo_next_i2c, o_i_info_fifo_next_uart : std_logic;
  signal o_o_info_fifo_data_i2c, o_o_info_fifo_data_uart : info_bus;
  signal o_o_info_fifo_next_i2c, o_o_info_fifo_next_uart : std_logic;

  signal uart_busy, i2c_busy : std_logic;
begin

  en_i2c  <= '1' when (i_en = "01") else '0';
  en_uart <= '1' when (i_en = "10") else '0';
  o_busy <= (i2c_busy) or (uart_busy);

  o_i_data_fifo_next <= o_i_data_fifo_next_i2c  when (i_en = "01") else
                        o_i_data_fifo_next_uart when (i_en = "10") else
                        '0';

  o_o_data_fifo_data <= o_o_data_fifo_data_i2c  when (i_en = "01") else
                        o_o_data_fifo_data_uart when (i_en = "10") else
                        (others => '0') ;

  o_o_data_fifo_next <= o_o_data_fifo_next_i2c  when (i_en = "01") else
                        o_o_data_fifo_next_uart when (i_en = "10") else
                        '0';

  o_i_info_fifo_next <= o_i_info_fifo_next_i2c  when (i_en = "01") else
                        o_i_info_fifo_next_uart when (i_en = "10") else
                        '0';

  o_o_info_fifo_data <= o_o_info_fifo_data_i2c  when (i_en = "01") else
                        o_o_info_fifo_data_uart when (i_en = "10") else
                        (others => '0') ;

  o_o_info_fifo_next <= o_o_info_fifo_next_i2c  when (i_en = "01") else
                        o_o_info_fifo_next_uart when (i_en = "10") else
                        '0';

  tx_ready <= i_interrupt_tx_rdy;
  i_interrupt <= i_interrupt_tx_rdy;

  o_interrupt_rx_rdy <= o_interrupt when (i_en = "01") else
                        rx_ready    when (i_en = "10") else
                        '0';

  p_bus_assigment : process(all)  -- swapping connections
  begin
    case (i_en) is
      when "01" =>
        if (o_scl = '1') then
          tx_scl <= 'Z';
        else
          tx_scl <= '0';
        end if;
        if (o_sda = '1') then
          rx_sda <= 'Z';
        else
          rx_sda <= '0';
        end if;
        i_sda <= rx_sda;
        i_scl <= tx_scl;
        rx <= '1';
        --tx <= open;
      when "10" =>
        i_sda <=  '1';
        i_scl <=  '1';
        tx_scl <= tx;
        rx_sda <= 'Z';
        rx <= rx_sda;
      when others =>
        i_scl  <= '1';
        i_sda  <= '1';
        tx_scl <= 'Z';
        rx_sda <= 'Z';
        rx     <= '1';
    end case;
  end process;
  

----------------------------------------------------------------------------------------
--ANCHOR - I2C controller
----------------------------------------------------------------------------------------
	i2c_ctrl_inst : entity work.i2c_ctrl
  generic map (
    MY_ID => MY_ID,
    INTERNAL_I2C => true
  )
  port map (
    clk => clk,
    i_rst_n => i_rst_n,
    i_en => en_i2c,
    i_i_data_fifo_data => i_i_data_fifo_data,
    i_i_data_fifo_empty => i_i_data_fifo_empty,
    o_i_data_fifo_next => o_i_data_fifo_next_i2c,
    o_o_data_fifo_data => o_o_data_fifo_data_i2c,
    i_o_data_fifo_full => i_o_data_fifo_full,
    o_o_data_fifo_next => o_o_data_fifo_next_i2c,
    i_i_info_fifo_data => i_i_info_fifo_data,
    i_i_info_fifo_empty => i_i_info_fifo_empty,
    o_i_info_fifo_next => o_i_info_fifo_next_i2c,
    o_o_info_fifo_data => o_o_info_fifo_data_i2c,
    i_o_info_fifo_full => i_o_info_fifo_full,
    o_o_info_fifo_next => o_o_info_fifo_next_i2c,
    scl => i_scl,
    sda => i_sda,
    o_scl => o_scl,
    o_sda => o_sda,
    i_interrupt => i_interrupt,
    o_interrupt => o_interrupt,
    o_busy => i2c_busy
  );

----------------------------------------------------------------------------------------
--ANCHOR - uart controller
----------------------------------------------------------------------------------------
	uart_ctrl2_inst : entity work.uart_ctrl2
  generic map (
    SMPL_W => SMPL_W,
    START_OFFSET => START_OFFSET,
    MY_ID => MY_ID
  )
  port map (
    i_clk => clk,
    i_rst_n => i_rst_n,
    i_en => en_uart,
    i_i_data_fifo_data => i_i_data_fifo_data,
    i_i_data_fifo_empty => i_i_data_fifo_empty,
    o_i_data_fifo_next => o_i_data_fifo_next_uart,
    o_o_data_fifo_data => o_o_data_fifo_data_uart,
    i_o_data_fifo_full => i_o_data_fifo_full,
    o_o_data_fifo_next => o_o_data_fifo_next_uart,
    i_i_info_fifo_data => i_i_info_fifo_data,
    i_i_info_fifo_empty => i_i_info_fifo_empty,
    o_i_info_fifo_next => o_i_info_fifo_next_uart,
    o_o_info_fifo_data => o_o_info_fifo_data_uart,
    i_o_info_fifo_full => i_o_info_fifo_full,
    o_o_info_fifo_next => o_o_info_fifo_next_uart,
    tx => tx,
    rx => rx,
    tx_ready => tx_ready,
    rx_ready => rx_ready,
    o_busy => uart_busy
  );



end architecture;