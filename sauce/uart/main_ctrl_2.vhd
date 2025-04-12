library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_unsigned.all;

library work;
  use work.my_common.all;

----------------------------------------------------------------------------------------
-- #ANCHOR - ENTITY
----------------------------------------------------------------------------------------

entity main_ctrl_2 is
  port (
    i_clk                   : in    std_logic;
    i_rst_n                 : in    std_logic;

    i_i_data_fifo_data      : in    data_bus;
    i_i_data_fifo_ready     : in    out_ready;
    o_i_data_fifo_next      : out   in_pulse;
    o_o_data_fifo_data      : out   data_bus;
    i_o_data_fifo_ready     : in    out_ready;
    o_o_data_fifo_next      : out   in_pulse;

    i_i_info_fifo_data      : in    info_bus;
    i_i_info_fifo_ready     : in    out_ready;
    o_i_info_fifo_next      : out   in_pulse;
    o_o_info_fifo_data      : out   info_bus;
    i_o_info_fifo_ready     : in    out_ready;
    o_o_info_fifo_next      : out   in_pulse;

    i_settings              : in    std_logic_array (1 to 2) (MSG_W-1 downto 0);
    o_ready                 : out   std_logic;

    tx                      : out std_logic;
    rx                      : in std_logic := 'Z'
  );
end entity;

architecture behavioral of main_ctrl_2 is

  type fsm_reciever is (
    st_reciever_idle,
    st_reciever_h_info,
    st_reciever_h_data,
    st_reciever_h_back,
    st_reciever_data,
    st_reciever_header
  );

  type fsm_sender is (
    st_sender_idle,
    st_sender_snd_head_1,
    st_sender_snd_head_2,
    st_sender_snd_head_3,
    st_sender_snd_data,
    st_sender_term
  );

  signal clk_div          : unsigned(15 downto 0);

  signal o_msg            : std_logic_vector(MSG_W - 1 downto 0);
  signal o_msg_vld_strb   : std_logic;
  signal o_busy_rx        : std_logic;

  signal i_msg            : std_logic_vector(MSG_W - 1 downto 0);
  signal i_msg_vld        : std_logic;
  signal o_busy_tx        : std_logic;

  signal timeout_s        : std_logic;
  signal timeout_rst      : std_logic;
  signal timeout_reg      : std_logic_vector(4 downto 0);

  signal flags_reg        : std_logic_vector(MSG_W-1 downto 0);
  signal flags            : std_logic_vector(MSG_W-1 downto 0);
  signal flag_rst         : std_logic;

  alias clk_div_sel       : std_logic_vector(2 downto 0) is i_settings(1)(2 downto 0);
  alias auto_flag_rep     : std_logic is i_settings(1)(3);
  alias parity_en         : std_logic is i_settings(1)(5);
  alias parity_odd        : std_logic is i_settings(1)(6);
  constant start_pol        : std_logic := '0';

  alias timeout_val       : std_logic_vector(4 downto 0) is i_settings(2)(4 downto 0);
  alias timeout_en        : std_logic is i_settings(2)(5);
  
  alias err_noise_strb    : std_logic is flags(7);
  alias err_frame_strb    : std_logic is flags(0);
  alias err_timeout_strb  : std_logic is flags(1);
  alias err_par_strb      : std_logic is flags(2);
  alias err_data_size_strb: std_logic is flags(3);
  alias err_msg_timeout   : std_logic is flags(5);

  
  attribute MARK_DEBUG : string;

  attribute MARK_DEBUG of o_i_data_fifo_next : signal is "TRUE";
  attribute MARK_DEBUG of o_i_info_fifo_next : signal is "TRUE";
  attribute MARK_DEBUG of i_i_info_fifo_ready : signal is "TRUE";
  attribute MARK_DEBUG of o_busy_tx : signal is "TRUE";
  attribute MARK_DEBUG of o_busy_rx : signal is "TRUE";

begin

----------------------------------------------------------------------------------------
--#ANCHOR - Flag management
----------------------------------------------------------------------------------------
  flag_p : process (i_clk)
  begin
    if rising_edge(i_clk) then
      if flag_rst = '1' then
        flags_reg <= (others => '0');
      else
        for i in flags'range loop
          if flags(i) = '1' then
            flags_reg(i) <= '1';
          end if;
        end loop;
      end if;
    end if;
  end process;
----------------------------------------------------------------------------------------
--#ANCHOR - Timeout counter
----------------------------------------------------------------------------------------
  p_timeout : process (i_clk)
    variable step : natural range 0 to 1048575;
    variable offset : unsigned(clk_div'length downto 0);
  begin
    -- timeout is counted from last recieved byte (if no bytes yet recieved it is timed by last send byte)
    if rising_edge (i_clk) then
      offset := ("0" & clk_div) when parity_en = '1' else (clk_div & "0");
      if ((to_integer(unsigned(timeout_val)) + 1 = timeout_reg)) then
        timeout_s <= '1';
      else
        timeout_s <= '0';
      end if;
      if ((timeout_rst = '1')or(o_busy_rx = '1')) then
        timeout_reg <= (others => '0');
        step := 0;
        timeout_s <= '0';
      elsif (timeout_s = '0') then
        step := step + 1;
      end if;
      if (step = (clk_div & "000" + offset)) then
        timeout_reg <= timeout_reg + 1; -- this way it will wait till all data is send before starting timeout on recieved data
        step := 0;
      end if;
    end if;
  end process;
----------------------------------------------------------------------------------------
--ANCHOR - Speed selection
----------------------------------------------------------------------------------------
p_clk_div_sel : process (clk_div_sel)
begin
  case( to_integer(unsigned(clk_div_sel)) ) is  -- dividers for clk = 100 MHz
    when 0 =>             -- 9600
      clk_div <= x"0412";
    when 1 =>             -- 19200
      clk_div <= x"0209";
    when 2 =>             -- 28800
      clk_div <= x"015B";
    when 3 =>             -- 57600
      clk_div <= x"00AE";
    when 4 =>             -- 76800
      clk_div <= x"0082";
    when 5 =>             -- 115200
      clk_div <= x"0057";
    when 6 =>             -- 460800
      clk_div <= x"0016";
    when 7 =>             -- 921600
      clk_div <= x"000B";
    when others =>
      clk_div <= x"0413";
  end case ;
end process;
----------------------------------------------------------------------------------------
--SECTION - Stream logic
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--ANCHOR - Data input logic
----------------------------------------------------------------------------------------
p_reciever : process (i_clk)
  variable st_reciever : fsm_reciever := st_reciever_idle;
  variable header      : info_bus;
  variable data_cnt    : unsigned(MSG_W - 1 downto 0);
  attribute MARK_DEBUG of st_reciever : variable is "TRUE";
begin
  if (rising_edge(i_clk)) then
    if (i_rst_n = '0') then
      err_data_size_strb <= '0';
      flag_rst <= '1';
      st_reciever := st_reciever_idle;
      o_o_info_fifo_data <= (others => '0');
      o_o_data_fifo_data <= (others => '0');
      header := (others => '0');
      o_ready <= '0';
      o_o_info_fifo_next <= '0';
      o_o_data_fifo_next <= '0';
      timeout_rst <= '1';
    else
      o_ready <= '1' when ((i_o_info_fifo_ready = '1') and (st_reciever = st_reciever_idle)) else '0';
      flag_rst <= '0';
      o_o_data_fifo_next <= '0';
      o_o_info_fifo_next <= '0';
      err_data_size_strb <= '0';
      err_msg_timeout <= '0';
      timeout_rst <= '0';
      if ((timeout_s = '1') and (st_reciever /= st_reciever_idle) and (st_reciever /= st_reciever_header)) then
        err_msg_timeout <= '1';
        st_reciever := st_reciever_header;
      end if;
      case( st_reciever ) is
        when st_reciever_idle =>
          header := (others => '0');
          data_cnt := to_unsigned(0,MSG_W);
          if o_busy_rx = '1' then
            st_reciever := st_reciever_h_info;
          end if;
        when st_reciever_h_info =>
          header := (o_msg & header(MSG_W * 2 - 1 downto 0));
          if o_msg_vld_strb = '1' then
            st_reciever := st_reciever_h_data;
          end if;
        when st_reciever_h_data =>
          header := (header(MSG_W * 3 - 1 downto MSG_W * 2) & o_msg & header(MSG_W * 1 - 1 downto 0));
          if (o_msg_vld_strb = '1') then
            st_reciever := st_reciever_h_back;
            if (inf_reg(header) = "00") then
              data_cnt := unsigned(header(MSG_W * 2 - 1 downto MSG_W * 1));
            else
              data_cnt := (others => '0');
            end if;
          end if;
        when st_reciever_h_back =>
          header := (header(MSG_W * 3 - 1 downto MSG_W * 1) & o_msg);
          if (o_msg_vld_strb = '1') then
            if (inf_reg(header) /= "00") then
              st_reciever := st_reciever_header;
            else
              st_reciever := st_reciever_data;
            end if;
          end if;
        when st_reciever_data =>
          o_o_data_fifo_data <= o_msg;
          if (o_msg_vld_strb = '1') then
            if (i_o_data_fifo_ready = '1') then
              o_o_data_fifo_next <= '1';
              data_cnt := data_cnt - 1;
            else
              st_reciever := st_reciever_header;
              err_data_size_strb <= '1';
            end if;
          end if;
          if (data_cnt < 1) then
            st_reciever := st_reciever_header;
          end if;
        when st_reciever_header =>
          if (i_o_info_fifo_ready = '1') then
            if (flags_reg /= x"00") then
              -- redirects output to main
              o_o_info_fifo_data <= (x"00" & std_logic_vector(unsigned(header(MSG_W * 2 - 1 downto MSG_W * 1)) - data_cnt) & flags_reg);
            elsif (data_cnt > 0) then
              -- redirects output to main
              o_o_info_fifo_data <= (header((MSG_W * 3 - 1) downto (MSG_W * 2 + 6)) & '0' & header(MSG_W * 2 + 4 downto MSG_W * 2 + 3) & "000" & std_logic_vector(unsigned(header(MSG_W * 2 - 1 downto MSG_W * 1)) - data_cnt) & flags_reg);
            else
              o_o_info_fifo_data <= header;
            end if;
            o_o_info_fifo_next <= '1';
            st_reciever := st_reciever_idle;
          end if;
        when others =>
          st_reciever := st_reciever_idle;
      end case ;
    end if;
  end if;
end process; 

----------------------------------------------------------------------------------------
--ANCHOR - Data output logic
----------------------------------------------------------------------------------------
  p_sender: process (i_clk)
    variable st_sender    : fsm_sender;
    variable data_cnt     : unsigned(MSG_W - 1 downto 0);
    variable header       : info_bus;
    variable last_out_st  : std_logic;
    
  attribute MARK_DEBUG of st_sender : variable is "TRUE";
  begin
    if rising_edge(i_clk) then
      if(i_rst_n = '0') then
        data_cnt := to_unsigned(0,MSG_W);
        st_sender := st_sender_idle;
        header := (others => '0') ;
        o_i_data_fifo_next <= '0';
        o_i_info_fifo_next <= '0';
        i_msg_vld <= '0';
      else
        o_i_data_fifo_next <= '0';
        o_i_info_fifo_next <= '0';
        i_msg_vld <= '0';
        case( st_sender ) is
          when st_sender_idle =>
            if (i_i_info_fifo_ready = '1') then
              i_msg_vld <= '1';
              last_out_st := '1';
              data_cnt := to_unsigned(0,MSG_W);
              header := i_i_info_fifo_data;
              i_msg <= i_i_info_fifo_data(MSG_W * 3 - 1 downto MSG_W * 2);
            end if;
            if(o_busy_tx = '1') then
              st_sender := st_sender_snd_head_1;
            end if;
          when st_sender_snd_head_1 =>
            if ((o_busy_tx = '0') and (last_out_st = '1')) then
              i_msg_vld <= '1';
              st_sender := st_sender_snd_head_2;
              i_msg <= header(MSG_W * 2 - 1 downto MSG_W * 1);
            end if;
          when st_sender_snd_head_2 =>
            if ((o_busy_tx = '0') and (last_out_st = '1')) then
              i_msg_vld <= '1';
              i_msg <= header(MSG_W * 1 - 1 downto MSG_W * 0);
              st_sender := st_sender_snd_head_3;
            end if;
          when st_sender_snd_head_3 =>
            if (o_busy_tx = '1') then
              st_sender := st_sender_snd_data;
              o_i_info_fifo_next <= '1';
            end if;
          when st_sender_snd_data =>
            if ((data_cnt < unsigned(header(MSG_W * 2 - 1 downto MSG_W * 1))) and (inf_reg(header) = "00")) then
              if (i_i_data_fifo_ready = '1') then
                i_msg <= i_i_data_fifo_data;
                if (o_busy_tx = '0' and last_out_st = '1') then
                  o_i_data_fifo_next <= '1';
                  data_cnt := data_cnt + 1;
                  i_msg_vld <= '1';
                end if;
              else -- this shouldnt be possible but oh well
                st_sender := st_sender_term;
              end if;
            elsif (o_busy_tx = '0') then
              st_sender := st_sender_term;
            end if;
          when st_sender_term =>
            st_sender := st_sender_idle;
          when others =>
            st_sender := st_sender_idle;
        end case ;
        last_out_st := o_busy_tx;
      end if;
    end if;
  end process;
--#!SECTION

----------------------------------------------------------------------------------------
--#SECTION - UART
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--ANCHOR - TX
----------------------------------------------------------------------------------------
  uart_tx_inst : entity work.uart_tx
  generic map (
    MSG_W => MSG_W,
    SMPL_W => SMPL_W
  )
  port map (
    i_clk => i_clk,
    i_rst_n => i_rst_n,
    i_msg => i_msg,
    i_msg_vld => i_msg_vld,
    i_start_pol => start_pol,
    i_par_en => parity_en,
    i_par_type => parity_odd,
    i_clk_div => clk_div,
    o_tx => tx,
    o_busy => o_busy_tx
  );
----------------------------------------------------------------------------------------
--ANCHOR - RX
----------------------------------------------------------------------------------------
uart_rx_inst : entity work.uart_rx
generic map (
  MSG_W => MSG_W,
  SMPL_W => SMPL_W,
  START_OFFSET => START_OFFSET
)
port map (
  i_clk => i_clk,
  i_rst_n => i_rst_n,
  i_rx => rx,
  i_start_pol => start_pol,
  i_par_en => parity_en,
  i_par_type => parity_odd,
  i_clk_div => clk_div,
  o_msg => o_msg,
  o_msg_vld_strb => o_msg_vld_strb,
  o_busy => o_busy_rx,
  o_err_noise_strb => err_noise_strb,
  o_err_frame_strb => err_frame_strb,
  o_err_par_strb => err_par_strb
);
--!SECTION

end architecture;







