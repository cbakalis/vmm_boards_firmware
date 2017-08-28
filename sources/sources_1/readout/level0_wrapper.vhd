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
-- Create Date: 28.04.2017 14:18:44
-- Design Name: Level-0 Wrapper
-- Module Name: level0_wrapper - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: Wrapper that contains all necessary modules for implementing
-- level0 readout of the VMMs
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use UNISIM.VComponents.all;

entity level0_wrapper is
    Generic(is_mmfe8        : std_logic;
            vmmReadoutMode  : std_logic);
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt        : in  std_logic; -- will be forwarded to the VMM
        clk             : in  std_logic; -- buffer read domain
        rst_buff        : in  std_logic; -- reset buffer
        level_0         : in  std_logic; -- level-0 signal
        wr_accept       : in  std_logic; -- buffer acceptance window
        vmm_conf        : in  std_logic; -- high during VMM configuration
        daq_on_inhib    : out std_logic; -- prevent daq_on state before checking link health
        all_ready       : out std_logic;
        ------------------------------------
        ---- Packet Formation Interface ----
        rd_ena_buff     : in  std_logic;
        rst_intf_proc   : in  std_logic;
        vmmId           : in  std_logic_vector(2 downto 0);  -- VMM to be readout
        vmmWordReady    : out std_logic;
        vmmWord         : out std_logic_vector(15 downto 0);
        vmmEventDone    : out std_logic;
        linkHealth_bmsk : out std_logic_vector(8 downto 1);
        ------------------------------------
        ---------- VMM3 Interface ----------
        vmm_data0_vec   : in  std_logic_vector(8 downto 1);  -- Single-ended data0 from VMM
        vmm_data1_vec   : in  std_logic_vector(8 downto 1);  -- Single-ended data1 from VMM
        vmm_cktk_vec    : out std_logic_vector(8 downto 1)   -- Strobe to VMM CKTK
    );
end level0_wrapper;

architecture RTL of level0_wrapper is

component l0_deserializer_decoder
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt    : in  std_logic; -- will be forwarded to the VMM
        level_0     : in  std_logic; -- level-0 signal
        ------------------------------------
        -------- Buffer Interface ----------
        inhib_wr    : in  std_logic;
        commas_true : out std_logic;
        dout_dec    : out std_logic_vector(7 downto 0);
        wr_en       : out std_logic;
        ------------------------------------
        ---------- VMM Interface -----------
        vmm_data0   : in  std_logic;
        vmm_data1   : in  std_logic
    );
end component;

component l0_buffer_wrapper is
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt        : in  std_logic;
        clk             : in  std_logic;
        rst_buff        : in  std_logic;
        wr_accept       : in  std_logic;
        level_0         : in  std_logic;
        ------------------------------------
        --- Deserializer Interface ---------
        inhib_wr        : out std_logic;
        commas_true     : in  std_logic;
        dout_dec        : in  std_logic_vector(7 downto 0);
        wr_en           : in  std_logic;
        ------------------------------------
        ---- Packet Formation Interface ----
        rd_ena_buff     : in  std_logic;
        rst_intf_proc   : in  std_logic;
        vmmWordReady    : out std_logic;
        vmmWord         : out std_logic_vector(15 downto 0);
        vmmEventDone    : out std_logic
    );
end component;

component l0_link_health
    Generic(is_mmfe8 : std_logic);
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk                 : in  std_logic;
        vmm_conf            : in  std_logic;
        daqOn_inhibit       : out std_logic;
        ------------------------------------
        --- Deserializer Interface ---------
        commas_true         : in  std_logic_vector(8 downto 1);
        ------------------------------------
        ---- Packet Formation Interface ----
        EventDone_dummy     : out std_logic_vector(8 downto 1);
        linkHealth_bitmask  : out std_logic_vector(8 downto 1)
    );
end component;

    type dout_dec_array is array (8 downto 1) of std_logic_vector(7 downto 0);
    type vmmWord_array  is array (8 downto 1) of std_logic_vector(15 downto 0);
    
    signal wr_en                : std_logic_vector(8 downto 1)  := (others => '0');
    signal rd_ena_buff_i        : std_logic_vector(8 downto 1)  := (others => '0');
    signal vmmWordReady_i       : std_logic_vector(8 downto 1)  := (others => '0');
    signal EventDone_health_i   : std_logic_vector(8 downto 1)  := (others => '0');
    signal vmmEventDone_i       : std_logic_vector(8 downto 1)  := (others => '0');
    signal inhib_wr_i           : std_logic_vector(8 downto 1)  := (others => '0');
    signal commas_true_i        : std_logic_vector(8 downto 1)  := (others => '0');
    signal commas_true_s0       : std_logic_vector(8 downto 1)  := (others => '0');
    signal commas_true_s1       : std_logic_vector(8 downto 1)  := (others => '0');
    signal vmmWord_i            : vmmWord_array;
    signal dout_dec             : dout_dec_array;
    
    attribute ASYNC_REG                         : string;
    attribute ASYNC_REG of commas_true_s0       : signal is "TRUE";
    attribute ASYNC_REG of commas_true_s1       : signal is "TRUE";
    
-- function to convert std_logic to integer for instance generation
function sl2int (x: std_logic) return integer is
begin
    if(x='1')then 
        return 8; 
    else 
        return 1; 
    end if;
end;

begin
  
---------------------------------------------
------- Add VMM Readout Instances -----------
---------------------------------------------
readout_instances: for I in 1 to sl2int(is_mmfe8) generate 

des_dec_inst: l0_deserializer_decoder
    Port Map(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt    => clk_ckdt,
        level_0     => level_0,
        ------------------------------------
        -------- Buffer Interface ----------
        inhib_wr    => inhib_wr_i(I),
        commas_true => commas_true_i(I),
        dout_dec    => dout_dec(I),
        wr_en       => wr_en(I),
        ------------------------------------
        ---------- VMM Interface -----------
        vmm_data0   => vmm_data0_vec(I),
        vmm_data1   => vmm_data1_vec(I)
    );
    
l0_buf_wr_inst: l0_buffer_wrapper
    Port Map(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt        => clk_ckdt,
        clk             => clk,
        rst_buff        => rst_buff,
        wr_accept       => wr_accept,
        level_0         => level_0,
        ------------------------------------
        --- Deserializer Interface ---------
        inhib_wr        => inhib_wr_i(I),
        commas_true     => commas_true_i(I),
        dout_dec        => dout_dec(I),
        wr_en           => wr_en(I),
        ------------------------------------
        ---- Packet Formation Interface ----
        rd_ena_buff     => rd_ena_buff_i(I),
        rst_intf_proc   => rst_intf_proc,
        vmmWordReady    => vmmWordReady_i(I),
        vmmWord         => vmmWord_i(I),
        vmmEventDone    => vmmEventDone_i(I)
    );
    
end generate readout_instances;

-- check comma alignment
l0_link_health_inst: l0_link_health
    Generic Map(is_mmfe8 => is_mmfe8)
    Port Map(
        ------------------------------------
        ------- General Interface ----------
        clk                 => clk,
        vmm_conf            => vmm_conf,
        daqOn_inhibit       => daq_on_inhib,
        ------------------------------------
        --- Deserializer Interface ---------
        commas_true         => commas_true_s1,
        ------------------------------------
        ---- Packet Formation Interface ----
        EventDone_dummy     => EventDone_health_i,
        linkHealth_bitmask  => linkHealth_bmsk
    );
    
sync_linkHealth: process(clk)
begin
    if(rising_edge(clk))then
        commas_true_s0 <= commas_true_i;
        commas_true_s1 <= commas_true_s0;
    end if;
end process;

-- multiplexer that drives the packet formation signals corresponding to the vmmID         
vmm_ID_MUX: process(vmmId, vmmWordReady_i, vmmWord_i, vmmEventDone_i, EventDone_health_i, rd_ena_buff)
begin
    case vmmId is
    when "000"  =>
        vmmWordReady                <= vmmWordReady_i(1) and not EventDone_health_i(1);
        vmmWord                     <= vmmWord_i(1);
        vmmEventDone                <= vmmEventDone_i(1) or EventDone_health_i(1);
        rd_ena_buff_i(1)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 2)   <= (others => '0');
    when "001"  =>
        vmmWordReady                <= vmmWordReady_i(2) and not EventDone_health_i(2);
        vmmWord                     <= vmmWord_i(2);
        vmmEventDone                <= vmmEventDone_i(2) or EventDone_health_i(2);
        rd_ena_buff_i(2)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 3)   <= (others => '0');
        rd_ena_buff_i(1 downto 1)   <= (others => '0');
    when "010"  =>
        vmmWordReady                <= vmmWordReady_i(3) and not EventDone_health_i(3);
        vmmWord                     <= vmmWord_i(3);
        vmmEventDone                <= vmmEventDone_i(3) or EventDone_health_i(3);
        rd_ena_buff_i(3)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 4)   <= (others => '0');
        rd_ena_buff_i(2 downto 1)   <= (others => '0');
    when "011"  =>
        vmmWordReady                <= vmmWordReady_i(4) and not EventDone_health_i(4);
        vmmWord                     <= vmmWord_i(4);
        vmmEventDone                <= vmmEventDone_i(4) or EventDone_health_i(4);
        rd_ena_buff_i(4)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 5)   <= (others => '0');
        rd_ena_buff_i(3 downto 1)   <= (others => '0');
    when "100"  =>
        vmmWordReady                <= vmmWordReady_i(5) and not EventDone_health_i(5);
        vmmWord                     <= vmmWord_i(5);
        vmmEventDone                <= vmmEventDone_i(5) or EventDone_health_i(5);
        rd_ena_buff_i(5)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 6)   <= (others => '0');
        rd_ena_buff_i(4 downto 1)   <= (others => '0');
    when "101"  =>
        vmmWordReady                <= vmmWordReady_i(6) and not EventDone_health_i(6);
        vmmWord                     <= vmmWord_i(6);
        vmmEventDone                <= vmmEventDone_i(6) or EventDone_health_i(6);
        rd_ena_buff_i(6)            <= rd_ena_buff;
        rd_ena_buff_i(8 downto 7)   <= (others => '0');
        rd_ena_buff_i(5 downto 1)   <= (others => '0');
    when "110"  =>
        vmmWordReady                <= vmmWordReady_i(7) and not EventDone_health_i(7);
        vmmWord                     <= vmmWord_i(7);
        vmmEventDone                <= vmmEventDone_i(7) or EventDone_health_i(7);
        rd_ena_buff_i(7)            <= rd_ena_buff;
        rd_ena_buff_i(6 downto 1)   <= (others => '0');
        rd_ena_buff_i(8)            <= '0';
    when "111"  =>
        vmmWordReady                <= vmmWordReady_i(8) and not EventDone_health_i(8);
        vmmWord                     <= vmmWord_i(8);
        vmmEventDone                <= vmmEventDone_i(8) or EventDone_health_i(8);
        rd_ena_buff_i(8)            <= rd_ena_buff;
        rd_ena_buff_i(7 downto 1)   <= (others => '0');
    when others =>
        vmmWordReady                <= '0';
        vmmWord                     <= (others => '0');
        rd_ena_buff_i               <= (others => '0');
        vmmEventDone                <= '0';
    end case;
end process;

    vmm_cktk_vec(1) <= level_0;
    vmm_cktk_vec(2) <= level_0;
    vmm_cktk_vec(3) <= level_0;
    vmm_cktk_vec(4) <= level_0;
    vmm_cktk_vec(5) <= level_0;
    vmm_cktk_vec(6) <= level_0;
    vmm_cktk_vec(7) <= level_0;
    vmm_cktk_vec(8) <= level_0;
    all_ready       <= vmmWordReady_i(0) and vmmWordReady_i(1) and vmmWordReady_i(2) and
                       vmmWordReady_i(3) and vmmWordReady_i(4) and vmmWordReady_i(5) and
                       vmmWordReady_i(6) and vmmWordReady_i(7);
    
end RTL;