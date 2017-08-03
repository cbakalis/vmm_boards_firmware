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
-- Create Date: 30.01.2017
-- Design Name: FPGA Configuration Block
-- Module Name: fpga_config_block - RTL
-- Project Name: MMFE8 - NTUA
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484
-- Tool Versions: Vivado 2016.2
-- Description: Module that samples the data coming from the UDP/Ethernet
-- to produce various control signals for the FPGA user logic. It controls
-- the configuration of the XADC/AXI4SPI_FLASH modules and more general
-- FPGA commands.

-- Dependencies: MMFE8 NTUA Project
-- 
-- Changelog:
-- 07.03.2017 Changed FPGA_conf_proc to accomodate CKBC/CKTP configuration
-- and future register address configuration scheme. (Christos Bakalis)
-- 14.03.2017 Register address configuration scheme deployed. (Christos Bakalis)
-- 17.03.2017 Added synchronizers for daq and trigger signals. (Christos Bakalis)
-- 31.03.2017 Added 2 ckbc mode register (Paris)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity fpga_config_block is
    port(
    ------------------------------------
    ------- General Interface ----------
    clk_125             : in  std_logic;
    rst                 : in  std_logic;
    cnt_bytes           : in  unsigned(7 downto 0);
    user_din_udp        : in  std_logic_vector(7 downto 0);
    ------------------------------------
    -------- UDP Interface -------------
    udp_rx              : in  udp_rx_type;
    ------------------------------------
    ---------- XADC Interface ----------
    xadc_conf           : in  std_logic;
    xadcPacket_rdy      : out std_logic;
    vmm_id_xadc         : out std_logic_vector(15 downto 0);
    xadc_sample_size    : out std_logic_vector(10 downto 0);
    xadc_delay          : out std_logic_vector(17 downto 0);
    ------------------------------------
    ---------- AXI4SPI Interface -------
    flash_conf          : in  std_logic;
    flashPacket_rdy     : out std_logic;
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
    fpga_conf           : in  std_logic;
    fpga_rst            : out std_logic;
    fpgaPacket_rdy      : out std_logic;
    latency             : out std_logic_vector(15 downto 0);
    tr_delay_limit      : out std_logic_vector(15 downto 0);
    ckbc_max_num        : out std_logic_vector(7 downto 0);
    daq_on              : out std_logic;
    ext_trigger         : out std_logic;
    ckbcMode            : out std_logic
    );
end fpga_config_block;

architecture RTL of fpga_config_block is
    
    -- register the address/value and valid signal from UDP packet
    signal reg_address      : std_logic_vector(7 downto 0)  := (others => '0');
    signal reg_value        : std_logic_vector(31 downto 0) := (others => '0');
    signal din_valid        : std_logic := '0';

    -- internal registers
    signal daq_state_reg    : std_logic_vector(7 downto 0)  := (others => '0');
    signal trig_state_reg   : std_logic_vector(7 downto 0)  := (others => '0');
    signal ro_state_reg     : std_logic_vector(7 downto 0)  := (others => '0');
    signal fpga_rst_reg     : std_logic_vector(7 downto 0)  := (others => '0');
    signal ckbcMode_i       : std_logic := '0';
    signal fpga_rst_i       : std_logic := '0';
    signal reg_rst          : std_logic := '0';
    signal rst_cnt          : integer range 0 to 63 := 0;
    
    -- signal to control the timing of the register address/value assertion
    signal latch_enable     : std_logic := '0';
    
    -- synchronizer signals
    signal daq_on_i         : std_logic := '0';
    signal daq_on_sync      : std_logic := '0';
    signal ext_trg_i        : std_logic := '0';
    signal ext_trg_sync     : std_logic := '0';

    -- async_regs
    attribute ASYNC_REG : string;
    
    attribute ASYNC_REG of daq_on_i     : signal is "true";
    attribute ASYNC_REG of daq_on_sync  : signal is "true";
    attribute ASYNC_REG of ext_trg_i    : signal is "true";
    attribute ASYNC_REG of ext_trg_sync : signal is "true";

begin
    
-- register the valid signal
reg_valid_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        din_valid <= udp_rx.data.data_in_valid;
    end if;
end process;

-- sub-process that samples register addresses and values for FPGA/xADC/Flash-IP configuration
FPGA_conf_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(rst = '1')then
            fpgaPacket_rdy  <= '0';
            flashPacket_rdy <= '0';
            xadcPacket_rdy  <= '0';
            reg_address     <= (others => '0');
            reg_value       <= (others => '0');
        else
            if((fpga_conf = '1' or flash_conf = '1' or xadc_conf = '1') and din_valid = '1')then
                case cnt_bytes is
                ----------------------------
                --- register addresses -----
                when "00001100" => -- 12
                    reg_address <= user_din_udp;
                when "00010100" => -- 20
                    reg_address <= user_din_udp;
                when "00011100" => -- 28
                    reg_address <= user_din_udp;
                when "00100100" => -- 36
                    reg_address <= user_din_udp;
                when "00101100" => -- 44
                    reg_address <= user_din_udp;
                when "00110100" => -- 52
                    reg_address <= user_din_udp;
                when "00111100" => -- 60
                    reg_address <= user_din_udp;
                ----------------------------
                --- register values --------
                when "00001101" => -- 13
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00001110" => -- 14
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00001111" => -- 15
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00010000" => -- 16
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00010101" => -- 21
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00010110" => -- 22
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00010111" => -- 23
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00011000" => -- 24
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00011101" => -- 29
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00011110" => -- 30
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00011111" => -- 31
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00100000" => -- 32
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00100101" => -- 37
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00100110" => -- 38
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00100111" => -- 39
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00101000" => -- 40
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00101101" => -- 45
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00101110" => -- 46
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00101111" => -- 47
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00110000" => -- 48
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00110101" => -- 53
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00110110" => -- 54
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00110111" => -- 55
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00111000" => -- 56
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00111101" => -- 61
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00111110" => -- 62
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00111111" => -- 63
                    reg_value(15 downto 8)     <= user_din_udp;
                when "01000000" => -- 64
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "01000100" => -- 68
                    if(fpga_conf = '1')then
                        fpgaPacket_rdy  <= '1';
                    elsif(flash_conf = '1')then
                        flashPacket_rdy <= '1';
                    elsif(xadc_conf = '1')then
                        xadcPacket_rdy  <= '1';
                    else
                        fpgaPacket_rdy  <= '1';
                    end if;
                when others => null;
                end case;
            elsif((fpga_conf = '1' or flash_conf = '1' or xadc_conf = '1') and din_valid = '0')then
                    
                    if(fpga_conf = '1')then
                        fpgaPacket_rdy  <= '1';
                    elsif(flash_conf = '1')then
                        flashPacket_rdy <= '1';
                    elsif(xadc_conf = '1')then
                        xadcPacket_rdy  <= '1';
                    else
                        fpgaPacket_rdy  <= '1';
                    end if;
            else
                fpgaPacket_rdy  <= '0';
                flashPacket_rdy <= '0';
                xadcPacket_rdy  <= '0';
            end if;
        end if;
    end if;
end process;

-- process that controls the latch enable signal
latch_ena_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if((fpga_conf = '1' or flash_conf = '1' or xadc_conf = '1') and din_valid = '1')then
            case cnt_bytes is
            --        9            17           25          33           41            49           57                
            when  "00001001" | "00010001" | "00011001" | "00100001" | "00101001" | "00110001" | "00111001" =>
                latch_enable <= '1';
            when  "00001011" | "00010011" | "00011011" | "00100011" | "00101011" | "00110011" | "00111011" =>
            --       11            19           27          35           43            51           59 
                latch_enable <= '0';
            when others => null;
            end case;
        elsif((fpga_conf = '1' or flash_conf = '1' or xadc_conf = '1') and din_valid = '0')then
            latch_enable <= '1';
        else
            latch_enable <= '0';
        end if;
    end if;
end process;

-- demux that assigns values to signals depending on the address
regMap_demux_proc: process(reg_address, reg_value, latch_enable, reg_rst)
begin
    if(latch_enable = '1')then
        case reg_address is
        ----- fpga conf ------
        when x"ab"  => trig_state_reg           <= reg_value(7 downto 0);
        when x"0f"  => daq_state_reg            <= reg_value(7 downto 0);
        when x"cd"  => ro_state_reg             <= reg_value(7 downto 0);
        when x"af"  => fpga_rst_reg             <= reg_value(7 downto 0);
        when x"05"  => latency                  <= reg_value(15 downto 0);
        when x"c1"  => cktk_max_num             <= reg_value(7 downto 0);
        when x"c2"  => ckbc_freq                <= reg_value(7 downto 0);
        when x"c3"  => cktp_max_num             <= reg_value(15 downto 0);
        when x"c4"  => cktp_skew                <= reg_value(7 downto 0);
        when x"c5"  => cktp_period              <= reg_value(15 downto 0);
        when x"c6"  => cktp_width               <= reg_value(7 downto 0);
        when x"c7"  => ckbc_max_num             <= reg_value(7 downto 0);
        when x"c8"  => tr_delay_limit           <= reg_value(15 downto 0);
        ----- xADC conf ------
        when x"a1"  => vmm_id_xadc              <= reg_value(15 downto 0);
        when x"a2"  => xadc_sample_size         <= reg_value(10 downto 0);
        when x"a3"  => xadc_delay               <= reg_value(17 downto 0);
        ----- flash IP conf --
        when x"b1"  => destIP_set               <= reg_value(31 downto 0);
        when x"b2"  => myIP_set                 <= reg_value(31 downto 0);
        when x"b3"  => myMAC_set(47 downto 32)  <= reg_value(15 downto 0);
        when x"b4"  => myMAC_set(31 downto 0)   <= reg_value(31 downto 0);
        when others => null;
        end case;
    elsif(reg_rst = '1')then
        fpga_rst_reg <= (others => '0');
    end if;
end process;

-- process to handle daq state
daqOnOff_proc: process(daq_state_reg, daq_on_i)
begin
    case daq_state_reg is
    when x"01"  => daq_on_i <= '1';
    when x"00"  => daq_on_i <= '0';
    when others => daq_on_i <= daq_on_i;
    end case;
end process;

-- process to handle trigger state
triggerState_proc: process(trig_state_reg, ext_trg_i)
begin
    case trig_state_reg is
    when x"04"  => ext_trg_i <= '1';
    when x"07"  => ext_trg_i <= '0';
    when others => ext_trg_i <= ext_trg_i;
    end case;
end process;

-- process to handle readout state
readoutState_proc: process(ro_state_reg, ckbcMode_i)
begin
    case ro_state_reg is
    when x"01"  => ckbcMode_i <= '1';
    when x"00"  => ckbcMode_i <= '0';
    when others => ckbcMode_i <= ckbcMode_i;
    end case;
end process;

-- process to handle FPGA reset state
FPGArst_proc: process(fpga_rst_reg, fpga_rst_i)
begin
    case fpga_rst_reg is
    when x"aa"  => fpga_rst_i <= '1';
    when x"00"  => fpga_rst_i <= '0';
    when others => fpga_rst_i <= fpga_rst_i;
    end case;
end process;

-- FPGA reset asserter
rst_asserter_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(fpga_rst_i = '1')then
            case rst_cnt is
            when 0 to 62 =>
                fpga_rst <= '1';
                rst_cnt  <= rst_cnt + 1;
            when 63 =>
                fpga_rst <= '0';
                reg_rst  <= '1';
            when others =>
                rst_cnt  <= 0;
                fpga_rst <= '0';
                reg_rst  <= '0';
            end case;
        else
            rst_cnt  <= 0;
            fpga_rst <= '0';
            reg_rst  <= '0';
        end if;
    end if;
end process;

-- synchronizing circuit
syncProc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        daq_on_sync     <= daq_on_i;
        daq_on          <= daq_on_sync;
        ext_trg_sync    <= ext_trg_i;
        ext_trigger     <= ext_trg_sync;
    end if;
end process;

-- To be synchronized into ckbc_gen
ckbcMode <= ckbcMode_i;

end RTL;