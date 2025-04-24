

library ieee;
  use ieee.std_logic_1164.ALL;
  use ieee.numeric_std.all;

  use work.my_common.all;


  package im_package is

    component main_v2
  port (
    i_clk_100MHz : in std_logic;
    i_rst_n : in std_logic;
    main_tx : out std_logic;
    main_rx : in std_logic;
    slv1_tx : out std_logic;
    slv1_rx : in std_logic;
    slv2_tx : inout std_logic;
    slv2_rx : inout std_logic;
    scl_3 : inout std_logic;
    sda_3 : inout std_logic;
    i2c_3_inter : inout std_logic;
    MISO_4 : in std_logic;
    MOSI_4 : out std_logic;
    SCLK_4 : out std_logic;
    o_CS_4 : out std_logic_vector(7 downto 0)
  );
end component;

component uart_tx
  generic (
    MSG_W : natural;
    SMPL_W : natural
  );
  port (
    i_clk : in std_logic;
    i_rst_n : in std_logic;
    i_msg : in std_logic_vector(MSG_W-1 downto 0);
    i_msg_vld : in std_logic;
    i_start_pol : in std_logic;
    i_par_en : in std_logic;
    i_par_type : in std_logic;
    i_char_len : in std_logic_vector(1 downto 0);
    i_clk_div : in unsigned(15 downto 0);
    o_tx : out std_logic;
    o_busy : out std_logic
  );
end component;

component uart_rx
  generic (
    MSG_W : natural;
    SMPL_W : natural
  );
  port (
    i_clk : in std_logic;
    i_rst_n : in std_logic;
    i_rx : in std_logic;
    i_start_pol : in std_logic;
    i_par_en : in std_logic;
    i_par_type : in std_logic;
    i_char_len : in std_logic_vector(1 downto 0);
    i_clk_div : in unsigned(15 downto 0);
    o_msg : out std_logic_vector(MSG_W-1 downto 0);
    o_msg_vld_strb : out std_logic;
    o_busy : out std_logic;
    o_err_noise_strb : out std_logic;
    o_err_frame_strb : out std_logic;
    o_err_par_strb : out std_logic
  );
end component;

component uart_module
  generic (
    ID : std_logic_vector(2 downto 0);
    GEN_TYPE : string
  );
  port (
    i_clk : in std_logic;
    i_rst_n : in std_logic;
    i_en : in std_logic;
    i_i_info_write : in std_logic;
    i_i_info_data : in info_bus;
    i_o_info_full : out std_logic;
    i_i_data_write : in std_logic;
    i_i_data_data : in data_bus;
    i_o_data_full : out std_logic;
    o_i_info_next : in std_logic;
    o_o_info_data : out info_bus;
    o_o_info_empty : out std_logic;
    o_i_data_next : in std_logic;
    o_o_data_data : out data_bus;
    o_o_data_empty : out std_logic;
    slv_tx : out std_logic;
    slv_rx : in std_logic;
    slv_tx_rdy : in std_logic;
    slv_rx_rdy : out std_logic
  );
end component;

component uart_ctrl2
  generic (
    SMPL_W : natural;
    START_OFFSET : natural;
    MY_ID : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0)
  );
  port (
    i_clk : in std_logic;
    i_rst_n : in std_logic;
    i_en : in std_logic;
    i_i_data_fifo_data : in data_bus;
    i_i_data_fifo_empty : in out_ready;
    o_i_data_fifo_next : out in_pulse;
    o_o_data_fifo_data : out data_bus;
    i_o_data_fifo_full : in out_ready;
    o_o_data_fifo_next : out in_pulse;
    i_i_info_fifo_data : in info_bus;
    i_i_info_fifo_empty : in out_ready;
    o_i_info_fifo_next : out in_pulse;
    o_o_info_fifo_data : out info_bus;
    i_o_info_fifo_full : in out_ready;
    o_o_info_fifo_next : out in_pulse;
    tx : out std_logic;
    rx : in std_logic;
    tx_ready : in std_logic;
    rx_ready : out std_logic
  );
end component;

component main_ctrl_2
  port (
    i_clk : in std_logic;
    i_rst_n : in std_logic;
    i_i_data_fifo_data : in data_bus;
    i_i_data_fifo_ready : in out_ready;
    o_i_data_fifo_next : out in_pulse;
    o_o_data_fifo_data : out data_bus;
    i_o_data_fifo_ready : in out_ready;
    o_o_data_fifo_next : out in_pulse;
    i_i_info_fifo_data : in info_bus;
    i_i_info_fifo_ready : in out_ready;
    o_i_info_fifo_next : out in_pulse;
    o_o_info_fifo_data : out info_bus;
    i_o_info_fifo_ready : in out_ready;
    o_o_info_fifo_next : out in_pulse;
    i_settings : in std_logic_array (1 to 2) (MSG_W-1 downto 0);
    o_ready : out std_logic;
    tx : out std_logic;
    rx : in std_logic
  );
end component;

component SPI_module
  generic (
    ID : std_logic_vector(2 downto 0);
    GEN_TYPE : string
  );
  port (
    i_clk : in std_logic;
    i_rst_n : in std_logic;
    i_en : in std_logic;
    i_i_info_write : in std_logic;
    i_i_info_data : in info_bus;
    i_o_info_full : out std_logic;
    i_i_data_write : in std_logic;
    i_i_data_data : in data_bus;
    i_o_data_full : out std_logic;
    o_i_info_next : in std_logic;
    o_o_info_data : out info_bus;
    o_o_info_empty : out std_logic;
    o_i_data_next : in std_logic;
    o_o_data_data : out data_bus;
    o_o_data_empty : out std_logic;
    MISO : in std_logic;
    MOSI : out std_logic;
    SCLK : out std_logic;
    o_CS : out std_logic_vector(MSG_W - 1 downto 0)
  );
end component;

component SPI_driver
  generic (
    MISO_DEB_BUFF_SIZE : natural
  );
  port (
    clk_100MHz : in std_logic;
    rst_n : in std_logic;
    i_clk_div : in std_logic_vector((MSG_W * 2) - 1 downto 0);
    i_hold_active : in std_logic;
    i_data_dir : in std_logic;
    i_CPHA : in std_logic;
    i_data : in std_logic_vector(MSG_W - 1 downto 0);
    i_data_vld : in std_logic;
    o_data_read : out std_logic;
    i_data_recieve : in std_logic;
    o_data : out std_logic_vector(MSG_W - 1 downto 0);
    o_data_vld : out std_logic;
    o_busy : out std_logic;
    o_noise_flg : out std_logic;
    MISO : in std_logic;
    MOSI : out std_logic;
    SCLK : out std_logic
  );
end component;

component SPI_ctrl
  generic (
    SMPL_W : natural;
    START_OFFSET : natural;
    MY_ID : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0)
  );
  port (
    clk_100MHz : in std_logic;
    i_rst_n : in std_logic;
    i_en : in std_logic;
    i_i_data_fifo_data : in data_bus;
    i_i_data_fifo_empty : in out_ready;
    o_i_data_fifo_next : out in_pulse;
    o_o_data_fifo_data : out data_bus;
    i_o_data_fifo_full : in out_ready;
    o_o_data_fifo_next : out in_pulse;
    i_i_info_fifo_data : in info_bus;
    i_i_info_fifo_empty : in out_ready;
    o_i_info_fifo_next : out in_pulse;
    o_o_info_fifo_data : out info_bus;
    i_o_info_fifo_full : in out_ready;
    o_o_info_fifo_next : out in_pulse;
    MISO : in std_logic;
    MOSI : out std_logic;
    SCLK : out std_logic;
    o_CS : out std_logic_vector(7 downto 0)
  );
end component;

component UART_I2C
  generic (
    SMPL_W : natural;
    START_OFFSET : natural;
    MY_ID : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0)
  );
  port (
    clk : in std_logic;
    i_rst_n : in std_logic;
    i_en : in std_logic_vector(1 downto 0);
    i_i_data_fifo_data : in data_bus;
    i_i_data_fifo_empty : in out_ready;
    o_i_data_fifo_next : out in_pulse;
    o_o_data_fifo_data : out data_bus;
    i_o_data_fifo_full : in out_ready;
    o_o_data_fifo_next : out in_pulse;
    i_i_info_fifo_data : in info_bus;
    i_i_info_fifo_empty : in out_ready;
    o_i_info_fifo_next : out in_pulse;
    o_o_info_fifo_data : out info_bus;
    i_o_info_fifo_full : in out_ready;
    o_o_info_fifo_next : out in_pulse;
    tx_scl : inout std_logic;
    rx_sda : inout std_logic;
    i_interrupt_tx_rdy : in std_logic;
    o_interrupt_rx_rdy : out std_logic
  );
end component;

component uart_i2c_module
  generic (
    ID : std_logic_vector(2 downto 0);
    GEN_TYPE : string
  );
  port (
    i_clk : in std_logic;
    i_rst_n : in std_logic;
    i_en : in std_logic_vector (1 downto 0);
    i_i_info_write : in std_logic;
    i_i_info_data : in info_bus;
    i_o_info_full : out std_logic;
    i_i_data_write : in std_logic;
    i_i_data_data : in data_bus;
    i_o_data_full : out std_logic;
    o_i_info_next : in std_logic;
    o_o_info_data : out info_bus;
    o_o_info_empty : out std_logic;
    o_i_data_next : in std_logic;
    o_o_data_data : out data_bus;
    o_o_data_empty : out std_logic;
    tx_scl : inout std_logic;
    rx_sda : inout std_logic;
    i_interrupt_tx_rdy : in std_logic;
    o_interrupt_rx_rdy : out std_logic
  );
end component;

component router
  port (
    i_clk : in std_logic;
    i_rst_n : in std_logic;
    i_out_en : in std_logic_vector(MSG_W -1 downto 0);
    i_bypass : in std_logic;
    o_err_rep : out std_logic;
    i_i_data_fifo_data : in data_bus;
    i_i_data_fifo_ready : in out_ready;
    o_i_data_fifo_next : out in_pulse;
    o_o_data_fifo_data : out data_bus;
    i_o_data_fifo_full_0 : in out_ready;
    o_o_data_fifo_next_0 : out in_pulse;
    i_o_data_fifo_full_1 : in out_ready;
    o_o_data_fifo_next_1 : out in_pulse;
    i_o_data_fifo_full_2 : in out_ready;
    o_o_data_fifo_next_2 : out in_pulse;
    i_o_data_fifo_full_3 : in out_ready;
    o_o_data_fifo_next_3 : out in_pulse;
    i_o_data_fifo_full_4 : in out_ready;
    o_o_data_fifo_next_4 : out in_pulse;
    i_o_data_fifo_full_5 : in out_ready;
    o_o_data_fifo_next_5 : out in_pulse;
    i_o_data_fifo_full_6 : in out_ready;
    o_o_data_fifo_next_6 : out in_pulse;
    i_o_data_fifo_full_7 : in out_ready;
    o_o_data_fifo_next_7 : out in_pulse;
    o_o_data_fifo_full_X : out out_ready;
    i_o_data_fifo_next_X : in in_pulse;
    i_i_info_fifo_data : in info_bus;
    i_i_info_fifo_ready : in out_ready;
    o_i_info_fifo_next : out in_pulse;
    o_o_info_fifo_data : out info_bus;
    i_o_info_fifo_full_0 : in out_ready;
    o_o_info_fifo_next_0 : out in_pulse;
    i_o_info_fifo_full_1 : in out_ready;
    o_o_info_fifo_next_1 : out in_pulse;
    i_o_info_fifo_full_2 : in out_ready;
    o_o_info_fifo_next_2 : out in_pulse;
    i_o_info_fifo_full_3 : in out_ready;
    o_o_info_fifo_next_3 : out in_pulse;
    i_o_info_fifo_full_4 : in out_ready;
    o_o_info_fifo_next_4 : out in_pulse;
    i_o_info_fifo_full_5 : in out_ready;
    o_o_info_fifo_next_5 : out in_pulse;
    i_o_info_fifo_full_6 : in out_ready;
    o_o_info_fifo_next_6 : out in_pulse;
    i_o_info_fifo_full_7 : in out_ready;
    o_o_info_fifo_next_7 : out in_pulse;
    o_o_info_fifo_full_X : out out_ready;
    i_o_info_fifo_next_X : in in_pulse
  );
end component;

component design_config
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    i_i_data_fifo_data : in data_bus;
    i_i_data_fifo_write : in out_ready;
    o_i_data_fifo_blck : out in_pulse;
    o_o_data_fifo_data : out data_bus;
    i_o_data_fifo_read : in out_ready;
    o_o_data_fifo_blck : out in_pulse;
    i_i_info_fifo_data : in info_bus;
    i_i_info_fifo_write : in out_ready;
    o_i_info_fifo_blck : out in_pulse;
    o_o_info_fifo_data : out info_bus;
    i_o_info_fifo_read : in out_ready;
    o_o_info_fifo_blck : out in_pulse;
    o_settings_main : out std_logic_array (1 to 2) (MSG_W-1 downto 0);
    o_enable_interfaces : out std_logic_vector (MSG_W-1 downto 0)
  );
end component;

component collector
  port (
    i_clk : in std_logic;
    i_rst_n : in std_logic;
    o_bypass : out std_logic;
    i_err_rep : in std_logic;
    i_i_data_fifo_data_X : in data_bus;
    i_i_data_fifo_data_0 : in data_bus;
    i_i_data_fifo_data_1 : in data_bus;
    i_i_data_fifo_data_2 : in data_bus;
    i_i_data_fifo_data_3 : in data_bus;
    i_i_data_fifo_data_4 : in data_bus;
    i_i_data_fifo_data_5 : in data_bus;
    i_i_data_fifo_data_6 : in data_bus;
    i_i_data_fifo_data_7 : in data_bus;
    i_i_data_fifo_empty_X : in out_ready;
    o_i_data_fifo_next_X : out in_pulse;
    i_i_data_fifo_empty_0 : in out_ready;
    o_i_data_fifo_next_0 : out in_pulse;
    i_i_data_fifo_empty_1 : in out_ready;
    o_i_data_fifo_next_1 : out in_pulse;
    i_i_data_fifo_empty_2 : in out_ready;
    o_i_data_fifo_next_2 : out in_pulse;
    i_i_data_fifo_empty_3 : in out_ready;
    o_i_data_fifo_next_3 : out in_pulse;
    i_i_data_fifo_empty_4 : in out_ready;
    o_i_data_fifo_next_4 : out in_pulse;
    i_i_data_fifo_empty_5 : in out_ready;
    o_i_data_fifo_next_5 : out in_pulse;
    i_i_data_fifo_empty_6 : in out_ready;
    o_i_data_fifo_next_6 : out in_pulse;
    i_i_data_fifo_empty_7 : in out_ready;
    o_i_data_fifo_next_7 : out in_pulse;
    o_o_data_fifo_data : out data_bus;
    i_o_data_fifo_ready : in out_ready;
    o_o_data_fifo_next : out in_pulse;
    i_i_info_fifo_data_X : in info_bus;
    i_i_info_fifo_data_0 : in info_bus;
    i_i_info_fifo_data_1 : in info_bus;
    i_i_info_fifo_data_2 : in info_bus;
    i_i_info_fifo_data_3 : in info_bus;
    i_i_info_fifo_data_4 : in info_bus;
    i_i_info_fifo_data_5 : in info_bus;
    i_i_info_fifo_data_6 : in info_bus;
    i_i_info_fifo_data_7 : in info_bus;
    i_i_info_fifo_empty_X : in out_ready;
    o_i_info_fifo_next_X : out in_pulse;
    i_i_info_fifo_empty_0 : in out_ready;
    o_i_info_fifo_next_0 : out in_pulse;
    i_i_info_fifo_empty_1 : in out_ready;
    o_i_info_fifo_next_1 : out in_pulse;
    i_i_info_fifo_empty_2 : in out_ready;
    o_i_info_fifo_next_2 : out in_pulse;
    i_i_info_fifo_empty_3 : in out_ready;
    o_i_info_fifo_next_3 : out in_pulse;
    i_i_info_fifo_empty_4 : in out_ready;
    o_i_info_fifo_next_4 : out in_pulse;
    i_i_info_fifo_empty_5 : in out_ready;
    o_i_info_fifo_next_5 : out in_pulse;
    i_i_info_fifo_empty_6 : in out_ready;
    o_i_info_fifo_next_6 : out in_pulse;
    i_i_info_fifo_empty_7 : in out_ready;
    o_i_info_fifo_next_7 : out in_pulse;
    o_o_info_fifo_data : out info_bus;
    i_o_info_fifo_ready : in out_ready;
    o_o_info_fifo_next : out in_pulse
  );
end component;

component i2c_module
  generic (
    ID : std_logic_vector(2 downto 0);
    GEN_TYPE : string
  );
  port (
    i_clk : in std_logic;
    i_rst_n : in std_logic;
    i_en : in std_logic;
    i_i_info_write : in std_logic;
    i_i_info_data : in info_bus;
    i_o_info_full : out std_logic;
    i_i_data_write : in std_logic;
    i_i_data_data : in data_bus;
    i_o_data_full : out std_logic;
    o_i_info_next : in std_logic;
    o_o_info_data : out info_bus;
    o_o_info_empty : out std_logic;
    o_i_data_next : in std_logic;
    o_o_data_data : out data_bus;
    o_o_data_empty : out std_logic;
    scl : inout std_logic;
    sda : inout std_logic;
    i_interrupt : in std_logic;
    o_interrupt : out std_logic
  );
end component;

component i2c_driver
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    scl : in std_logic;
    sda : in std_logic;
    o_scl : out std_logic;
    o_sda : out std_logic;
    i_data_vld : in std_logic;
    i_data : in data_bus;
    i_recieve : in std_logic;
    o_data_vld : out std_logic;
    o_data : out data_bus;
    i_ignore : in std_logic;
    o_no_ack : out std_logic;
    clk_div : in std_logic_vector(MSG_W * 2 - 1 downto 0);
    i_slv_addr : in std_logic_vector(6 downto 0);
    i_en_slave : in std_logic;
    o_busy : out std_logic;
    o_running : out std_logic
  );
end component;

component i2c_ctrl
  generic (
    MY_ID : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0);
    INTERNAL_I2C : boolean
  );
  port (
    clk : in std_logic;
    i_rst_n : in std_logic;
    i_en : in std_logic;
    i_i_data_fifo_data : in data_bus;
    i_i_data_fifo_empty : in out_ready;
    o_i_data_fifo_next : out in_pulse;
    o_o_data_fifo_data : out data_bus;
    i_o_data_fifo_full : in out_ready;
    o_o_data_fifo_next : out in_pulse;
    i_i_info_fifo_data : in info_bus;
    i_i_info_fifo_empty : in out_ready;
    o_i_info_fifo_next : out in_pulse;
    o_o_info_fifo_data : out info_bus;
    i_o_info_fifo_full : in out_ready;
    o_o_info_fifo_next : out in_pulse;
    scl : inout std_logic;
    sda : inout std_logic;
    o_scl : out std_logic;
    o_sda : out std_logic;
    i_interrupt : in std_logic;
    o_interrupt : out std_logic
  );
end component;

component FIFO_wrapper
  generic (
    g_WIDTH : natural;
    g_DEPTH : integer;
    GEN_TYPE : string
  );
  port (
    i_rst_sync : in std_logic;
    i_clk : in std_logic;
    i_wr_en : in std_logic;
    i_wr_data : in std_logic_vector(g_WIDTH-1 downto 0);
    o_full : out std_logic;
    i_rd_en : in std_logic;
    o_rd_data : out std_logic_vector(g_WIDTH-1 downto 0);
    o_empty : out std_logic
  );
end component;

  end package;