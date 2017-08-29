----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch) 
-- 
-- Copyright Notice/Copying Permission:
--    Copyright 2017 Christos Bakalis
--
--    This file is part of NTUA-BNL_VMM_firmware.
--
--    NTUA-BNL_VMM_firmware is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    NTUA-BNL_VMM_firmware is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with NTUA-BNL_VMM_firmware.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- Create Date: 20.04.2017 11:46:44
-- Design Name: Level-0 Deserializer/Decoder
-- Module Name: l0_deserializer_decoder - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: Implementation of data0/data1 sampling and deserialization, comma
-- character recognition, and 8b/10b decoding.
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 30.04.2017: Changed the way wr_en is asserted to comply with the halved wr_clk
-- of the vmm level-0 data buffer. (Christos Bakalis)
-- 20.06.2017: Removed pipeline. (Christos Bakalis)
-- 29.06.2017: Swapped clk_des with IDDR to ease timing closure. (Christos Bakalis)
-- 29.08.2017: Added wr_en counter. (Christos Bakalis)
--
----------------------------------------------------------------------------------
library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use work.StdRtlPkg.all;
use work.Code8b10bPkg.all;
use UNISIM.VComponents.all;

entity l0_deserializer_decoder is
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt    : in  std_logic; -- will be forwarded to the VMM
        level_0     : in  std_logic; -- level-0 signal
        ------------------------------------
        -------- Buffer Interface ----------
        inhib_wr    : in  std_logic;
        dout_dec    : out std_logic_vector(7 downto 0);
        commas_true : out std_logic;
        wr_en       : out std_logic;
        null_event  : out std_logic;
        ------------------------------------
        ---------- VMM Interface -----------
        vmm_data0   : in  std_logic;
        vmm_data1   : in  std_logic
    );
end l0_deserializer_decoder;

architecture RTL of l0_deserializer_decoder is

    component Decoder8b10b 
        generic (
            TPD_G          : time     := 1 ns;
            NUM_BYTES_G    : positive := 2;
            RST_POLARITY_G : sl       := '1';
            RST_ASYNC_G    : boolean  := false);
        port(
            clk      : in  sl;
            clkEn    : in  sl := '1';
            rst      : in  sl;
            dataIn   : in  slv(NUM_BYTES_G*10-1 downto 0);
            dataOut  : out slv(NUM_BYTES_G*8-1 downto 0);
            dataKOut : out slv(NUM_BYTES_G-1 downto 0);
            codeErr  : out slv(NUM_BYTES_G-1 downto 0);
            dispErr  : out slv(NUM_BYTES_G-1 downto 0)
        );
    end component;
    
    -- deserializing IDDR and Shift Register
    signal ddr_sreg             : std_logic_vector(11 downto 0) := (others => '0');
    signal data0_pos            : std_logic := '0';
    signal data0_neg            : std_logic := '0';
    signal data1_pos            : std_logic := '0';
    signal data1_neg            : std_logic := '0';
    signal ddr_buff             : std_logic_vector(3 downto 0)  := (others => '0');

    -- alignment logic
    constant comma_p            : std_logic_vector(9 downto 0) := "0101111100";
    constant comma_n            : std_logic_vector(9 downto 0) := "1010000011";
    type word10b_2array_type is array (0 to 2) of std_logic_vector(9 downto 0); -- 2 words of 10bit
    signal word10b_align_array, word10b_align_array_r : word10b_2array_type;
    signal comma_valid_bits_p   : std_logic_vector(2 downto 0) := (others => '0');
    signal comma_valid_bits_n   : std_logic_vector(2 downto 0) := (others => '0');
    signal comma_valid_p        : std_logic := '0';
    signal comma_valid_n        : std_logic := '0';
    signal align_sreg_p         : std_logic_vector(4 downto 0) := (others => '0');
    signal align_sreg_n         : std_logic_vector(4 downto 0) := (others => '0');

    -- word selection logic and decoder
    signal pos_p                : std_logic_vector(2 downto 0) := (others => '0');
    signal pos_n                : std_logic_vector(2 downto 0) := (others => '0');
    signal align_select         : std_logic_vector(2 downto 0) := (others => '0');
    signal word10b_rdy          : std_logic := '0';
    signal align_sel_p          : std_logic := '0';
    signal align_sel_n          : std_logic := '0';
    signal dec_en               : std_logic := '0';
    signal L0_8B_data           : std_logic_vector(7 downto 0) := (others => '0');
    signal L0_8B_data_i         : std_logic_vector(7 downto 0) := (others => '0');
    signal L0_8B_K              : std_logic_vector(0 downto 0) := (others => '0');
    signal din_dec              : std_logic_vector(9 downto 0) := (others => '0');
    signal wr_en_i              : std_logic := '0';

    -- comma counter and wr_en counter
    signal cnt_commas           : unsigned(4 downto 0) := (others => '0');
    signal cnt_wr_en            : unsigned(1 downto 0) := (others => '0');
    constant cnt_thr            : unsigned(4 downto 0) := "11111"; -- 6 consecutive commas              

begin

------------------------------------------
-------- DDR and Shift Register ----------
------------------------------------------

IDDR_inst_data0: IDDR
    generic map (
        DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE", "SAME_EDGE" or "SAME_EDGE_PIPELINED"
        INIT_Q1      => '0', -- Initial value of Q1: '0' or '1'
        INIT_Q2      => '0', -- Initial value of Q2: '0' or '1'
        SRTYPE       => "SYNC") -- Set/Reset type: "SYNC" or "ASYNC"
    port map (
        Q1  => data0_pos,   -- 1-bit output for positive edge of clock
        Q2  => data0_neg,   -- 1-bit output for negative edge of clock
        C   => clk_ckdt,    -- 1-bit clock input
        CE  => '1',         -- 1-bit clock enable input
        D   => vmm_data0,   -- 1-bit DDR data input
        R   => '0',         -- 1-bit reset
        S   => '0'          -- 1-bit set
);

IDDR_inst_data1: IDDR
    generic map (
        DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE", "SAME_EDGE" or "SAME_EDGE_PIPELINED"
        INIT_Q1      => '0', -- Initial value of Q1: '0' or '1'
        INIT_Q2      => '0', -- Initial value of Q2: '0' or '1'
        SRTYPE       => "SYNC") -- Set/Reset type: "SYNC" or "ASYNC"
    port map (
        Q1  => data1_pos,   -- 1-bit output for positive edge of clock
        Q2  => data1_neg,   -- 1-bit output for negative edge of clock
        C   => clk_ckdt,    -- 1-bit clock input
        CE  => '1',         -- 1-bit clock enable input
        D   => vmm_data1,   -- 1-bit DDR data input
        R   => '0',         -- 1-bit reset
        S   => '0'          -- 1-bit set
);

sreg_proc: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        ddr_buff(3) <= data0_pos;
        ddr_buff(2) <= data1_pos;
        ddr_buff(1) <= data0_neg;
        ddr_buff(0) <= data1_neg;
        ddr_sreg    <= ddr_buff & ddr_sreg(11 downto 4);   
    end if;
end process;
------------------------------------------


------------------------------------------
-------- Alignment Logic -----------------
------------------------------------------
--- 10 bit array 
input_map:  for I in 0 to 2 generate -- 1 10bit-word per alignment, 2 possible alignments
word10b_align_array(I) <= ddr_sreg(I+9)&ddr_sreg(I+8)&ddr_sreg(I+7)&ddr_sreg(I+6)&ddr_sreg(I+5)&
                          ddr_sreg(I+4)&ddr_sreg(I+3)&ddr_sreg(I+2)&ddr_sreg(I+1)&ddr_sreg(I+0);   -- 10 bit word, alligned to bit I
end generate input_map;

comma_test_p:  for I in 0 to 2 generate -- 1 10bit-word per alignment, comma is valid if two first words have comma...
comma_valid_bits_p(I) <=  '1' when (word10b_align_array(I) = comma_p) else '0';
end generate comma_test_p;

comma_test_n:  for I in 0 to 2 generate -- 1 10bit-word per alignment, comma is valid if two first words have comma...
comma_valid_bits_n(I) <=  '1' when (word10b_align_array(I) = comma_n) else '0';
end generate comma_test_n;

comma_valid_p <= comma_valid_bits_p(2) or comma_valid_bits_p(1) or comma_valid_bits_p(0);
comma_valid_n <= comma_valid_bits_n(2) or comma_valid_bits_n(1) or comma_valid_bits_n(0);

-- alignment shift register for Comma_P
align_sreg_p_proc: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        if comma_valid_p = '1' then
            align_sreg_p <= "10000"; 
        else
            align_sreg_p <= align_sreg_p(0) & align_sreg_p(4 downto 1); 
        end if;
    end if;
end process;

-- alignment shift register for Comma_N
align_sreg_n_proc: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        if comma_valid_n = '1' then
            align_sreg_n <= "10000"; 
        else
            align_sreg_n <= align_sreg_n(0) & align_sreg_n(4 downto 1); 
        end if;
    end if;
end process;
------------------------------------------


------------------------------------------
---- Word Selection Logic and Decoder ----
------------------------------------------
-- latch the 10-bit word array position while receiving commas
latch_pos: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        if(comma_valid_p = '1')then
            pos_p <= comma_valid_bits_p;
        else null;
        end if;
        if(comma_valid_n = '1')then
            pos_n <= comma_valid_bits_n;
        else null;
        end if;
    end if;
end process;

-- select the correct 10-bit word from the array
sel_fromArray: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        if(align_sel_p = '1')then
            align_select <= pos_p;
        elsif(align_sel_n = '1')then
            align_select <= pos_n;
        end if;
    end if;
end process;

-- register the 10-bit word
input_reg1: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        word10b_align_array_r <= word10b_align_array;
    end if;
end process;

-- final register stage before the decoder + word selection
reg_final: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        dec_en  <= word10b_rdy;
        case align_select is 
            when "001" =>  -- bit0 word got comma => align to bit0
                 din_dec <= word10b_align_array_r(0); 
            when "010" =>  -- bit1 word got comma => align to bit1
                 din_dec <= word10b_align_array_r(1);
            when "100" =>  -- bit1 word got comma => align to bit1
                 din_dec <= word10b_align_array_r(2); 
            when others =>
        end case;
    end if;
end process;

Decoder8b10b_inst: Decoder8b10b
   generic map (
      TPD_G          => 1 ns,
      NUM_BYTES_G    => 1,
      RST_POLARITY_G => '1',
      RST_ASYNC_G    => false)
   port map(
      clk           => clk_ckdt,
      clkEn         => dec_en,
      rst           => '0',
      dataIn        => din_dec,
      dataOut       => L0_8B_data,
      dataKOut      => L0_8B_K,
      codeErr       => open,
      dispErr       => open
    );
------------------------------------------


------------------------------------------
----------- Misc Processes ---------------
------------------------------------------
-- process that counts commas
cnt_commas_proc: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        if(L0_8B_data_i /= x"BC")then
            cnt_commas  <= (others => '0');
            commas_true <= '0';
        else
            if(cnt_commas = cnt_thr)then
                commas_true <= '1';
            else
                commas_true <= '0';
                cnt_commas  <= cnt_commas + 1;
            end if;
        end if;
    end if;
end process;

-- process that scans for non-comma characters and asserts the FIFO wr_en
wr_ena_proc: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        if(inhib_wr = '0' and dec_en = '1' and L0_8B_data /= x"BC")then
            wr_en_i <= '1';
        else
            wr_en_i <= '0';
        end if;
        L0_8B_data_i <= L0_8B_data;
    end if;
end process;

-- process that counts write_enables and asserts the null_event signal
-- null_event is high when the VMM only sends a header
cnt_wr_proc: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        if(inhib_wr = '0')then
            if(wr_en_i = '1' and cnt_wr_en /= "11")then
                cnt_wr_en <= cnt_wr_en + 1;
            else 
                cnt_wr_en <= cnt_wr_en; -- keep at this state until assertion of inhibit
            end if;
        else
            cnt_wr_en <= (others => '0');
        end if;

        if(cnt_wr_en > "01")then
            null_event <= '0'; -- keep at this state until assertion of inhibit
        else
            null_event <= '1';
        end if;
    end if;
end process;
------------------------------------------  
  
  word10b_rdy   <= align_sreg_p(4) or align_sreg_n(4);
  align_sel_p   <= align_sreg_p(0);
  align_sel_n   <= align_sreg_n(0);
  dout_dec      <= L0_8B_data_i;
  wr_en         <= wr_en_i;
  
end RTL;
