library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
library work;
use work.tb_common.all;
use work.my_common.all;

entity tb_universal_uart is
end entity;


architecture sim of tb_universal_uart is

  constant CLK_PERIOD : TIME := 10 ns;

  constant MSG_W : natural := 8;
  constant SMPL_W : natural := 8;
  constant START_OFFSET : natural := 10;
  constant BUS_MODE : t_bus_type := t_bus_UART;
  constant MY_ID : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0) := "000";
  signal clk : std_logic;
  signal i_rst_n : std_logic := '0';
  signal comm_wire : std_logic;
  signal SPI_device_sel : STD_LOGIC_VECTOR(MSG_W-1 downto 0);
  signal recieved_data  : std_logic_vector(MSG_W-1 downto 0);
  signal recieved_info  : std_logic_vector(3*MSG_W-1 downto 0);
  signal i_i_data_fifo_data : data_bus;
  signal i_i_data_fifo_ready : out_ready;
  signal o_i_data_fifo_next : in_pulse;
  signal o_o_data_fifo_data : data_bus;
  signal o_o_data_fifo_ready : out_ready;
  signal i_o_data_fifo_next : in_pulse;
  signal i_i_info_fifo_data : info_bus;
  signal i_i_info_fifo_ready : out_ready;
  signal o_i_info_fifo_next : in_pulse;
  signal o_o_info_fifo_data : info_bus;
  signal o_o_info_fifo_ready : out_ready;
  signal i_o_info_fifo_next : in_pulse;


begin

  p_clk :process
  begin
    generate_clk(clk,CLK_PERIOD);
  end process;

  p_test  : process
  begin
    wait for 1 ns;
    i_i_data_fifo_data <= (others => '0');
    i_i_data_fifo_ready <= '0';
    i_o_data_fifo_next <= '0';
    i_i_info_fifo_data <= (others => '0');
    i_i_info_fifo_ready <= '0';
    i_o_info_fifo_next <= '0';
    recieved_data <= ((others => '0') );
    recieved_info <= ((others => '0') );
    wait for CLK_PERIOD*2;
    i_rst_n <= '1';
    wait for CLK_PERIOD*10;
    sim_fifo_out(i_i_info_fifo_data,i_i_info_fifo_ready,"111000000000010100000101");
    wait until o_i_info_fifo_next = '1';
    i_i_info_fifo_ready <= '0';
    sim_fifo_out(i_i_data_fifo_data,i_i_data_fifo_ready,"01101001");
    wait until o_i_data_fifo_next = '1';
    i_i_data_fifo_ready <= '0';
    sim_fifo_in(o_o_data_fifo_data,o_o_data_fifo_ready,recieved_data,CLK_PERIOD);
    i_o_data_fifo_next <= '1';
    wait until o_o_data_fifo_ready = '0';
    i_o_data_fifo_next <= '0';
    sim_fifo_out(i_i_data_fifo_data,i_i_data_fifo_ready,"11011100");
    wait until o_i_data_fifo_next = '1';
    i_i_data_fifo_ready <= '0';
    sim_fifo_in(o_o_data_fifo_data,o_o_data_fifo_ready,recieved_data,CLK_PERIOD);
    i_o_data_fifo_next <= '1';
    wait until o_o_data_fifo_ready = '0';
    i_o_data_fifo_next <= '0';
    sim_fifo_out(i_i_data_fifo_data,i_i_data_fifo_ready,"00011000");
    wait until o_i_data_fifo_next = '1';
    i_i_data_fifo_ready <= '0';
    sim_fifo_in(o_o_data_fifo_data,o_o_data_fifo_ready,recieved_data,CLK_PERIOD);
    i_o_data_fifo_next <= '1';
    wait until o_o_data_fifo_ready = '0';
    i_o_data_fifo_next <= '0';
    sim_fifo_out(i_i_data_fifo_data,i_i_data_fifo_ready,"10100101");
    wait until o_i_data_fifo_next = '1';
    i_i_data_fifo_ready <= '0';
    sim_fifo_in(o_o_data_fifo_data,o_o_data_fifo_ready,recieved_data,CLK_PERIOD);
    i_o_data_fifo_next <= '1';
    wait until o_o_data_fifo_ready = '0';
    i_o_data_fifo_next <= '0';
    sim_fifo_out(i_i_data_fifo_data,i_i_data_fifo_ready,"11110000");
    wait until o_i_data_fifo_next = '1';
    i_i_data_fifo_ready <= '0';
    sim_fifo_in(o_o_data_fifo_data,o_o_data_fifo_ready,recieved_data,CLK_PERIOD);
    i_o_data_fifo_next <= '1';
    wait until o_o_data_fifo_ready = '0';
    i_o_data_fifo_next <= '0';
    sim_fifo_in(o_o_info_fifo_data,o_o_info_fifo_ready,recieved_info,CLK_PERIOD);
    wait until o_o_info_fifo_ready = '0';
    wait for CLK_PERIOD*10;
    std.env.stop(0);
  end process p_test;


  universal_ctrl_DUT : entity work.universal_ctrl
  generic map (
    MSG_W => MSG_W,
    SMPL_W => SMPL_W,
    START_OFFSET => START_OFFSET,
    BUS_MODE => BUS_MODE,
    MY_ID => "000"
  )
  port map (
    i_clk => clk,
    i_rst_n => i_rst_n,
    i_en => '1',
    i_i_data_fifo_data =>   i_i_data_fifo_data,
    i_i_data_fifo_ready =>  i_i_data_fifo_ready,
    o_i_data_fifo_next =>   o_i_data_fifo_next,
    o_o_data_fifo_data =>   o_o_data_fifo_data,
    o_o_data_fifo_ready =>  o_o_data_fifo_ready,
    i_o_data_fifo_next =>   i_o_data_fifo_next,
    i_i_info_fifo_data =>   i_i_info_fifo_data,
    i_i_info_fifo_ready =>  i_i_info_fifo_ready,
    o_i_info_fifo_next =>   o_i_info_fifo_next,
    o_o_info_fifo_data =>   o_o_info_fifo_data,
    o_o_info_fifo_ready =>  o_o_info_fifo_ready,
    i_o_info_fifo_next =>   i_o_info_fifo_next,
    comm_wire_0 => comm_wire,
    comm_wire_1 => comm_wire,
    SPI_device_sel => SPI_device_sel
  );

end architecture;