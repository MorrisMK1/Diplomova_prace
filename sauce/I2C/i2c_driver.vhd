library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.std_logic_unsigned.all;

library work;
  use work.my_common.all;

----------------------------------------------------------------------------------------
-- #ANCHOR - ENTITY
----------------------------------------------------------------------------------------
entity i2c_driver is
    port (
        clk         : in std_logic;
        rst_n       : in std_logic;

        scl         : inout  std_logic;
        sda         : inout  std_logic;

        i_data_vld  : in     std_logic;
        i_data      : in     data_bus;
        i_recieve   : in     std_logic;
        o_data_vld  : out    std_logic;
        o_data      : out    data_bus;

        i_ignore    : in     std_logic;
        o_no_ack    : out    std_logic;

        clk_div     : in     std_logic_vector(MSG_W * 2 - 1 downto 0);
        i_slv_addr  : in     std_logic_vector(6 downto 0);
        i_en_slave  : in     std_logic;

        o_busy      : out    std_logic;
        o_running   : out    std_logic
    );
end entity i2c_driver;

architecture rtl of i2c_driver is

  
  type t_driver_state is (  --ANCHOR - driver states
    st_driver_IDLE,
    st_driver_ms_start,
    st_driver_ms_addr, 
    st_driver_ms_addr_ack, 
    st_driver_ms_addr_fail, 
    st_driver_ms_snd_msg, 
    st_driver_ms_snd_ack,   -- means send routine acknowledgement step
    st_driver_ms_snd_ter,
    st_driver_ms_rec_msg, 
    st_driver_ms_rec_ack, 
    st_driver_ms_rec_ter,
    st_driver_ms_ter_del,
    st_driver_ms_ter_del2,
    st_driver_sl_addr, 
    st_driver_sl_addr_ack, 
    st_driver_sl_snd_msg, 
    st_driver_sl_snd_ack, 
    st_driver_sl_snd_ter, 
    st_driver_sl_rec_msg, 
    st_driver_sl_rec_ack, 
    st_driver_sl_rec_ter, 
    st_driver_WAIT
  );

  signal data_cnt : natural range 0 to MSG_W;
  signal scl_timer_en : std_logic;
  signal scl_timer_mid: std_logic;
  signal scl_internal, scl_timer : std_logic;

  signal sda_output, sda_debnc : std_logic;

  signal st_driver  : t_driver_state;
  signal start_sig, stop_sig  : std_logic;
  
  signal last_scl, last_sda, fall_scl, rise_scl : std_logic;

begin
----------------------------------------------------------------------------------------
--#ANCHOR - SCL switch
----------------------------------------------------------------------------------------
  p_scl_switch : process(scl,scl_internal,scl_timer,scl_timer_en)
  begin
  if (scl_timer_en = '1')then
    scl_internal <= scl_timer;
    if (scl_timer = '1') then
      scl <= 'Z';
    else
      scl <= '0';
    end if;
  else
    if (scl = '0') then
      scl_internal <= '0';
    else
      scl_internal <= '1';
    end if;
  end if;
  end process;


----------------------------------------------------------------------------------------
--#ANCHOR - SCL timer
----------------------------------------------------------------------------------------
  p_scl_timer : process (clk)
    variable measure  : natural range 0 to 65536;
    variable inner_scl  : std_logic;
  begin
    if (rising_edge(clk)) then
      if (rst_n = '0'or scl_timer_en = '0') then
        measure := 0;
        scl_timer <= '1';
        scl_timer_mid <= '0';
        inner_scl := '1';
      else
        scl_timer_mid <= '0';
        if (measure < to_integer(unsigned(clk_div))) then
          if (measure = to_integer(unsigned(clk_div(MSG_W * 2 - 1 downto 1)))) then
            scl_timer_mid <= '1';
          end if;
          measure := measure + 1;
        else
          measure := 0;
          if (inner_scl = '1') then
          inner_scl := '0';
          scl_timer <= '0';
          else
          inner_scl := '1';
          scl_timer <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

----------------------------------------------------------------------------------------
--#ANCHOR - SDA Debouncer
----------------------------------------------------------------------------------------
p_sda_deb : process (clk)
  variable SDA_buf    : std_logic_vector (2 downto 0);
  variable sda_1_cnt  : natural range 3 downto 0;
begin
  if rising_edge(clk) then
    if (rst_n = '0') then
      SDA_buf := (others => '1') ;
    else
      sda_1_cnt := 0;
      for i in 2 downto 0 loop
        if (SDA_buf(i) = '1') then
          sda_1_cnt := sda_1_cnt + 1;
        end if;
      end loop;
      if (sda_1_cnt > 1) then
        sda_debnc <= '1';
      else
        sda_debnc <= '0';
      end if;
      if (sda = '0') then
        SDA_buf := SDA_buf(1 downto 0) & "0";
      else
        SDA_buf := SDA_buf(1 downto 0) & "1";
      end if;
    end if;
  end if;
end process;

  sda <= 'Z' when (sda_output = '1') else '0';
  fall_scl  <= '1' when ((last_scl = '1') and (scl_internal = '0')) else '0';
  rise_scl  <= '1' when ((last_scl = '0') and (scl_internal = '1')) else '0';
  start_sig <= '1' when ((i_en_slave = '1') and (sda_debnc = '0') and (last_sda = '1') and (scl_internal = '1') and (last_scl = '1')) else '0';
  stop_sig  <= '1' when ((scl_internal = '1') and (last_scl = '1') and (sda_debnc = '1') and (last_sda = '0')) else '0';
  o_running <= '0' when (st_driver = st_driver_IDLE) else '1';
----------------------------------------------------------------------------------------
--#ANCHOR - main process
----------------------------------------------------------------------------------------
  p_main : process (clk) 
    variable msg : std_logic_vector(MSG_W-1 downto 0);
  begin
    if rising_edge(clk) then
      if (rst_n = '0') then   
        data_cnt <= 0;
        st_driver <= st_driver_IDLE;
        msg := (others => '0');
        scl_timer_en <= '0';
        sda_output <= '1';
        last_scl <= '1';
        last_sda <= '1';
        o_no_ack <= '0';
        o_data <= (others => '0');
      else
        o_no_ack <= '0';
        o_busy <= '0';
        o_data_vld <= '0';
        case(st_driver) is

          when st_driver_IDLE           =>
            scl_timer_en <= '0';
            msg := (others => '0');
            if (start_sig = '1') then  --ANCHOR - start slave 
              st_driver <= st_driver_sl_addr;
              data_cnt <= 0;
            elsif ((i_data_vld = '1')) then  --ANCHOR - start master
              msg := i_data;
              st_driver <= st_driver_ms_start;
              scl_timer_en <= '1';
              sda_output <= '0';
              data_cnt <= 0;
            end if;
          
          when st_driver_ms_start       =>
            o_busy <= '1';
            if ((scl_timer_mid = '1')) then
              st_driver <= st_driver_ms_addr;
            end if;
          when st_driver_ms_addr        =>
            o_busy <= '1';
            if (data_cnt < 8) then
              if (fall_scl = '1') then
                sda_output <= msg(7);
                msg := msg(6 downto 0) & '0';
                data_cnt <= data_cnt + 1;
              end if;
            elsif (fall_scl = '1') then
              sda_output <= '1';
              st_driver <= st_driver_ms_addr_ack;
              data_cnt <= 0;
            end if;

          when st_driver_ms_addr_ack    =>
            if (rise_scl = '1') then
              if (sda_debnc = '0') then
                if (i_recieve = '1') then
                  st_driver <= st_driver_ms_rec_msg;
                elsif (i_data_vld = '1') then
                  st_driver <= st_driver_ms_snd_msg;
                  msg := i_data;
                else
                  st_driver <= st_driver_ms_snd_ter;
                end if;
              else
                o_no_ack <= '1';
                st_driver <= st_driver_ms_addr_fail;
              end if;
            end if;

          when st_driver_ms_addr_fail =>
            st_driver <= st_driver_ms_snd_ter;

          when st_driver_ms_snd_msg     =>
            o_busy <= '1';
            if (data_cnt < 8) then
              if (fall_scl = '1') then
                sda_output <= msg(7);
                msg := msg(6 downto 0) & '0';
                data_cnt <= data_cnt + 1;
              end if;
            elsif (fall_scl = '1') then
              sda_output <= '1';
              st_driver <= st_driver_ms_snd_ack;
              data_cnt <= 0;
            end if;

          when st_driver_ms_snd_ack     =>
          if ((scl_timer_mid = '1') and (scl_internal /= '0')) then
            if (sda_debnc /= '0') then
              o_no_ack <= '1';
            else
              o_no_ack <= '0';
            end if;
            st_driver <= st_driver_ms_snd_ter;
          end if;

          when st_driver_ms_rec_msg     =>
            o_busy <= '1';
            sda_output <= '1';
            if (data_cnt < 8) then
              if (rise_scl = '1') then
                if (sda_debnc = '0') then
                  msg := msg(6 downto 0) & '0';
                else
                  msg := msg(6 downto 0) & '1';
                end if;
                data_cnt <= data_cnt + 1;
              end if;
            elsif (fall_scl = '1') then
              if (i_recieve = '1') then
                sda_output <= '0';
              else
                sda_output <= '1';
              end if;
              o_data <= msg;
              o_data_vld <= '1';
              st_driver <= st_driver_ms_rec_ack;
              data_cnt <= 0;
            end if;

          when st_driver_ms_rec_ack     =>
            if (scl_timer_mid = '1' and scl_internal /= '0') then
              st_driver <= st_driver_ms_rec_ter;
            end if;

          when st_driver_ms_rec_ter   =>
            sda_output <= '0';
            if ((i_recieve = '1') and (scl_internal = '0')) then
              st_driver <= st_driver_ms_rec_msg;
              sda_output <= '1';
            elsif ((scl_timer_mid = '1') and (scl_internal /= '0')) then
              sda_output <= '1';
              scl_timer_en <= '0';
              st_driver <= st_driver_ms_ter_del;
            end if;

          when st_driver_ms_snd_ter   =>
          sda_output <= '0';
            if ((i_data_vld = '1') and (scl_internal = '0')) then
              st_driver <= st_driver_ms_snd_msg;
              msg := i_data;
              sda_output <= '1';
            elsif ((scl_timer_mid = '1') and (scl_internal /= '0')) then
              sda_output <= '1';
              scl_timer_en <= '0';
              st_driver <= st_driver_ms_ter_del;
            end if; 

          when st_driver_ms_ter_del     =>
            scl_timer_en <= '1';
            sda_output <= '1';
            if (scl_timer_mid = '1') then
              scl_timer_en <= '0';
              st_driver <= st_driver_ms_ter_del2;
            end if;

          when st_driver_ms_ter_del2    =>
            scl_timer_en <= '1';
            sda_output <= '1';
            if (scl_timer_mid = '1') then
              st_driver <= st_driver_IDLE;
            end if;

          when st_driver_sl_addr        =>
            o_busy <= '1';
            sda_output <= '1';
            if (data_cnt < 8) then
              if (rise_scl = '1') then
                msg := msg(MSG_W-2 downto 0) & sda_debnc;
                data_cnt <= data_cnt + 1;
              end if;
            elsif (fall_scl = '1') then
                -- Check if the received address matches the slave's address
                if (msg(MSG_W-1 downto 1) = i_slv_addr) then
                  st_driver <= st_driver_sl_addr_ack;
                else
                  st_driver <= st_driver_WAIT;
                end if;
                data_cnt <= 0;
            end if;

          when st_driver_sl_addr_ack    =>
            if (msg(0) = '1') then --send
              if (i_data_vld = '1') then  
                sda_output <= '0';
              else  --fail
                sda_output <= '1';
              end if;
            else  -- recieve
              if (i_recieve = '1') then
                sda_output <= '0';
              else  --fail
                sda_output <= '1';
              end if;
            end if;

          when st_driver_sl_snd_msg     =>

          when st_driver_sl_snd_ack     =>

          when st_driver_sl_snd_ter     =>

          when st_driver_sl_rec_msg     =>

          when st_driver_sl_rec_ack     =>

          when st_driver_sl_rec_ter     =>

          when st_driver_WAIT           =>
          o_busy <= '1';
          if (stop_sig = '1') then
            st_driver <= st_driver_IDLE;
          end if;

          when others =>
            st_driver <= st_driver_IDLE;

        end case;
        
        if (scl_internal = '0') then
          last_scl <= '0';
        else
          last_scl <= '1';
        end if;
        if (sda_debnc = '0') then
          last_sda <= '0';
        else
          last_sda <= '1';
        end if;
      end if;
    end if;
  end process;

end architecture;