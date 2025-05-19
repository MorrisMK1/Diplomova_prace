
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
    o_CS                    : out std_logic_vector(7 downto 0);

    o_busy                  : out std_logic
  );
end entity SPI_ctrl;

architecture rtl of SPI_ctrl is

  constant MISO_DEB_BUFF_SIZE : natural := 7;
  signal clk_div : std_logic_vector((MSG_W * 2) - 1 downto 0);
  signal i_hold_active : std_logic;
  signal i_data : std_logic_vector(MSG_W - 1 downto 0);
  signal i_data_vld : std_logic;
  signal o_data_read : std_logic;
  signal i_data_recieve : std_logic;
  signal o_data : std_logic_vector(MSG_W - 1 downto 0);
  signal o_data_vld : std_logic;
  signal drv_busy : std_logic;

  type t_flow_ctrl_state is (
    st_flow_IDLE,
    st_flow_MS_START,
    st_flow_MS_REGISTER,
    st_flow_MS_TRANSFER_NEXT,
    st_flow_MS_TRANSFER_CHCK,
    st_flow_MS_HOLD,
    st_flow_MS_DELAY,
    st_flow_MS_DUMP,
    st_flow_MS_TERMINATE
  );

  signal st_flow : t_flow_ctrl_state;

      
  signal r_registers    : std_logic_array (1 to 3) (MSG_W-1 downto 0);
  alias  div_sel        : std_logic_vector (2 downto 0) is r_registers(1)(2 downto 0);
  alias  data_dir       : std_logic is r_registers(1)(3);
  alias  SPOL           : std_logic is r_registers(1)(4); -- invert polarity of chip select, 0 = 0 active
  alias  CPOL           : std_logic is r_registers(1)(5); -- invert polarity of BUS, 0 = 1 active
  alias  CPHA           : std_logic is r_registers(1)(6); -- set second edge as reading edge, 0 = first edge (for slave)
  alias  rst_r          : std_logic is r_registers(1)(7);
  alias  CHIP_SEL       : std_logic_vector (2 downto 0) is r_registers(2)(2 downto 0);

  signal flags          : std_logic_vector (MSG_W-1 downto 0);  -- what am I supposed to check here?
  --alias  frame_flg      : std_logic is flags(0);
  alias  reg_w_blck_flg : std_logic is flags(1);
  alias  data_ovf_flg   : std_logic is flags(3);
  --alias  info_ovf_flg   : std_logic is flags(4);
  --alias  disconnect_flg : std_logic is flags(5);
  --alias  blocked_flg    : std_logic is flags(6);
  alias  noise_flg      : std_logic is flags(7);

  signal en_rst         : std_logic;
  signal rst_n          : std_logic;
  signal clk_en         : std_logic;

  signal info_reg       : info_bus;
  signal info_ack       : std_logic;
  signal info_rdy       : std_logic;
  signal reg_op         : info_bus;
  signal reg_op_rdy_strb: std_logic;
  signal flag_rst       : std_logic;

  signal data_cnt_i     : natural range 0 to 255;
  signal data_cnt_o     : natural range 0 to 255;
  signal delay_cnt      : natural range 0 to 32767;

  signal MISO_in, MOSI_in, SCLK_in  : std_logic;

  
  attribute MARK_DEBUG : string;

  --attribute MARK_DEBUG of MOSI : signal is "TRUE";
  --attribute MARK_DEBUG of SCLK : signal is "TRUE";
  --attribute MARK_DEBUG of MISO_in : signal is "TRUE";
  --attribute MARK_DEBUG of o_CS : signal is "TRUE";

begin

  
  rst_n <= i_rst_n and not rst_r and not en_rst;
  clk_en <= clk_100MHz and i_en;

  MOSI <= MOSI_in ;--when (CPOL = '0') else not MOSI_in;
  SCLK <= SCLK_in when (CPOL = '0') else not SCLK_in;
  MISO_in <= MISO ;--when (CPOL = '0') else not MISO;
  o_busy <= '0' when (st_flow = st_flow_IDLE) else i_en;

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
--#ANCHOR - Controller
----------------------------------------------------------------------------------------
  p_controller : process(clk_en)
  begin
    if rising_edge(clk_en) then
      if (rst_n = '0') then
        o_CS <= (others => not SPOL);
        reg_op <= (others => '0') ;
        --frame_flg     <= '0';
        --data_ovf_flg  <= '0';
        --info_ovf_flg  <= '0';
        --disconnect_flg<= '0';
        --blocked_flg   <= '0';
        reg_w_blck_flg<= '0';
        flag_rst      <= '0';
        reg_op_rdy_strb <= '0';
        info_ack <= '0';
        o_o_info_fifo_next <= '0';
        o_i_info_fifo_next <= '0';
        o_o_data_fifo_next <= '0';
        o_i_data_fifo_next <= '0';
        i_data_vld <= '0';
        i_data_recieve <= '0';
        flag_rst <= '1';
        i_hold_active <= '0';
        st_flow <= st_flow_IDLE;

      else
        o_CS(to_integer(unsigned(CHIP_SEL))) <= SPOL;
        info_ack <= '0';
        i_data_vld <= '0';
        i_data_recieve <= '0';
        o_o_info_fifo_next <= '0';
        o_i_info_fifo_next <= '0';
        o_o_data_fifo_next <= '0';
        o_i_data_fifo_next <= '0';
        reg_w_blck_flg<= '0';
        --frame_flg     <= '0';
        data_ovf_flg  <= '0';
        --info_ovf_flg  <= '0';
        --disconnect_flg<= '0';
        --blocked_flg   <= '0';
        flag_rst      <= '0';
        reg_op_rdy_strb <= '0';
        flag_rst <= '0';
        case( st_flow ) is
          when st_flow_IDLE =>
            o_CS <= (others => not SPOL);
            if (i_i_info_fifo_empty = '0') then
              reg_op <= i_i_info_fifo_data;
              o_i_info_fifo_next <= '1';
              if (inf_reg(i_i_info_fifo_data) = "00") then
                delay_cnt <= to_integer(unsigned(clk_div((MSG_W * 2) - 1 downto 1)));
                st_flow <= st_flow_MS_START;
              else
                st_flow <= st_flow_MS_DELAY;
                reg_op_rdy_strb <= '1';
              end if ;
            end if ;

          when st_flow_MS_DELAY =>
            o_CS <= (others => not SPOL);
            st_flow <= st_flow_MS_REGISTER;

          when st_flow_MS_REGISTER =>
            o_CS <= (others => not SPOL);
            if(info_rdy = '1')then
              o_o_info_fifo_data <= info_reg;
              if (i_o_info_fifo_full = '0') then
                info_ack <= '1';
                o_o_info_fifo_next <= '1';
                st_flow <= st_flow_IDLE;
              end if;
            else
              st_flow <= st_flow_IDLE;
            end if;
            
          when st_flow_MS_START =>
            data_cnt_i <= 0;
            data_cnt_o <= 0;
            if (delay_cnt = 0) then
              st_flow <= st_flow_MS_TRANSFER_NEXT;
            else
              delay_cnt <= delay_cnt - 1;
            end if;
            
          when st_flow_MS_TRANSFER_NEXT =>
            i_hold_active <= '0';
            o_o_data_fifo_data <= o_data;
            i_data <= i_i_data_fifo_data;
            if (data_cnt_i /= reg_op(MSG_W * 2 - 1 downto MSG_W)) then
              i_data_vld <= '1';
            end if;
            if (o_data_read = '1') then
              o_i_data_fifo_next <= '1';
              data_cnt_i <= data_cnt_i + 1;
            end if;
            if (data_cnt_o /= reg_op(MSG_W - 1 downto 0)) then
              i_data_recieve <= '1';
            end if;
            if(o_data_vld = '1') then
              if (i_o_data_fifo_full = '1') then
                data_ovf_flg <= '1';
                st_flow <= st_flow_MS_DUMP;
              else
                o_o_data_fifo_next <= '1';
                data_cnt_o <= data_cnt_o + 1;
              end if;
            end if;
            if((data_cnt_i = reg_op(MSG_W * 2 - 1 downto MSG_W)) and (data_cnt_o = reg_op(MSG_W - 1 downto 0))) then
              st_flow <= st_flow_MS_TRANSFER_CHCK;
            end if;
            
          when st_flow_MS_TRANSFER_CHCK =>
            --i_hold_active <= reg_op(MSG_W * 2 + 5);
            if (drv_busy = '0') then
              if (reg_op(MSG_W * 2 + 5) = '1') then
                st_flow <= st_flow_MS_HOLD;
              else
                if ((data_cnt_o /= 0) or ( r_registers(3) /= x"00" )) then
                  o_o_info_fifo_data <= reg_op(MSG_W * 3 - 1 downto MSG_W * 2) & std_logic_vector(to_unsigned(data_cnt_o,MSG_W)) & r_registers(3);
                  o_o_info_fifo_next <= '1';
                end if;
                i_data_recieve <= '0';
                i_data_vld <= '0';
                st_flow <= st_flow_IDLE;
              end if ;
            end if;
            
          when st_flow_MS_HOLD =>
            i_hold_active <= '1';
            if (i_i_info_fifo_empty = '0') then
              reg_op <= i_i_info_fifo_data;
              o_i_info_fifo_next <= '1';
              if (inf_reg(i_i_info_fifo_data) = "00") then
                st_flow <= st_flow_MS_START;
              else
                reg_w_blck_flg <= '1';
              end if ;
            end if ;
            if (unsigned(r_registers(3)) /= 0 ) then
              o_o_info_fifo_data <= reg_op(MSG_W * 3 - 1 downto MSG_W * 2) & x"00" & r_registers(3);
              o_o_info_fifo_next <= '1';
              flag_rst <= '1';
              reg_w_blck_flg <= '0';
            end if;

          when st_flow_MS_DUMP =>
            if (data_cnt_o = reg_op(MSG_W - 1 downto 0)) then
              st_flow <= st_flow_MS_TERMINATE;
            else
              o_i_data_fifo_next <= '1';
              data_cnt_i <= data_cnt_i + 1;
            end if;
            
          when st_flow_MS_TERMINATE =>
            i_hold_active <= '0';
            if (drv_busy = '0') then
              st_flow <= st_flow_IDLE;
            end if;
            
          when others =>
            st_flow <= st_flow_IDLE;
            
        end case ;
      end if;
      
    end if;
  end process;

----------------------------------------------------------------------------------------
--#ANCHOR - Divider select
----------------------------------------------------------------------------------------
p_clk_div_sel : process (div_sel)
begin
  case( to_integer(unsigned(div_sel)) ) is  -- dividers for clk = 100 MHz
    when 0 =>             -- 20 Kbps
      clk_div <= x"1388";
    when 1 =>             -- 50 Kbps
      clk_div <= x"07D0";
    when 2 =>             -- 100 Kbps
      clk_div <= x"03E8";
    when 3 =>             -- 200 Kbps
      clk_div <= x"01F4";
    when 4 =>             -- 400 Kbps
      clk_div <= x"00FA";
    when 5 =>             -- 1 Mbps
      clk_div <= x"0064";
    when 6 =>             -- 2 Mbps
      clk_div <= x"0032";
    when 7 =>             -- 4 Mbps
      clk_div <= x"0019";
    when others =>
      clk_div <= x"1388";
  end case ;
end process;


----------------------------------------------------------------------------------------
--#ANCHOR - Driver
----------------------------------------------------------------------------------------

  SPI_driver_inst : entity work.SPI_driver
  generic map (
    MISO_DEB_BUFF_SIZE => MISO_DEB_BUFF_SIZE
  )
  port map (
    clk_100MHz => clk_en,
    rst_n => rst_n,
    i_clk_div => clk_div,
    i_hold_active => i_hold_active,
    i_data_dir => not data_dir,
    i_CPHA => CPHA,
    i_data => i_data,
    i_data_vld => i_data_vld,
    o_data_read => o_data_read,
    i_data_recieve => i_data_recieve,
    o_data => o_data,
    o_data_vld => o_data_vld,
    o_busy => drv_busy,
    o_noise_flg => noise_flg,
    MISO => MISO_in,
    MOSI => MOSI_in,
    SCLK => SCLK_in
  );


end architecture;