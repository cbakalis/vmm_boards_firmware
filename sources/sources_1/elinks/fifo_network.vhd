--------------------------------------------------------------------------------------
-- Company: NTUA - BNL
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
-- Create Date: 08.09.2017 15:06:12
-- Design Name: 
-- Module Name: fifo_network - RTL
-- Project Name: 
-- Target Devices: 
-- Target Devices: Artix7 xc7a200t-2fbg484 & xc7a200t-3fbg484 
-- Tool Versions: Vivado 2017.2 
-- 
-- Changelog:
--
--------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fifo_network is
    Port(
        ---------------------------
        ---- general interface ---- 
        clk_in      : in  std_logic;
        fifo_flush  : in  std_logic;
        ---------------------------
        ------- pf interface ------
        vmm_id_pf   : in  std_logic_vector(2 downto 0);
        din_daq     : in  std_logic_vector(15 downto 0);
        wr_en_daq   : in  std_logic;
        ---------------------------
        --- driver interface ------
        vmm_id_drv  : in  std_logic_vector(2 downto 0);
        rd_en_daq   : in  std_logic;
        dout_daq    : out std_logic_vector(15 downto 0);
        empty_daq   : out std_logic
    );
end fifo_network;

architecture RTL of fifo_network is

-- FIFO that buffers the DAQ data
component DAQelinkFIFO
  port (
    clk     : in  std_logic;
    srst    : in  std_logic;
    din     : in  std_logic_vector(15 downto 0);
    wr_en   : in  std_logic;
    rd_en   : in  std_logic;
    dout    : out std_logic_vector(15 downto 0);
    full    : out std_logic;
    empty   : out std_logic
  );
end component;

    signal wr_en_daq_i  : std_logic_vector(7 downto 0) := (others => '0');
    signal rd_en_daq_i  : std_logic_vector(7 downto 0) := (others => '0');
    signal full_daq_i   : std_logic_vector(7 downto 0) := (others => '0');
    signal empty_daq_i  : std_logic_vector(7 downto 0) := (others => '0');

    type daqArray is array (0 to 7) of std_logic_vector(15 downto 0);
    signal dout_daq_i   : daqArray;


begin

-- pf2fifo demux
pf2fifo_demux_proc: process(vmm_id_pf, wr_en_daq)
begin
    case vmm_id_pf is
    when "000"  => wr_en_daq_i(0) <= wr_en_daq; wr_en_daq_i(7 downto 1) <= (others => '0'); 
    when "001"  => wr_en_daq_i(1) <= wr_en_daq; wr_en_daq_i(7 downto 2) <= (others => '0'); wr_en_daq_i(0)          <= '0';
    when "010"  => wr_en_daq_i(2) <= wr_en_daq; wr_en_daq_i(7 downto 3) <= (others => '0'); wr_en_daq_i(1 downto 0) <= (others => '0');
    when "011"  => wr_en_daq_i(3) <= wr_en_daq; wr_en_daq_i(7 downto 4) <= (others => '0'); wr_en_daq_i(2 downto 0) <= (others => '0');
    when "100"  => wr_en_daq_i(4) <= wr_en_daq; wr_en_daq_i(7 downto 5) <= (others => '0'); wr_en_daq_i(3 downto 0) <= (others => '0');
    when "101"  => wr_en_daq_i(5) <= wr_en_daq; wr_en_daq_i(7 downto 6) <= (others => '0'); wr_en_daq_i(4 downto 0) <= (others => '0');
    when "110"  => wr_en_daq_i(6) <= wr_en_daq; wr_en_daq_i(7)          <= '0';             wr_en_daq_i(5 downto 0) <= (others => '0');
    when "111"  => wr_en_daq_i(7) <= wr_en_daq;                                             wr_en_daq_i(6 downto 0) <= (others => '0');
    when others => wr_en_daq_i(7 downto 0) <= (others => '0');
    end case;
end process;

-- fifo2drv mux
fifo2drv_mux_proc: process(vmm_id_drv, rd_en_daq, dout_daq_i, empty_daq_i)
begin
    case vmm_id_drv is
    when "000"  => rd_en_daq_i(0)   <= rd_en_daq;  rd_en_daq_i(7 downto 1) <= (others => '0'); 
                   dout_daq         <= dout_daq_i(0);
                   empty_daq        <= empty_daq_i(0);
    when "001"  => rd_en_daq_i(1)   <= rd_en_daq;  rd_en_daq_i(7 downto 2) <= (others => '0'); rd_en_daq_i(0) <= '0';
                   dout_daq         <= dout_daq_i(1);
                   empty_daq        <= empty_daq_i(1);
    when "010"  => rd_en_daq_i(2)   <= rd_en_daq;  rd_en_daq_i(7 downto 3) <= (others => '0'); rd_en_daq_i(1 downto 0) <= (others => '0');
                   dout_daq         <= dout_daq_i(2);
                   empty_daq        <= empty_daq_i(2);
    when "011"  => rd_en_daq_i(3)   <= rd_en_daq;  rd_en_daq_i(7 downto 4) <= (others => '0'); rd_en_daq_i(2 downto 0) <= (others => '0');
                   dout_daq         <= dout_daq_i(3);
                   empty_daq        <= empty_daq_i(3);
    when "100"  => rd_en_daq_i(4)   <= rd_en_daq;  rd_en_daq_i(7 downto 5) <= (others => '0'); rd_en_daq_i(3 downto 0) <= (others => '0');
                   dout_daq         <= dout_daq_i(4);
                   empty_daq        <= empty_daq_i(4);
    when "101"  => rd_en_daq_i(5)   <= rd_en_daq;  rd_en_daq_i(7 downto 6) <= (others => '0'); rd_en_daq_i(4 downto 0) <= (others => '0');
                   dout_daq         <= dout_daq_i(5);
                   empty_daq        <= empty_daq_i(5);
    when "110"  => rd_en_daq_i(6)   <= rd_en_daq;  rd_en_daq_i(7) <= '0'; rd_en_daq_i(5 downto 0) <= (others => '0');
                   dout_daq         <= dout_daq_i(6);
                   empty_daq        <= empty_daq_i(6);
    when "111"  => rd_en_daq_i(7)   <= rd_en_daq;  rd_en_daq_i(6 downto 0) <= (others => '0'); 
                   dout_daq         <= dout_daq_i(7);
                   empty_daq        <= empty_daq_i(7);
    when others => null;
    end case;
end process;

driverFIFO_0: DAQelinkFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_daq,
    wr_en   => wr_en_daq_i(0),
    rd_en   => rd_en_daq_i(0),
    dout    => dout_daq_i(0),
    full    => full_daq_i(0),
    empty   => empty_daq_i(0)
  );

driverFIFO_1: DAQelinkFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_daq,
    wr_en   => wr_en_daq_i(1),
    rd_en   => rd_en_daq_i(1),
    dout    => dout_daq_i(1),
    full    => full_daq_i(1),
    empty   => empty_daq_i(1)
  );

driverFIFO_2: DAQelinkFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_daq,
    wr_en   => wr_en_daq_i(2),
    rd_en   => rd_en_daq_i(2),
    dout    => dout_daq_i(2),
    full    => full_daq_i(2),
    empty   => empty_daq_i(2)
  );

driverFIFO_3: DAQelinkFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_daq,
    wr_en   => wr_en_daq_i(3),
    rd_en   => rd_en_daq_i(3),
    dout    => dout_daq_i(3),
    full    => full_daq_i(3),
    empty   => empty_daq_i(3)
  );

driverFIFO_4: DAQelinkFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_daq,
    wr_en   => wr_en_daq_i(4),
    rd_en   => rd_en_daq_i(4),
    dout    => dout_daq_i(4),
    full    => full_daq_i(4),
    empty   => empty_daq_i(4)
  );

driverFIFO_5: DAQelinkFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_daq,
    wr_en   => wr_en_daq_i(5),
    rd_en   => rd_en_daq_i(5),
    dout    => dout_daq_i(5),
    full    => full_daq_i(5),
    empty   => empty_daq_i(5)
  );

driverFIFO_6: DAQelinkFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_daq,
    wr_en   => wr_en_daq_i(6),
    rd_en   => rd_en_daq_i(6),
    dout    => dout_daq_i(6),
    full    => full_daq_i(6),
    empty   => empty_daq_i(6)
  );

driverFIFO_7: DAQelinkFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_daq,
    wr_en   => wr_en_daq_i(7),
    rd_en   => rd_en_daq_i(7),
    dout    => dout_daq_i(7),
    full    => full_daq_i(7),
    empty   => empty_daq_i(7)
  );


end RTL;
