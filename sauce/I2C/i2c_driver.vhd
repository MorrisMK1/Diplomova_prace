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
    st_driver_ms_snd_msg, 
    st_driver_ms_snd_ack,   -- means send routine acknowledgement step
    st_driver_ms_snd_ter,
    st_driver_ms_rec_msg, 
    st_driver_ms_rec_ack, 
    st_driver_ms_rec_ter,
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

  signal st_driver  : t_driver_state;
  
  signal last_scl, last_sda : std_logic;

begin

  p_scl_timer : process (clk) --ANCHOR - timer process
    variable measure  : natural range 0 to 65536;
    variable inner_scl  : std_logic;
  begin
    if (rising_edge(clk)) then
      if (rst_n = '0'or scl_timer_en = '0') then
        measure := 0;
        scl <= 'Z';
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
          scl <= '0';
          else
          inner_scl := '1';
          scl <= 'Z';
          end if;
        end if;
      end if;
    end if;
  end process;

  o_running <= '0' when (st_driver = st_driver_IDLE) else '1';

  p_main : process (clk) --ANCHOR - main process
    variable msg : std_logic_vector(MSG_W-1 downto 0);
  begin
    if rising_edge(clk) then
      if (rst_n = '0') then   
        data_cnt <= 0;
        st_driver <= st_driver_IDLE;
        msg := (others => '0');
        scl_timer_en <= '0';
        sda <= 'Z';
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
            if ((i_en_slave = '1') and (sda = '0') and (last_sda = '0') and (scl = '0') and (last_scl = '1')) then  --ANCHOR - start slave 
              st_driver <= st_driver_WAIT; --NOTE - switch to slave, now just wait until other comm passes
              data_cnt <= 0;
            elsif ((i_data_vld = '1')) then  --ANCHOR - start master
              msg := i_data;
              st_driver <= st_driver_ms_start;
              scl_timer_en <= '1';
              sda <= '0';
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
              if ((last_scl = '1') and (scl = '0')) then
                if (msg(7) = '1') then
                  sda <= 'Z';
                else
                  sda <= '0';
                end if;
                msg := msg(6 downto 0) & '0';
                data_cnt <= data_cnt + 1;
              end if;
            elsif ((last_scl = '1') and (scl = '0')) then
              sda <= 'Z';
              st_driver <= st_driver_ms_addr_ack;
              data_cnt <= 0;
            end if;

          when st_driver_ms_addr_ack    =>
            if ((scl_timer_mid = '1') and (scl /= '0')) then
              if (sda = '0') then
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
                st_driver <= st_driver_ms_snd_ter;
              end if;
            end if;

          when st_driver_ms_snd_msg     =>
            o_busy <= '1';
            if (data_cnt < 8) then
              if ((last_scl = '1') and (scl = '0')) then
                if (msg(7) = '1') then
                  sda <= 'Z';
                else
                  sda <= '0';
                end if;
                msg := msg(6 downto 0) & '0';
                data_cnt <= data_cnt + 1;
              end if;
            elsif ((scl = '0') and (last_scl = '1')) then
              sda <= 'Z';
              st_driver <= st_driver_ms_snd_ack;
              data_cnt <= 0;
            end if;

          when st_driver_ms_snd_ack     =>
          if ((scl_timer_mid = '1') and (scl /= '0')) then
            o_no_ack <= sda;
            st_driver <= st_driver_ms_snd_ter;
          end if;

          when st_driver_ms_rec_msg     =>
            o_busy <= '1';
            sda <= 'Z';
            if (data_cnt < 8) then
              if ((last_scl = '0') and (scl /= '0')) then
                if (sda = '0') then
                  msg := msg(6 downto 0) & '0';
                else
                  msg := msg(6 downto 0) & '1';
                end if;
                data_cnt <= data_cnt + 1;
              end if;
            else
              o_data <= msg;
              o_data_vld <= '1';
              st_driver <= st_driver_ms_rec_ack;
              data_cnt <= 0;
            end if;

          when st_driver_ms_rec_ack     =>  --FIXME - terminates on 7th bit
            if ((last_scl = '1')) then
              if (scl = '0') then
                if (i_recieve = '1') then
                  sda <= '0';
                else
                  sda <= 'Z';
                end if;
              else
                st_driver <= st_driver_ms_rec_ter;
              end if;
            end if;

          when st_driver_ms_rec_ter   =>
            sda <= '0';
            if ((i_recieve = '1') and (scl = '0')) then
              st_driver <= st_driver_ms_rec_msg;
              sda <= 'Z';
            elsif ((scl_timer_mid = '1') and (scl /= '0')) then
              sda<= 'Z';
              st_driver <= st_driver_IDLE;
            end if;

          when st_driver_ms_snd_ter   =>
            sda <= '0';
            if ((i_data_vld = '1') and (scl = '0')) then
              st_driver <= st_driver_ms_snd_msg;
              msg := i_data;
              sda <= 'Z';
            elsif ((scl_timer_mid = '1') and (scl /= '0')) then
              sda<= 'Z';
              st_driver <= st_driver_IDLE;
            end if; 

          when st_driver_sl_addr        =>

          when st_driver_sl_addr_ack    =>

          when st_driver_sl_snd_msg     =>

          when st_driver_sl_snd_ack     =>

          when st_driver_sl_snd_ter     =>

          when st_driver_sl_rec_msg     =>

          when st_driver_sl_rec_ack     =>

          when st_driver_sl_rec_ter     =>

          when st_driver_WAIT           =>
          if ((scl /= '0') and (last_scl = '1') and (sda /= '0') and (last_sda = '0')) then
            st_driver <= st_driver_IDLE;
          end if;

          when others =>
            st_driver <= st_driver_IDLE;

        end case;
        
        if (scl = '0') then
          last_scl <= '0';
        else
          last_scl <= '1';
        end if;
        if (sda = '0') then
          last_sda <= '0';
        else
          last_sda <= '1';
        end if;
      end if;
    end if;
  end process;

end architecture;