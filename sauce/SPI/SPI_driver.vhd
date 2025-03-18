

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.numeric_std_unsigned.all;


library work;
  use work.my_common.all;


entity SPI_driver is
  generic (
    MISO_DEB_BUFF_SIZE : natural := 8
  );
  port (
    clk_100MHz    : in  std_logic;
    rst_n         : in  std_logic;

    i_clk_div     : in  std_logic_vector((MSG_W * 2) - 1 downto 0);  -- divider for baud_gen
    i_hold_active : in  std_logic;   -- if no data given and no data requested the communication will not be terminated but put on hold
    i_data_dir    : in  std_logic;   -- 1 for MSB first

    i_data        : in  std_logic_vector(MSG_W - 1 downto 0);
    i_data_vld    : in  std_logic;
    o_data_read   : out std_logic;

    i_data_recieve: in  std_logic;   -- allow recieving data
    o_data        : out std_logic_vector(MSG_W - 1 downto 0);
    o_data_vld    : out std_logic;

    o_busy        : out std_logic;

    MISO          : in  std_logic;
    MOSI          : out std_logic;
    SCLK          : out std_logic
  );
end entity SPI_driver;

architecture rtl of SPI_driver is
  signal sclk_run, sclk_hold, sclk_mid  : std_logic;
  signal out_busy, in_busy: std_logic;
  signal MISO_stable  : std_logic;
  

    
begin

----------------------------------------------------------------------------------------
--ANCHOR - MISO debounce
----------------------------------------------------------------------------------------

  p_MISO_debounce : process(clk_100MHz)
    variable MISO_buffer  : std_logic_vector (MISO_DEB_BUFF_SIZE-1 downto 0);
    variable MISO_1_cnt   : natural range MISO_DEB_BUFF_SIZE downto 0;
  begin
    if rising_edge(clk_100MHZ) then
      if (rst_n = '0') then
        MISO_buffer := (others => '1');
      else
        MISO_1_cnt := 0;
        for i in 0 to MISO_DEB_BUFF_SIZE-1 loop
          if (MISO_buffer(i) = '1') then
            MISO_1_cnt := MISO_1_cnt + 1;
          end if;
        end loop;
        if (MISO_1_cnt > MISO_DEB_BUFF_SIZE/2) then
          MISO_stable <= '1';
        else
          MISO_stable <= '0';
        end if;
        MISO_buffer := MISO_buffer(MISO_DEB_BUFF_SIZE-2 downto 0) & MISO;
      end if;
    end if;

  end process;

----------------------------------------------------------------------------------------
--ANCHOR - SCLK generator
----------------------------------------------------------------------------------------

  p_sclk_gen : process(clk_100MHz)
    variable sclk_cnt : natural range 0 to 65535;
  begin
    if rising_edge(clk_100MHz) then
      if (rst_n = '0') then
        sclk_cnt := 0;
        SCLK <= '1';
        sclk_mid <= '0';
      else
        sclk_mid <= '0';
        if (sclk_run = '1') then
          if ((sclk_hold = '0') or (SCLK = '1')) then
            if (sclk_cnt < unsigned(i_clk_div)) then
              sclk_cnt := sclk_cnt + 1;
            else
              sclk_cnt := 0;
              SCLK <= '1' when (SCLK = '0') else '0';
            end if;
            if (sclk_cnt = unsigned(i_clk_div((MSG_W * 2) - 1 downto 1))) then
              sclk_mid <= '1';
            end if;
          else
            sclk_cnt := 0;
          end if;
        else
          SCLK <= '1';
          sclk_cnt := 0;
        end if;
      end if;
    end if;
  end process;

----------------------------------------------------------------------------------------
--ANCHOR - MOSI controller
----------------------------------------------------------------------------------------

  p_flow_ctrl_MOSI : process(clk_100MHz)    --TODO - finish this
    variable bits_to_snd  : natural range MSG_W-1 downto 0;
    variable data_to_snd  : std_logic_vector(MSG_W-1 downto 0);
  begin
    if rising_edge(clk_100MHz) then
      if (rst_n = '0') then
        bits_to_snd := 0;
      else
        if ((i_data_vld = '1') and (bits_to_snd = 0)) then
          if (i_data_dir = '1') then
            data_to_snd := i_data;  -- TODO - reverse this 
          else
            data_to_snd := i_data;
          end if;
          bits_to_snd := MSG_W - 1;
          o_data_read <= '0';
        else

        end if;
      end if;
    end if;
  
  end process;

end architecture;
