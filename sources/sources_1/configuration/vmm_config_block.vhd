----------------------------------------------------------------------------------------
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
-- Design Name: VMM Configuration Block
-- Module Name: vmm_config_block - RTL
-- Project Name: MMFE8 - NTUA
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484
-- Tool Versions: Vivado 2016.2
-- Description: Module that stores the data coming from the UDP/Ethernet for VMM
-- configuration using a FIFO serializer. It also drives the SCK and CS signals.

-- Dependencies: MMFE8 NTUA Project
-- 
-- Changelog:
-- 16.02.2017 Modified the serialization FSM for VMM3 configuration. (Christos Bakalis)
-- 28.03.2017 VMM_ID is now sampled one level above. (Christos Bakalis)
--
----------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity vmm_config_block is
    port(
    ------------------------------------
    ------- General Interface ----------
    clk_125             : in  std_logic;
    clk_40              : in  std_logic;
    rst                 : in  std_logic;
    rst_fifo            : in  std_logic;
    cnt_bytes           : in  unsigned(7 downto 0);
    ------------------------------------
    --------- FIFO/UDP Interface -------
    user_din_udp        : in  std_logic_vector(7 downto 0); --prv
    user_valid_udp      : in  std_logic; --prv
    user_last_udp       : in  std_logic; --prv
    ------------------------------------
    ------ VMM Config Interface --------
    vmmConf_rdy         : out std_logic;
    vmmConf_done        : out std_logic;
    vmm_sck             : out std_logic;
    vmm_cs              : out std_logic;
    vmm_cfg_bit         : out std_logic;
    vmm_conf            : in  std_logic;
    top_rdy             : in  std_logic;
    init_ser            : in  std_logic
    );
end vmm_config_block;

architecture RTL of vmm_config_block is

    COMPONENT vmm_conf_buffer
    PORT (
        rst     : IN STD_LOGIC;
        wr_clk  : IN STD_LOGIC;
        rd_clk  : IN STD_LOGIC;
        din     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        wr_en   : IN STD_LOGIC;
        rd_en   : IN STD_LOGIC;
        dout    : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        full    : OUT STD_LOGIC;
        empty   : OUT STD_LOGIC
    );
    END COMPONENT;

    signal rd_ena           : std_logic := '0';
    signal fifo_full        : std_logic := '0';
    signal fifo_empty       : std_logic := '0';
    signal sel_vmm_data     : std_logic := '0';
    signal wait_cnt         : unsigned(1 downto 0) := (others => '0');
    signal bit_cnt          : unsigned(6 downto 0) := (others => '0');
    signal user_valid_fifo  : std_logic := '0';
    signal vmm_cs_i         : std_logic := '1';

    type confFSM is (ST_IDLE, ST_RD_HIGH, ST_RD_LOW, ST_CKTK_LOW, ST_DONE);
    signal st_conf : confFSM := ST_IDLE;

begin

-- sub-process that drives the data into the FIFO used for VMM configuration. 
-- it also detects the 'last' pulse sent from the UDP block to initialize the 
-- VMM config data serialization
VMM_conf_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(rst = '1')then
            sel_vmm_data    <= '0';
            vmmConf_rdy     <= '0';
        else
            if(vmm_conf = '1' and user_last_udp = '0')then
                case cnt_bytes is 
                when "00001000" => --8
                    sel_vmm_data        <= '1'; -- select the correct data at the MUX
                when others => null;
                end case;
            elsif(vmm_conf = '1' and user_last_udp = '1')then -- 'last' pulse detected, signal master FSM
                vmmConf_rdy    <= '1';
            else
                vmmConf_rdy    <= '0';
                sel_vmm_data   <= '0';
            end if;
        end if;
    end if;
end process;

-- FSM that reads the data from the serializing FIFO  and asserts the SCK pulse 
-- after the bit has passed safely into the vmm configuration bus. serialization 
-- starts only after the assertion of the 'last' signal from the UDP block (see VMM_conf_proc)
VMM_conf_SCK_FSM: process(clk_40)
begin
    if(rising_edge(clk_40))then
        if(rst = '1' or rst_fifo = '1')then
            st_conf         <= ST_IDLE;
            vmmConf_done    <= '0';
            rd_ena          <= '0';
            wait_cnt        <= (others => '0');
            bit_cnt         <= (others => '0');
            vmm_sck         <= '0';
            vmm_cs_i        <= '1';
        else
            case st_conf is

            -- wait for flow_fsm and master_conf_FSM
            when ST_IDLE =>
                vmmConf_done <= '0';
                vmm_cs_i     <= '1';

                if(top_rdy = '1' and init_ser = '1')then                   
                    st_conf     <= ST_RD_HIGH;
                else
                    st_conf     <= ST_IDLE;
                end if;

            -- assert the rd_ena signal if there is still data in the buffer. also check for 96-bit counter
            when ST_RD_HIGH =>
                if(fifo_empty = '0' and bit_cnt /= "1100000")then
                    rd_ena      <= '1';
                    bit_cnt     <= bit_cnt + 1;
                    vmm_cs_i    <= '0';
                    st_conf     <= ST_RD_LOW;
                elsif(fifo_empty = '0' and bit_cnt = "1100000")then -- 96 bits sent, pull cs high and return to this state
                    rd_ena      <= '0';
                    bit_cnt     <= (others => '0');
                    vmm_cs_i    <= '1';
                    st_conf     <= ST_RD_HIGH;
                else
                    rd_ena  <= '0';
                    bit_cnt <= (others => '0');
                    st_conf <= ST_DONE;
                end if;

            -- wait for the FIFO to pass the bit as there is
            -- some latency (see 'embedded registers' at FIFO generator)
            when ST_RD_LOW =>
                rd_ena  <= '0';
                if(wait_cnt = "11")then
                    wait_cnt    <= (others => '0');
                    vmm_sck     <= '1';
                    st_conf     <= ST_CKTK_LOW;
                else
                    wait_cnt    <= wait_cnt + 1;
                    vmm_sck     <= '0';
                    st_conf     <= ST_RD_LOW;
                end if;

            -- ground CKTK and then check if there is more data left
            when ST_CKTK_LOW =>
                vmm_sck     <= '0';
                st_conf     <= ST_RD_HIGH;

            -- stay here until reset by master config FSM
            when ST_DONE =>
                vmmConf_done    <= '1';
                vmm_cs_i        <= '1';
                st_conf         <= ST_DONE;   

            when others =>
                st_conf <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

-- MUX that drives the VMM configuration data into the FIFO
FIFO_valid_MUX: process(sel_vmm_data, user_valid_udp)
begin
    case sel_vmm_data is
    when '0'    =>  user_valid_fifo <= '0';
    when '1'    =>  user_valid_fifo <= user_valid_udp;
    when others =>  user_valid_fifo <= '0';
    end case;
end process;

-- FIFO that serializes the VMM data
FIFO_serializer: vmm_conf_buffer
    PORT MAP(
        rst     => rst_fifo,
        wr_clk  => clk_125,
        rd_clk  => clk_40,
        din     => user_din_udp,
        wr_en   => user_valid_fifo,
        rd_en   => rd_ena,
        dout(0) => vmm_cfg_bit,
        full    => fifo_full,
        empty   => fifo_empty
      );
      
      vmm_cs <= vmm_cs_i;

end RTL;