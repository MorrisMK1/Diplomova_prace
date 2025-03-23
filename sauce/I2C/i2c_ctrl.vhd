library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_unsigned.all;

library work;
  use work.my_common.all;


  entity i2c_ctrl is
    generic (
      constant  SMPL_W        : natural := 8;             -- rx line sample width
      constant  START_OFFSET  : natural := 10;            -- offset in clks between start and first bit
      constant  MY_ID         : STD_LOGIC_VECTOR(BUS_ID_W-1 downto 0) := "000"
    );
    port (
      clk                     : in std_logic;
      i_rst_n                   : in std_logic;
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

      scl                     : inout std_logic := 'Z';
      sda                     : inout std_logic := 'Z';
      i_interrupt             : in  std_logic;
      o_interrupt             : out std_logic
    );
  end entity i2c_ctrl;
  
  architecture rtl of i2c_ctrl is
    signal i_data_vld : std_logic;
    signal i_data : data_bus;
    signal i_recieve : std_logic;
    signal o_data_vld : std_logic;
    signal o_data : data_bus;
    signal i_ignore : std_logic;
    signal o_no_ack : std_logic;
    signal clk_div : std_logic_vector(MSG_W * 2 - 1 downto 0);
    signal o_busy : std_logic;
    signal o_running : std_logic;

    
    signal r_registers    : std_logic_array (1 to 3) (MSG_W-1 downto 0);
    alias  div_sel        : std_logic_vector (2 downto 0) is r_registers(1)(2 downto 0);
    alias  interrupt_en   : std_logic is r_registers(1)(4);
    alias  slave_mode     : std_logic is r_registers(1)(5);
    alias  multimaster_en : std_logic is r_registers(1)(6);
    alias  rst_r          : std_logic is r_registers(1)(7);
    alias  address        : std_logic_vector (6 downto 0) is r_registers(2)(6 downto 0);

    signal flags          : std_logic_vector (MSG_W-1 downto 0);
    alias  frame_flg      : std_logic is flags(0);
    alias  no_ack_flg     : std_logic is flags(1);
    alias  data_size_flg  : std_logic is flags(2);
    alias  data_ovf_flg   : std_logic is flags(3);
    alias  info_ovf_flg   : std_logic is flags(4);
    alias  disconnect_flg : std_logic is flags(5);
    alias  blocked_flg    : std_logic is flags(6);
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

    signal data_cnt       : natural range 0 to 255;

    type t_flow_ctrl_state is (
      st_flow_IDLE,
      st_flow_MS_START,
      st_flow_MS_SND,
      st_flow_MS_REC,
      st_flow_MS_TER,
      st_flow_WAIT,
      st_flow_SL_ADR,
      st_flow_SL_SND,
      st_flow_SL_REC,
      st_flow_SL_TER,
      st_flow_PURGE,
      st_flow_REG_DELAY
    );
    
    signal st_flow_ctrl   : t_flow_ctrl_state;

    attribute MARK_DEBUG : string;

    attribute MARK_DEBUG of st_flow_ctrl : signal is "TRUE";
    attribute MARK_DEBUG of reg_op : signal is "TRUE";
  
  begin

    rst_n <= i_rst_n and not rst_r and not en_rst;
    clk_en <= clk and i_en;

----------------------------------------------------------------------------------------
--#ANCHOR - Auto reset after enable
----------------------------------------------------------------------------------------
--  generating reset pulse after enabling interface to ensure indentical start state
p_en_autorst  : process (clk)
variable last_en    : std_logic;
begin
if rising_edge(clk) then
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

p_flow_ctrl : process(clk_en) --TODO - finish this
  variable last_busy  : std_logic;
begin
  if rising_edge(clk_en) then
    if (rst_n = '0') then
      st_flow_ctrl <= st_flow_IDLE;
      reg_op_rdy_strb <= '0';
      o_i_info_fifo_next <= '0';
      i_data_vld <= '0';
      data_size_flg <= '0';
      o_i_data_fifo_next <= '0';
      i_recieve <= '0';
      data_ovf_flg <= '0';
      last_busy := '0';
      no_ack_flg <= '0';
      o_o_info_fifo_next <= '0';
      o_o_data_fifo_next <= '0';
      o_o_data_fifo_data <= (others => '0') ;
      o_o_info_fifo_data <= (others => '0') ;
      o_interrupt <= '0';
      disconnect_flg <= '0';
      frame_flg <= '0';
    else
      no_ack_flg <= '0';
      o_interrupt <= '0';
      disconnect_flg <= '0';
      o_o_info_fifo_next <= '0';
      o_o_data_fifo_next <= '0';
      data_ovf_flg <= '0';
      o_i_data_fifo_next <= '0';
      reg_op_rdy_strb <= '0';
      o_i_info_fifo_next <= '0';
      i_data_vld <= '0';
      data_size_flg <= '0';
      frame_flg <= '0';
      flag_rst <= '0';
      case st_flow_ctrl is
        when st_flow_IDLE =>
          data_cnt <= 0;
          flag_rst <= '1';
          if ((inf_reg(i_i_info_fifo_data) /= "00") and (i_i_info_fifo_empty = '0')) then -- register operation
            reg_op <= i_i_info_fifo_data;
            reg_op_rdy_strb <= '1';
            o_i_info_fifo_next <= '1';
            st_flow_ctrl <= st_flow_REG_DELAY;
          elsif ((slave_mode = '0') and (i_i_info_fifo_empty = '0') and (inf_reg(i_i_info_fifo_data) = "00")) then --ANCHOR - start as master
            reg_op <= i_i_info_fifo_data;
            st_flow_ctrl <= st_flow_MS_START;
            o_i_info_fifo_next <= '1';
          elsif ((o_running = '1')) then  --ANCHOR - start as slave
            st_flow_ctrl <= st_flow_SL_ADR;
          end if;

        when st_flow_MS_START =>
          if (to_integer(unsigned(inf_size(reg_op))) = 0) then
            data_size_flg <= '1';
            st_flow_ctrl <= st_flow_IDLE;
          elsif ((to_integer(unsigned(inf_size(reg_op))) > 1) and (to_integer(unsigned(reg_op(MSG_W-1 downto 0))) /= 0 ) ) then
            frame_flg <= '1';
            st_flow_ctrl <= st_flow_PURGE;
          else
            if (i_data = i_i_data_fifo_data) then
              i_data_vld <= '1';
            end if;
            i_data <= i_i_data_fifo_data;
            if (o_running = '1') then
              if(o_busy = '0') then
                if (o_no_ack = '1') then
                  disconnect_flg <= '1';
                  no_ack_flg <= '1';
                  st_flow_ctrl <= st_flow_PURGE;
                elsif (i_i_data_fifo_data(0) /= '0') then
                  o_i_data_fifo_next <= '1';
                  st_flow_ctrl <= st_flow_MS_REC;
                else
                  st_flow_ctrl <= st_flow_MS_SND;
                end if;
              end if;
            end if;
          end if;

        when st_flow_MS_REC =>
          i_recieve <= '1';
          o_o_data_fifo_data <= o_data;
          o_o_data_fifo_next <= o_data_vld;
          data_cnt <= data_cnt + 1 when (o_data_vld = '1') else data_cnt;
          if (data_cnt = to_integer(unsigned(reg_op(MSG_W - 1 downto 0)))) then
            st_flow_ctrl <= st_flow_MS_TER;
            i_recieve <= '0';
          elsif (i_o_data_fifo_full = '1') then
            st_flow_ctrl <= st_flow_MS_TER;
            i_recieve <= '0';
            data_ovf_flg <= '1';
          end if;

        when st_flow_MS_SND =>
          i_data_vld <= '1';
          i_data <= i_i_data_fifo_data;
          if (last_busy = '0' and o_busy = '1') then
            data_cnt <= data_cnt + 1;
            o_i_data_fifo_next <= '1';
          end if;
          if (data_cnt = to_integer(unsigned(inf_size(reg_op)))) then
            st_flow_ctrl <= st_flow_MS_TER;
            i_data_vld <= '0';
          elsif (i_i_data_fifo_empty = '1') then
            st_flow_ctrl <= st_flow_MS_TER;
            i_data_vld <= '0';
            data_size_flg <= '1';
          elsif (o_no_ack = '1') then
            st_flow_ctrl <= st_flow_MS_TER;
            i_data_vld <= '0';
            no_ack_flg <= '1';
          end if;

        when st_flow_MS_TER =>
          if (to_integer(unsigned(reg_op(MSG_W-1 downto 0))) /= 0) then
            o_o_info_fifo_data <= reg_op(3 * MSG_W - 1 downto MSG_W * 2) & std_logic_vector(to_unsigned(data_cnt,MSG_W)) & r_registers(3) ;
          elsif (to_integer(unsigned(flags)) /= 0) then
            o_o_info_fifo_data <= reg_op(3 * MSG_W - 1 downto MSG_W * 2) & std_logic_vector(to_unsigned(0,MSG_W)) & r_registers(3) ;
          end if;
          if (o_running = '0') then
            st_flow_ctrl <= st_flow_IDLE;
            if ((to_integer(unsigned(reg_op(MSG_W-1 downto 0))) /= 0) or (to_integer(unsigned(flags)) /= 0)) then
              o_o_info_fifo_next <= '1';
            end if;
          end if;

        when st_flow_PURGE =>
          if (data_cnt < to_integer(unsigned(inf_size(reg_op)))) then
            o_i_data_fifo_next <= '1';
            data_cnt <= data_cnt + 1;
          else
            st_flow_ctrl <= st_flow_MS_TER;
          end if;

      
        when others =>
          st_flow_ctrl <= st_flow_IDLE;
      end case;
      last_busy := o_busy;

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
    i2c_driver_inst : entity work.i2c_driver
  port map (
    clk => clk_en,
    rst_n => rst_n,
    scl => scl,
    sda => sda,
    i_data_vld => i_data_vld,
    i_data => i_data,
    i_recieve => i_recieve,
    o_data_vld => o_data_vld,
    o_data => o_data,
    i_ignore => i_ignore,
    o_no_ack => o_no_ack,
    clk_div => clk_div,
    i_en_slave => slave_mode,
    o_busy => o_busy,
    o_running => o_running
  );

  
  end architecture;