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
        o_ack_ack   : out    std_logic;

        clk_div     : in     (MSG_W * 2 - 1 downto 0);
        i_en_slave  : in     std_logic;

        o_busy      : out    std_logic
    );
end entity i2c_driver;

architecture rtl of i2c_driver is

  
  type t_driver_state is (
    st_driver_IDLE,
    st_driver_START,
    st_driver_snd_msg, 
    st_driver_rec_vld, 
    st_driver_slv_ter0, 
    st_driver_rec_msg, 
    st_driver_snd_vld,
    st_driver_slv_ter1,
    st_driver_mst_ter,
    st_driver_TERMINATE,
    st_driver_WAIT
  );

  signal data_cnt : natural range MSG_W to 0;
  signal scl_timer_en : std_logic;
  signal scl_timer_mid: std_logic;

  signal slave_mode : std_logic;

  signal st_driver  : t_driver_state;

  signal send_trig  : std_logic;
  
  signal last_scl, last_sda : std_logic;

begin

  o_busy <= '0' when (st_driver = st_driver_IDLE or st_driver = st_driver_rec_vld or st_driver = st_driver_snd_vld) else '1';
  
  send_trig <= '1' when ((scl_timer_mid = '1') and (slave_mode = '0') and (scl = '0')) or ((slave_mode = '1') and (scl = '1') and (last_scl = '0')) else '0';

  p_scl_timer : process (clk)
    variable measure  : natural range 0 to 65536;
    variable inner_scl  : std_logic;
  begin
    if (rising_edge(clk)) then
      if (rst_n = '0'or scl_timer_en = '0') then
        measure := 0;
        scl <= 'Z';
        scl_timer_mid <= '0';
        inner_scl <= '1';
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
          inner_scl <= '0';
          scl <= '0';
          else
          inner_scl <= '1';
          scl <= 'Z';
          end if;
        end if;
      end if;
    end if;
  end process;


  p_main : process (clk)
    variable msg : std_logic_vector(MSG_W-1 downto 0);
  begin
    if rising_edge(clk) then
      if (rst_n = '0') then   #FIXME - rewrite this stupid state machine
        data_cnt <= 0;
        st_driver <= st_driver_IDLE;
        msg := (others => '0');
        scl_timer_en <= '0';
        sda <= 'Z';
        last_scl <= '1';
        last_sda <= '1';
        slave_mode <= '0';
        o_ack_ack <= '0';
      else
        o_ack_ack <= '0';
        case(st_driver) is
          when st_driver_IDLE =>
            if (i_data_vld = '1' and scl = '1' and sda = '1') then
              msg := i_data;
              sda <= '0';
              scl_timer_en <= '1';
              slave_mode <= '0';
              st_driver <= st_driver_START;
            elsif (scl = '0' and sda = '0' and last_scl = '1' and last_sda = '0' and i_en_slave = '1') then
              scl_timer_en <= '0';
              slave_mode <= '1';
              st_driver <= st_driver_rec_msg;
            end if;
          when st_driver_START =>
            if (scl = '0') then
              st_driver <= st_driver_snd_msg;
              data_cnt <= 0;
            end if;
          when st_driver_snd_msg =>
            if (data_cnt < 8) then
              if (send_trig = '1') then
                if (msg(data_cnt) = '1') then
                  sda <= 'Z';
                else
                  sda <= '0';
                end if;
                data_cnt <= data_cnt + 1;
              end if;
            else
              st_driver <= st_driver_rec_vld;
            end if;
          when st_driver_rec_vld =>
            if (send_trig = '1') then
              if (sda = '0') then
                o_ack_ack <= '1';
                if (slave_mode = '1') then
                  if (i_data_vld = 1) then
                    msg := i_data;
                  else
                    msg := (others => '0');
                  end if;
                  st_driver <= st_driver_slv_ter0;
                else
                  if (i_recieve = '1') then
                    st_driver <= st_driver_rec_msg;
                  elsif (i_data_vld = '1') then
                    msg := i_data;
                    st_driver <= st_driver_snd_msg;
                  else
                    st_driver <= st_driver_TERMINATE;
                  end if;
                end if;
              else
              st_driver <= st_driver_IDLE;
              end if;
            end if;
          when st_driver_slv_ter0 =>

          
          when st_driver_rec_msg =>

          
          when st_driver_snd_vld =>

          
          when st_driver_slv_ter1 =>

          
          when st_driver_TERMINATE =>

          
          when st_driver_WAIT =>


          when others =>
            st_driver <= st_driver_IDLE;

        end case;
        
        last_scl <= scl;
        last_sda <= sda;
      end if;
    end if;
  end process;

end architecture;