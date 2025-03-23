
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.numeric_std_unsigned.all;


library work;
  use work.my_common.all;


entity SPI_ctrl is
  generic (
    constant  SMPL_W        : natural := 8;             -- rx line sample width
    constant  START_OFFSET  : natural := 10;            -- offset in clks between start and first bit
    constant  MY_ID         : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0) := "000"
  );
  port (
    clk_100MHz              : in  std_logic;
    i_rst_n                 : in  std_logic;
    i_en                    : in  std_logic := '1';

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

    MISO                    : in  std_logic;
    MOSI                    : out std_logic;
    SCLK                    : out std_logic;
    o_interrupt             : out std_logic
  );
end entity SPI_ctrl;

architecture rtl of SPI_ctrl is

  constant MISO_DEB_BUFF_SIZE : natural := 5;
  signal i_clk_div : std_logic_vector((MSG_W * 2) - 1 downto 0);
  signal i_hold_active : std_logic;
  signal i_data_dir : std_logic;
  signal i_data : std_logic_vector(MSG_W - 1 downto 0);
  signal i_data_vld : std_logic;
  signal o_data_read : std_logic;
  signal i_data_recieve : std_logic;
  signal o_data : std_logic_vector(MSG_W - 1 downto 0);
  signal o_data_vld : std_logic;
  signal o_busy : std_logic;

  
  signal en_rst         : std_logic;
  signal rst_n          : std_logic;
  signal clk_en         : std_logic;

  signal info_reg       : info_bus;
  signal info_ack       : std_logic;
  signal info_rdy       : std_logic;
  signal reg_op         : info_bus;
  signal reg_op_rdy_strb: std_logic;
  signal flag_rst       : std_logic;

  signal r_registers    : std_logic_array (1 to 3) (MSG_W-1 downto 0);
  --alias  div_sel        : std_logic_vector (2 downto 0) is r_registers(1)(2 downto 0);
  --alias  interrupt_en   : std_logic is r_registers(1)(4);
  --alias  slave_mode     : std_logic is r_registers(1)(5);
  --alias  multimaster_en : std_logic is r_registers(1)(6);
  alias  rst_r          : std_logic is r_registers(1)(7);
  --alias  address        : std_logic_vector (6 downto 0) is r_registers(2)(6 downto 0);

  signal flags          : std_logic_vector (MSG_W-1 downto 0);
  --alias  frame_flg      : std_logic is flags(0);
  --alias  no_ack_flg     : std_logic is flags(1);
  --alias  data_size_flg  : std_logic is flags(2);
  --alias  data_ovf_flg   : std_logic is flags(3);
  --alias  info_ovf_flg   : std_logic is flags(4);
  --alias  disconnect_flg : std_logic is flags(5);
  --alias  blocked_flg    : std_logic is flags(6);
  --alias  noise_flg      : std_logic is flags(7);

begin

  rst_n <= i_rst_n and not rst_r and not en_rst;
  clk_en <= clk_100MHz and i_en;

----------------------------------------------------------------------------------------
--#ANCHOR - Auto reset after enable
----------------------------------------------------------------------------------------
--  generating reset pulse after enabling interface to ensure indentical start state
p_en_autorst  : process (clk_100MHz)
variable last_en    : std_logic;
begin
if rising_edge(clk_100MHz) then
if i_rst_n = '0' then
  en_rst <= '0';
elsif i_en = '0' then
  en_rst <= '1';
elsif last_en = i_en then
  en_rst <= '0';
end if;
last_en := i_en;
end if;
end process;
  
----------------------------------------------------------------------------------------
--#ANCHOR - Config manager
----------------------------------------------------------------------------------------
p_cfg_manager : process (clk_en)
variable register_selection : natural range 0 to 3;
begin
register_selection := to_integer(unsigned(inf_reg(reg_op)));
if rising_edge(clk_en) then 
  -- internal reset from registr should not reset registers
  if (i_rst_n = '0' or en_rst = '1') then
    for i in 1 to 3 loop
      r_registers(i) <= (others => '0');
    end loop;
    info_reg <= (others => '0');
    info_rdy <= '0';
  elsif (info_rdy = '0') then
    rst_r <= '0'; -- internal reset is only a strobe
    if reg_op_rdy_strb = '1' then
      if inf_ret(reg_op) = '0' and (inf_reg(reg_op)(0) xor inf_reg(reg_op)(1)) = '1' then
        r_registers(register_selection) <= inf_size(reg_op);
      end if;
      if inf_ret(reg_op) = '1' then
        info_reg <= inf_id(reg_op) & "0" & inf_reg(reg_op) & MY_ID & r_registers(register_selection) & x"00";
        info_rdy <= '1';
      end if;
      -- register 3 will be reset after every interaction
      if register_selection = 3 then
        r_registers(3) <= (others => '0') ;
      end if;
    end if;
  else
    if (info_ack = '1') then
      info_rdy <= '0';
    end if;
  end if;
  -- separate capturing of flags, they are strobed
  if flag_rst = '1' then
    r_registers(3) <= (others => '0');
  else
    for i in flags'range loop
      if flags(i) = '1' then
        r_registers(3)(i) <= '1';
      end if;
    end loop;
  end if;
end if;
end process p_cfg_manager;


----------------------------------------------------------------------------------------
--#ANCHOR - Driver
----------------------------------------------------------------------------------------
  SPI_driver_inst : entity work.SPI_driver
  generic map (
    MISO_DEB_BUFF_SIZE => MISO_DEB_BUFF_SIZE
  )
  port map (
    clk_100MHz => clk_100MHz,
    rst_n => i_rst_n,
    i_clk_div => i_clk_div,
    i_hold_active => i_hold_active,
    i_data_dir => i_data_dir,
    i_data => i_data,
    i_data_vld => i_data_vld,
    o_data_read => o_data_read,
    i_data_recieve => i_data_recieve,
    o_data => o_data,
    o_data_vld => o_data_vld,
    o_busy => o_busy,
    MISO => MISO,
    MOSI => MOSI,
    SCLK => SCLK
  );


end architecture;