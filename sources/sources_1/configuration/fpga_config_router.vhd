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
-- Create Date: 05.08.2017
-- Design Name: FPGA Configuration Router
-- Module Name: fpga_config_router - RTL
-- Project Name: MMFE8 - NTUA
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484
-- Tool Versions: Vivado 2017.2
-- Description: Module that drives the register value bus shift register to the
-- appropriate FPGA register depending on the address.

-- Dependencies: MMFE8 NTUA Project
-- 
-- Changelog:
--
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity fpga_config_router is
    port(
    ------------------------------------
    ------ General Interface -----------
    clk_125             : in std_logic;
    reg_addr            : in std_logic_vector(7 downto 0);
    reg_rst             : in std_logic;
    reg_value_bit       : in std_logic;
    sreg_ena            : in std_logic;
    ------------------------------------
    ---------- XADC Interface ----------
    vmm_id_xadc         : out std_logic_vector(15 downto 0);
    xadc_sample_size    : out std_logic_vector(10 downto 0);
    xadc_delay          : out std_logic_vector(17 downto 0);
    ------------------------------------
    ---------- AXI4SPI Interface -------
    myIP_set            : out std_logic_vector(31 downto 0);
    myMAC_set           : out std_logic_vector(47 downto 0);
    destIP_set          : out std_logic_vector(31 downto 0);
    ------------------------------------
    -------- CKTP/CKBC Interface -------
    ckbc_freq           : out std_logic_vector(7 downto 0);
    cktk_max_num        : out std_logic_vector(7 downto 0);
    cktp_max_num        : out std_logic_vector(15 downto 0);
    cktp_skew           : out std_logic_vector(7 downto 0);
    cktp_period         : out std_logic_vector(15 downto 0);
    cktp_width          : out std_logic_vector(7 downto 0);
    ------------------------------------
    -------- FPGA Config Interface -----
    latency             : out std_logic_vector(15 downto 0);
    tr_delay_limit      : out std_logic_vector(15 downto 0);
    ckbc_max_num        : out std_logic_vector(7 downto 0);
    daq_state           : out std_logic_vector(7 downto 0);
    trig_state          : out std_logic_vector(7 downto 0);
    ro_state            : out std_logic_vector(7 downto 0);
    fpga_rst_state      : out std_logic_vector(7 downto 0);
    artTimeout          : out std_logic_vector(7 downto 0)
    );
end fpga_config_router;

architecture RTL of fpga_config_router is

    ---- shift register enable buses. unused, but added here for index reference
    ---- 0 (index)
    --signal vmm_id_xadc_ena      : std_logic := '0';
    ---- 1
    --signal xadc_sample_size_ena : std_logic := '0';
    ---- 2
    --signal xadc_delay_ena       : std_logic := '0';
    ---- 3
    --signal destIP_set_ena         : std_logic := '0';
    ---- 4
    --signal myIP_set_ena        : std_logic := '0';
    ---- 5
    --signal myMAC_set_ena(47 downto 32) : std_logic := '0';
    ---- 19
    --signal myMAC_set_ena(31 downto 0) : std_logic := '0';
    ---- 6
    --signal ckbc_freq_ena        : std_logic := '0';
    ---- 7
    --signal cktk_max_num_ena     : std_logic := '0';
    ---- 8
    --signal cktp_max_num_ena     : std_logic := '0';
    ---- 9
    --signal cktp_skew_ena        : std_logic := '0';
    ---- 10
    --signal cktp_period_ena      : std_logic := '0';
    ---- 11
    --signal cktp_width_ena       : std_logic := '0';
    ---- 12
    --signal latency_ena          : std_logic := '0';
    ---- 13
    --signal tr_delay_limit_ena   : std_logic := '0';
    ---- 14
    --signal ckbc_max_num_ena     : std_logic := '0';
    ---- 15
    --signal daq_state_ena        : std_logic := '0';
    ---- 16
    --signal trig_state_ena       : std_logic := '0';
    ---- 17
    --signal ro_state_ena         : std_logic := '0';
    ---- 18
    --signal fpga_rst_ena         : std_logic := '0';
    ---- 20
    --signal artTimeout           : std_logic := '0';

    signal ena_bus              : std_logic_vector(31 downto 0) := (others => '0');

function bit_reverse(s1:std_logic_vector) return std_logic_vector is 
    variable rr : std_logic_vector(s1'high downto s1'low); 
    begin 
        for ii in s1'high downto s1'low loop 
            rr(ii) := s1(s1'high-ii); 
        end loop; 
        return rr; 
end bit_reverse; 

    -- internal registers
    signal daq_state_reg        : std_logic_vector(7 downto 0)  := (others => '0');
    signal trig_state_reg       : std_logic_vector(7 downto 0)  := (others => '0');
    signal ro_state_reg         : std_logic_vector(7 downto 0)  := (others => '0');
    signal fpga_rst_reg         : std_logic_vector(7 downto 0)  := (others => '0');
    signal myMAC_0              : std_logic_vector(15 downto 0) := (others => '0');
    signal myMAC_1              : std_logic_vector(31 downto 0) := (others => '0');
    signal latency_i            : std_logic_vector(15 downto 0) := (others => '0');
    signal cktk_max_num_i       : std_logic_vector(7 downto 0)  := bit_reverse(x"07");
    signal ckbc_freq_i          : std_logic_vector(7 downto 0)  := bit_reverse(x"28");
    signal cktp_max_num_i       : std_logic_vector(15 downto 0) := bit_reverse(x"ffff");
    signal cktp_skew_i          : std_logic_vector(7 downto 0)  := (others => '0');
    signal cktp_period_i        : std_logic_vector(15 downto 0) := bit_reverse(x"7530");
    signal cktp_width_i         : std_logic_vector(7 downto 0)  := bit_reverse(x"04");
    signal ckbc_max_num_i       : std_logic_vector(7 downto 0)  := bit_reverse(x"06");
    signal tr_delay_limit_i     : std_logic_vector(15 downto 0) := bit_reverse(x"ffff");
    signal vmm_id_xadc_i        : std_logic_vector(15 downto 0) := (others => '0');
    signal xadc_sample_size_i   : std_logic_vector(10 downto 0) := (others => '0');
    signal xadc_delay_i         : std_logic_vector(17 downto 0) := (others => '0');
    signal destIP_set_i         : std_logic_vector(31 downto 0) := (others => '0');
    signal myIP_set_i           : std_logic_vector(31 downto 0) := (others => '0');
    signal artTimeout_i         : std_logic_vector(7 downto 0)  := bit_reverse(x"18");



begin

router_demux: process(reg_addr, sreg_ena)
begin
    case reg_addr is
    ----- fpga conf ------
    when x"ab"  => ena_bus(16) <= sreg_ena; ena_bus(15 downto 0) <= (others => '0'); ena_bus(31 downto 17) <= (others => '0'); -- trigger mode
    when x"0f"  => ena_bus(15) <= sreg_ena; ena_bus(14 downto 0) <= (others => '0'); ena_bus(31 downto 16) <= (others => '0'); -- DAQ state
    when x"cd"  => ena_bus(17) <= sreg_ena; ena_bus(16 downto 0) <= (others => '0'); ena_bus(31 downto 18) <= (others => '0'); -- readout state
    when x"af"  => ena_bus(18) <= sreg_ena; ena_bus(17 downto 0) <= (others => '0'); ena_bus(31 downto 19) <= (others => '0'); -- FPGA reset
    when x"05"  => ena_bus(12) <= sreg_ena; ena_bus(11 downto 0) <= (others => '0'); ena_bus(31 downto 13) <= (others => '0'); -- latency
    when x"c1"  => ena_bus(7)  <= sreg_ena; ena_bus(6 downto 0)  <= (others => '0'); ena_bus(31 downto 8)  <= (others => '0'); -- CKTK max
    when x"c2"  => ena_bus(6)  <= sreg_ena; ena_bus(5 downto 0)  <= (others => '0'); ena_bus(31 downto 7)  <= (others => '0'); -- CKBC freq
    when x"c3"  => ena_bus(8)  <= sreg_ena; ena_bus(7 downto 0)  <= (others => '0'); ena_bus(31 downto 9)  <= (others => '0'); -- CKTP max
    when x"c4"  => ena_bus(9)  <= sreg_ena; ena_bus(8 downto 0)  <= (others => '0'); ena_bus(31 downto 10) <= (others => '0'); -- CKTP skew
    when x"c5"  => ena_bus(10) <= sreg_ena; ena_bus(9 downto 0)  <= (others => '0'); ena_bus(31 downto 11) <= (others => '0'); -- CKTP period
    when x"c6"  => ena_bus(11) <= sreg_ena; ena_bus(10 downto 0) <= (others => '0'); ena_bus(31 downto 12) <= (others => '0'); -- CKTP width
    when x"c7"  => ena_bus(14) <= sreg_ena; ena_bus(13 downto 0) <= (others => '0'); ena_bus(31 downto 15) <= (others => '0'); -- CKBC max
    when x"c8"  => ena_bus(13) <= sreg_ena; ena_bus(12 downto 0) <= (others => '0'); ena_bus(31 downto 14) <= (others => '0'); -- trigger delay
    when x"c9"  => ena_bus(20) <= sreg_ena; ena_bus(19 downto 0) <= (others => '0'); ena_bus(31 downto 21) <= (others => '0'); -- art timeout
    ----- xADC conf ------
    when x"a1"  => ena_bus(0)  <= sreg_ena; ena_bus(31 downto 1) <= (others => '0'); ena_bus(31 downto 1)  <= (others => '0'); -- VMM ID xADC
    when x"a2"  => ena_bus(1)  <= sreg_ena; ena_bus(0 downto 0)  <= (others => '0'); ena_bus(31 downto 2)  <= (others => '0'); -- xADC sample size
    when x"a3"  => ena_bus(2)  <= sreg_ena; ena_bus(1 downto 0)  <= (others => '0'); ena_bus(31 downto 3)  <= (others => '0'); -- xADC delay
    ----- flash IP conf --
    when x"b1"  => ena_bus(3)  <= sreg_ena; ena_bus(2 downto 0)  <= (others => '0'); ena_bus(31 downto 4)  <= (others => '0'); -- destIP
    when x"b2"  => ena_bus(4)  <= sreg_ena; ena_bus(3 downto 0)  <= (others => '0'); ena_bus(31 downto 5)  <= (others => '0'); -- myIP
    when x"b3"  => ena_bus(5)  <= sreg_ena; ena_bus(4 downto 0)  <= (others => '0'); ena_bus(31 downto 6)  <= (others => '0'); -- myMAC(47 downto 32)
    when x"b4"  => ena_bus(19) <= sreg_ena; ena_bus(18 downto 0) <= (others => '0'); ena_bus(31 downto 20) <= (others => '0'); -- myMAC(31 downto 0)
    when others => null;
    end case;
end process;

-- drives the enable signal to the correct shift register
sreg_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(reg_rst = '1')then
            fpga_rst_reg <= (others => '0');
        else
                ----- fpga conf ------
            if(ena_bus(16) = '1')then trig_state_reg    <= reg_value_bit & trig_state_reg(7 downto 1);      else null; end if;
            if(ena_bus(15) = '1')then daq_state_reg     <= reg_value_bit & daq_state_reg(7 downto 1);       else null; end if;
            if(ena_bus(17) = '1')then ro_state_reg      <= reg_value_bit & ro_state_reg(7 downto 1);        else null; end if;
            if(ena_bus(18) = '1')then fpga_rst_reg      <= reg_value_bit & fpga_rst_reg(7 downto 1);        else null; end if;
            if(ena_bus(12) = '1')then latency_i         <= reg_value_bit & latency_i(15 downto 1);          else null; end if;
            if(ena_bus(7) = '1')then cktk_max_num_i     <= reg_value_bit & cktk_max_num_i(7 downto 1);      else null; end if;
            if(ena_bus(6) = '1')then ckbc_freq_i        <= reg_value_bit & ckbc_freq_i(7 downto 1);         else null; end if;
            if(ena_bus(8) = '1')then cktp_max_num_i     <= reg_value_bit & cktp_max_num_i(15 downto 1);     else null; end if;
            if(ena_bus(9) = '1')then cktp_skew_i        <= reg_value_bit & cktp_skew_i(7 downto 1);         else null; end if;
            if(ena_bus(10) = '1')then cktp_period_i     <= reg_value_bit & cktp_period_i(15 downto 1);      else null; end if;        
            if(ena_bus(11) = '1')then cktp_width_i      <= reg_value_bit & cktp_width_i(7 downto 1);        else null; end if;
            if(ena_bus(14) = '1')then ckbc_max_num_i    <= reg_value_bit & ckbc_max_num_i(7 downto 1);      else null; end if;
            if(ena_bus(13) = '1')then tr_delay_limit_i  <= reg_value_bit & tr_delay_limit_i(15 downto 1);   else null; end if;
            if(ena_bus(20) = '1')then artTimeout_i      <= reg_value_bit & artTimeout_i(7 downto 1);        else null; end if;
                ----- xADC conf ------
            if(ena_bus(0) = '1')then vmm_id_xadc_i      <= reg_value_bit & vmm_id_xadc_i(15 downto 1);      else null; end if;
            if(ena_bus(1) = '1')then xadc_sample_size_i <= reg_value_bit & xadc_sample_size_i(10 downto 1); else null; end if;
            if(ena_bus(2) = '1')then xadc_delay_i       <= reg_value_bit & xadc_delay_i(17 downto 1);       else null; end if;
                ----- flash IP conf ----
            if(ena_bus(3) = '1')then destIP_set_i       <= reg_value_bit & destIP_set_i(31 downto 1);       else null; end if;
            if(ena_bus(4) = '1')then myIP_set_i         <= reg_value_bit & myIP_set_i(31 downto 1);         else null; end if;
            if(ena_bus(5) = '1')then myMAC_0            <= reg_value_bit & myMAC_0(15 downto 1);            else null; end if;
            if(ena_bus(19) = '1')then myMAC_1           <= reg_value_bit & myMAC_1(31 downto 1);            else null; end if;
        end if;
    end if;
end process;

    latency         <= bit_reverse(latency_i);
    cktk_max_num    <= bit_reverse(cktk_max_num_i);
    ckbc_freq       <= bit_reverse(ckbc_freq_i);
    cktp_max_num    <= bit_reverse(cktp_max_num_i);
    cktp_skew       <= bit_reverse(cktp_skew_i);
    cktp_period     <= bit_reverse(cktp_period_i);
    cktp_width      <= bit_reverse(cktp_width_i);
    ckbc_max_num    <= bit_reverse(ckbc_max_num_i);
    tr_delay_limit  <= bit_reverse(tr_delay_limit_i);
    vmm_id_xadc     <= bit_reverse(vmm_id_xadc_i);
    xadc_sample_size<= bit_reverse(xadc_sample_size_i);
    xadc_delay      <= bit_reverse(xadc_delay_i);
    destIP_set      <= bit_reverse(destIP_set_i);
    myIP_set        <= bit_reverse(myIP_set_i);
    myMAC_set       <= bit_reverse(myMAC_0) & bit_reverse(myMAC_1);
    daq_state       <= bit_reverse(daq_state_reg);
    trig_state      <= bit_reverse(trig_state_reg);
    ro_state        <= bit_reverse(ro_state_reg);
    fpga_rst_state  <= bit_reverse(fpga_rst_reg);
    artTimeout      <= bit_reverse(artTimeout_i);
    

end RTL;