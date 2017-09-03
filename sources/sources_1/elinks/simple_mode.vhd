----------------------------------------------------------------------------------
-- Company: NTU ATHNENS - BNL
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
-- Create Date: 02.09.2017 11:39:21
-- Design Name: 
-- Module Name: simple_mode - RTL
-- Project Name: MMFE8 
-- Target Devices: Arix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2017.2
-- Description: This module forwards all elink data to the elink2udp module.
-- 
-- Changelog:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity simple_mode is
Port(
    ---------------------------
    ---- General Interface ----
    clk_elink   : in  std_logic;
    rst_rx      : in  std_logic;
    ---------------------------
    -- Elink/Filter Interface -
    empty_fifo  : in  std_logic;
    rd_en_fifo  : out std_logic;
    din_fifo    : in  std_logic_vector(15 downto 0);
    ---------------------------
    --- elink2udp Interface ---
    wr_en_len   : out std_logic;
    wr_en_daq   : out std_logic;
    dout_len    : out std_logic_vector(15 downto 0);
    dout_daq    : out std_logic_vector(15 downto 0)
    );
end simple_mode;

architecture RTL of simple_mode is
    
    signal packLen_cnt  : unsigned(15 downto 0)         := (others => '0');
    signal wait_cnt     : unsigned(1 downto 0)          := (others => '0');
    signal dbg_spl_fsm  : std_logic_vector(3 downto 0)  := (others => '0');

    type stateType_wrFSM is (ST_IDLE, ST_WAIT, ST_WR_WORD, ST_CHK_CNT, ST_WR_LEN, ST_DONE);
    signal state_wr         : stateType_wrFSM := ST_IDLE;

    attribute FSM_ENCODING              : string;
    attribute FSM_ENCODING of state_wr  : signal is "ONE_HOT";
    
begin

-- FSM that writes the data to the two FIFOs
FSM_wr_simple: process(clk_elink)
begin
    if(rising_edge(clk_elink))then
        if(rst_rx = '1')then
            packLen_cnt <= (others => '0');
            wr_en_len   <= '0';
            wr_en_daq   <= '0';
            rd_en_fifo  <= '0';
            wait_cnt    <= (others => '0');
            dbg_spl_fsm <= (others => '0');
            state_wr    <= ST_IDLE; 
        else
            case state_wr is

            -- is the elink/filter fifo empty?
            when ST_IDLE =>
                wr_en_len   <= '0';
                wr_en_daq   <= '0';
                dbg_spl_fsm <= "0001";

                if(empty_fifo = '0')then
                    rd_en_fifo  <= '1';
                    state_wr    <= ST_WAIT; -- to ST_WR_WORD
                else
                    rd_en_fifo  <= '0';
                    state_wr    <= ST_IDLE;
                end if;

            -- generic state that waits...
            when ST_WAIT =>
                rd_en_fifo  <= '0';
                dbg_spl_fsm <= "0010";
                wait_cnt    <= wait_cnt + 1;
                if(wait_cnt = "11")then
                    state_wr    <= ST_WR_WORD;
                else
                    state_wr    <= ST_WAIT;
                end if;

            when ST_WR_WORD =>
                dbg_spl_fsm <= "0011";
                wr_en_daq   <= '1';
                packLen_cnt <= packLen_cnt + 2; -- two bytes in each word 
                state_wr    <= ST_CHK_CNT;
                
            when ST_CHK_CNT =>
                dbg_spl_fsm <= "0100";
                wr_en_daq   <= '0';
                if(packLen_cnt = 32)then -- one kbyte ready to be sent (1024) (must be even number)
                    wr_en_len   <= '1';
                    state_wr    <= ST_WR_LEN;
                else
                    wr_en_len   <= '0';
                    state_wr    <= ST_IDLE;
                end if;

            -- write the length of the packet to the length FIFO
            when ST_WR_LEN =>
                dbg_spl_fsm <= "0101";
                wr_en_len   <= '0';
                state_wr    <= ST_DONE;

            -- back to IDLE
            when ST_DONE =>
                dbg_spl_fsm <= "0110";
                packLen_cnt <= (others => '0');
                state_wr    <= ST_IDLE;

            when others => 
                packLen_cnt <= (others => '0');
                wr_en_len   <= '0';
                wr_en_daq   <= '0';
                rd_en_fifo  <= '0';
                dbg_spl_fsm <= (others => '0');
                wait_cnt    <= (others => '0');
                state_wr    <= ST_IDLE;

            end case;
        end if;
    end if;
end process;

    dout_len    <= std_logic_vector(packLen_cnt);
    dout_daq    <= din_fifo;

end RTL;