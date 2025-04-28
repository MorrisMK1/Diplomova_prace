library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FIFO_wrapper is
  generic (
    g_WIDTH : natural := 8;
    g_DEPTH : integer := 32;
    GEN_TYPE: string  := "DEFAULT" --NOTE - types: "DEFAULT", "XILINX"
    );
  port (
    i_rst_sync : in std_logic;
    i_clk      : in std_logic;

    -- FIFO Write Interface
    i_wr_en   : in  std_logic;
    i_wr_data : in  std_logic_vector(g_WIDTH-1 downto 0);
    o_full    : out std_logic;

    -- FIFO Read Interface
    i_rd_en   : in  std_logic;
    o_rd_data : out std_logic_vector(g_WIDTH-1 downto 0);
    o_empty   : out std_logic
    );
end FIFO_wrapper;

architecture rtl of FIFO_wrapper is

begin

  g_fifo_type : if (GEN_TYPE = "DEFAULT") generate
    module_fifo : entity work.module_fifo_regs_no_flags
    generic map (
      g_WIDTH => g_WIDTH,
      g_DEPTH => g_DEPTH
    )
    port map (
      i_rst_sync => i_rst_sync,
      i_clk => i_clk,
      i_wr_en => i_wr_en,
      i_wr_data => i_wr_data,
      o_full => o_full,
      i_rd_en => i_rd_en,
      o_rd_data => o_rd_data,
      o_empty => o_empty
    );
  elsif (GEN_TYPE = "XILINX" and g_WIDTH = 8) generate   --NOTE - xilinx cases might need to be commented in sim to let it run
    module_fifo : entity work.fifo_generator_8b
      PORT MAP (
        clk   => i_clk,
        rst  => i_rst_sync,
        din   => i_wr_data,
        wr_en => i_wr_en,
        rd_en => i_rd_en,
        dout  => o_rd_data,
        full  => o_full,
        empty => o_empty
      );
  elsif (GEN_TYPE = "XILINX" and g_WIDTH = 24) generate
    module_fifo : entity work.fifo_generator_24b
      PORT MAP (
        clk   => i_clk,
        srst  => i_rst_sync,
        din   => i_wr_data,
        wr_en => i_wr_en,
        rd_en => i_rd_en,
        dout  => o_rd_data,
        full  => o_full,
        empty => o_empty
      );
  else generate
      p_err : process (i_clk)
    begin
      report "GENERATION FAILIURE: XILINX FIFO NOT IMPLEMENTED " severity failure;
    end process;
  end generate;
end architecture;