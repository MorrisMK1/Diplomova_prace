library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_unsigned.all;

library work;
  use work.my_common.all;

entity UART_I2C is
  generic (
    constant  SMPL_W        : natural := 8;             -- rx line sample width
    constant  START_OFFSET  : natural := 10;            -- offset in clks between start and first bit
    constant  MY_ID         : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0) := "000"
  );
	port (
		clk   : in std_logic;
		i_rst_n : in std_logic;
		i_en                    : in  std_logic_vector(0 downto 1) := '1';

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
		o_interrupt_rx_rdy      : out std_logic
		
	);
end entity;


architecture rtl of UART_I2C is			--FIXME - Needs a finish

	signal tx,	rx,	sda,	scl,	tx_ready,	rx_ready,	i_interrupt,	o_interrupt	: std_logic;

begin

	i2c_ctrl_inst : entity work.i2c_ctrl
  generic map (
    SMPL_W => SMPL_W,
    START_OFFSET => START_OFFSET,
    MY_ID => MY_ID
  )
  port map (
    clk => clk,
    i_rst_n => i_rst_n,
    i_en => i_en,
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

	uart_ctrl2_inst : entity work.uart_ctrl2
  generic map (
    SMPL_W => SMPL_W,
    START_OFFSET => START_OFFSET,
    MY_ID => MY_ID
  )
  port map (
    i_clk => clk,
    i_rst_n => i_rst_n,
    i_en => i_en,
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
    tx => tx,
    rx => rx,
    tx_ready => tx_ready,
    rx_ready => rx_ready
  );



end architecture;