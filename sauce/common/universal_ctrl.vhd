
library ieee;
  use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
library work;
use work.my_common.all;

----------------------------------------------------------------------------------------
-- #ANCHOR - ENTITY
----------------------------------------------------------------------------------------
entity universal_ctrl is
  generic (
    constant  MSG_W         : natural := 8;             -- message width
    constant  SMPL_W        : natural := 8;             -- rx line sample width
    constant  START_OFFSET  : natural := 10;            -- offset in clks between start and first bit
    constant  BUS_MODE      : t_bus_type := t_bus_UART  -- type of bus
  );
  port (
    i_clk                   : in  std_logic;
    i_rst_n                 : in  std_logic;
    
    i_data                  : inout fifo_bus;         -- input bus from fifo

    o_data                  : inout fifo_bus;         -- output bus to fifo

    cfg                     : inout cfg_bus;          -- configuration bus

    info_bus                : inout info_bus;         -- information bus

    comm_wire_0             : inout std_logic := 'Z';
    comm_wire_1             : inout std_logic := 'Z';
    SPI_device_sel          : out STD_LOGIC_VECTOR(MSG_W-1 downto 0) := (others => 'Z')
  );
end universal_ctrl;

----------------------------------------------------------------------------------------
--#SECTION - ARCHITECTURE
----------------------------------------------------------------------------------------
architecture behavioral of universal_ctrl is
  signal r_registers    : std_logic_array (1 to 3) (MSG_W-1 downto 0);
  signal flags          : std_logic_vector(MSG_W-1 downto 0);
  signal msg_i_vld      : std_logic;
  signal msg_o_vld      : std_logic;
  signal msg_i_dat      : STD_LOGIC_VECTOR(MSG_W-1 downto 0);
  signal msg_o_dat      : STD_LOGIC_VECTOR(MSG_W-1 downto 0);
  signal msg_i_rdy      : std_logic;
  signal out_busy       : std_logic;
  signal clk_div        : std_logic_vector(11 downto 0);
  signal set_0          : std_logic;
  signal set_1          : std_logic;
  signal set_2          : std_logic;
begin


----------------------------------------------------------------------------------------
--#ANCHOR - Config manager
----------------------------------------------------------------------------------------
p_cfg_manager : process (i_clk)
  variable register_selection : natural range 0 to 3;
  variable data_to_reg          : std_logic_vector(MSG_W - 1 downto 0);
begin
  if rising_edge(i_clk) then
    if (i_rst_n = '0') then
      for i in 1 to 3 loop
        r_registers(i) <= (others => '0');
      end loop;
    else
      register_selection := natural(unsigned(cfg.register_select));
      if register_selection = 3 then
        data_to_reg := (others => '0');
      else
        data_to_reg := cfg.data_master;
      end if;
      if register_selection /= 0 then
        cfg.data_slave <= r_registers(register_selection);
        if cfg.slave_write_en = '1' then
          r_registers(register_selection) <= data_to_reg;
        end if;
      else
        cfg.data_slave <= (others => '0');
      end if;
    end if;
    for i in flags'range loop
      if flags(i) = '1' then
        r_registers(3)(i) <= '1';
      end if;
    end loop;
  end if;
end process p_cfg_manager;




----------------------------------------------------------------------------------------
--#SECTION - BUS CONTROLLER GENERATION
----------------------------------------------------------------------------------------
  g_interface : case BUS_MODE generate
----------------------------------------------------------------------------------------
--#ANCHOR - UART
----------------------------------------------------------------------------------------
    when t_bus_UART =>
    uart_rx_inst : entity work.uart_rx
    generic map (
      MSG_W => MSG_W,
      SMPL_W => SMPL_W,
      START_OFFSET => START_OFFSET
    )
    port map (
      i_clk => i_clk,
      i_rst_n => i_rst_n,
      i_rx => comm_wire_0,
      i_start_pol => set_1,
      i_par_en => set_0,
      i_par_type => set_2,
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
      i_clk => i_clk,
      i_rst_n => i_rst_n,
      i_msg => msg_i_dat,
      i_msg_vld  => msg_i_rdy,
      i_start_pol => set_1,
      i_par_en => set_0,
      i_par_type => set_2,
      i_clk_div => unsigned(clk_div),
      o_tx => comm_wire_1,
      o_busy => out_busy
    );
  
    when others =>
    
  end generate; --#!SECTION


end architecture; --#!SECTION