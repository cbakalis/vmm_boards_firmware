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
-- Create Date: 30.08.2017 11:39:21
-- Design Name: 
-- Module Name: roc2udp - RTL
-- Project Name: MMFE8 
-- Target Devices: Arix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2017.2
-- Description: This module acts as an adapter between the receiving side of the
-- elink, and the UDP interface. If a ROC packet is detected, it is forwarded to
-- the UDP blocks as-is.
-- 
-- Changelog:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
--use work.axi.all;
--use work.ipv4_types.all;
--use work.arp_types.all;

entity roc2udp is
Generic (real_roc : std_logic);
Port(
    ---------------------------
    ---- General Interface ----
    clk_elink   : in  std_logic;
    rst_rx      : in  std_logic;
    fsm_roc_o   : out std_logic_vector(3 downto 0);
    ---------------------------
    -- Elink/Filter Interface -
    empty_fifo  : in  std_logic;
    rd_en_fifo  : out std_logic;
    din_fifo    : in  std_logic_vector(15 downto 0);
    ---------------------------
    --- elink2udp Interface ---
    full_daq    : in  std_logic;
    full_len    : in  std_logic;
    empty_len   : in  std_logic;
    udp_tx_busy : in  std_logic;
    flush_daq   : out std_logic;
    wr_en_len   : out std_logic;
    wr_en_daq   : out std_logic;
    dout_len    : out std_logic_vector(15 downto 0);
    dout_daq    : out std_logic_vector(15 downto 0)
    );
end roc2udp;

architecture RTL of roc2udp is

    constant ROC_SOP        : std_logic_vector(7 downto 0) := "00111100"; -- K28.1
    --constant ROC_SOP        : std_logic_vector(7 downto 0) := "10011100"; -- K28.4 
    constant ROC_EOP        : std_logic_vector(7 downto 0) := "11011100"; -- K28.6
    
    signal packLen_cnt      : unsigned(15 downto 0)         := (others => '0');
    signal wait_cnt         : unsigned(1 downto 0)          := (others => '0');
    
    signal hitsLen          : unsigned(9 downto 0)          := (others => '0');
    signal din_prev         : std_logic_vector(15 downto 0) := (others => '0');
    
    signal dbg_roc_fsm      : std_logic_vector(3 downto 0)  := (others => '0');
    
    signal udp_tx_busy_i    : std_logic := '0';
    signal udp_tx_busy_s    : std_logic := '0';
    signal empty_len_i      : std_logic := '0';
    signal empty_len_s      : std_logic := '0';

    type stateType_wrFSM is (ST_IDLE, ST_CHK_SOP, ST_WR_WORD, ST_CHK_FIFO, ST_CHK_WORD, ST_CHK_EOP_0, 
                             ST_CHK_EOP_1, ST_WR_LEN, ST_WAIT, ST_CHK_UDP,  ST_ERROR, ST_DONE);
    signal state_wr         : stateType_wrFSM := ST_IDLE;
    signal state_prv        : stateType_wrFSM := ST_IDLE;

    attribute FSM_ENCODING                  : string;
    attribute FSM_ENCODING of state_wr      : signal is "ONE_HOT";
    
    attribute ASYNC_REG                     : string;
    attribute ASYNC_REG of udp_tx_busy_i    : signal is "TRUE";
    attribute ASYNC_REG of udp_tx_busy_s    : signal is "TRUE";
    attribute ASYNC_REG of empty_len_i      : signal is "TRUE";
    attribute ASYNC_REG of empty_len_s      : signal is "TRUE";

begin

-- FSM that writes the data to the two FIFOs
FSM_wr_roc: process(clk_elink)
begin
    if(rising_edge(clk_elink))then
        if(rst_rx = '1')then
            packLen_cnt <= (others => '0');
            wr_en_len   <= '0';
            wr_en_daq   <= '0';
            rd_en_fifo  <= '0';
            flush_daq   <= '0';
            wait_cnt    <= (others => '0');
            dbg_roc_fsm <= (others => '0');
            state_wr    <= ST_IDLE; 
        else
            case state_wr is

            -- is the elink/filter fifo empty?
            when ST_IDLE =>
                packLen_cnt <= (others => '0');
                wr_en_len   <= '0';
                wr_en_daq   <= '0';
                flush_daq   <= '0';
                state_prv   <= ST_IDLE;
                dbg_roc_fsm <= "0001";

                if(empty_fifo = '0')then
                    rd_en_fifo  <= '1';
                    state_wr    <= ST_WAIT; -- to ST_CHK_SOP
                else
                    rd_en_fifo  <= '0';
                    state_wr    <= ST_IDLE;
                end if;

            -- is this the ROC_SOP? (1st byte is always ROC_SOP and T is always zero)
            when ST_CHK_SOP =>
                dbg_roc_fsm     <= "0010";
                if(din_fifo(15 downto 8) = ROC_SOP and din_fifo(7) = '0')then
                    state_wr    <= ST_WR_WORD;
                else -- not a ROC packet, back to idle
                    state_wr    <= ST_IDLE;
                end if;

            -- write the word
            when ST_WR_WORD =>
                dbg_roc_fsm <= "0011";
                din_prev    <= din_fifo;
                
                if(packLen_cnt >= 2060)then
                    wr_en_daq   <= '0';
                    state_wr    <= ST_CHK_UDP; -- error!      
                elsif(state_prv = ST_CHK_EOP_1)then
                    wr_en_daq   <= '0'; -- no need to write
                    packLen_cnt <= packLen_cnt;
                    state_wr    <= ST_CHK_FIFO;
                elsif(full_daq = '1')then
                    wr_en_daq   <= '0'; -- hold before writing
                    packLen_cnt <= packLen_cnt;
                    state_wr    <= ST_WR_WORD;
                else
                    wr_en_daq   <= '1';
                    packLen_cnt <= packLen_cnt + 2; -- two bytes in each word 
                    state_wr    <= ST_CHK_FIFO;
                end if;         

            -- is the fifo empty?
            when ST_CHK_FIFO =>
                dbg_roc_fsm <= "0100";
                wr_en_daq   <= '0';
                state_prv   <= ST_CHK_FIFO;
                if(empty_fifo = '0')then
                    rd_en_fifo  <= '1';
                    state_wr    <= ST_WAIT; -- to ST_CHK_WORD
                else
                    rd_en_fifo  <= '0';
                    state_wr    <= ST_CHK_FIFO;
                end if;

            ------ ROC EOP checking -------
            -------------------------------

            -- check the word
            when ST_CHK_WORD =>
                dbg_roc_fsm     <= "0101";
                if(real_roc = '0' and packLen_cnt = 2 and din_fifo(7 downto 0) /= x"00")then
                    state_wr    <= ST_CHK_UDP; -- ERROR: that was not the real SOP, since the FPGA uses only the 8 LSB of the event_counter
                elsif(real_roc = '0' and din_fifo (15 downto 8) = x"00" and din_fifo(7 downto 0) = ROC_EOP)then -- probably ROC trailer from FPGA (no checksum)
                    state_wr    <= ST_CHK_EOP_0;
                elsif(real_roc = '1' and din_fifo(7 downto 0) = ROC_EOP)then -- that was the EOP (add checksum check?)
                    state_wr    <= ST_CHK_EOP_0;
                else
                    state_wr    <= ST_WR_WORD; -- not EOP, but still a packet...
                end if;

            -- is this the ROC EOP?
            when ST_CHK_EOP_0 =>
                dbg_roc_fsm <= "0110";
                if(full_daq = '0')then
                    wr_en_daq   <= '1';
                    packLen_cnt <= packLen_cnt + 2; -- two bytes in each word
                    state_wr    <= ST_CHK_EOP_1;
                else
                    wr_en_daq   <= '0';
                    packLen_cnt <= packLen_cnt; -- hold before writing
                    state_wr    <= ST_CHK_EOP_0;
                end if;

            -- two checks, either a null packet, or a real EOP
            when ST_CHK_EOP_1 =>
                dbg_roc_fsm <= "0111";
                wr_en_daq   <= '0';
                state_prv   <= ST_CHK_EOP_1;
                if(packLen_cnt = 4)then -- 4 bytes = null event
                    state_wr    <= ST_WR_LEN;
                elsif(hitsLen*4 + 10 = packLen_cnt)then -- 4 bytes in each hit data + 10(header+trl)
                    state_wr    <= ST_WR_LEN;
                else
                    state_wr    <= ST_WR_WORD; -- not the real EOP
                end if;

            -----------------------------
            -----------------------------
            -- write the length of the packet to the length FIFO
            when ST_WR_LEN =>
                dbg_roc_fsm <= "1000";
                wr_en_daq   <= '0';
                if(full_len = '0')then
                    wr_en_len   <= '1';
                    state_wr    <= ST_DONE;
                else
                    wr_en_len   <= '0'; -- hold if full
                    state_wr    <= ST_WR_LEN;
                end if;

            -- back to IDLE
            when ST_DONE =>
                dbg_roc_fsm <= "1010";
                wr_en_len   <= '0';
                state_wr    <= ST_IDLE;

            -- generic state that waits...
            when ST_WAIT =>
                rd_en_fifo  <= '0';
                dbg_roc_fsm <= "1001";
                wait_cnt    <= wait_cnt + 1;
                if(wait_cnt = "11")then
                    case state_prv is
                    when ST_IDLE        => state_wr <= ST_CHK_SOP;
                    when ST_CHK_FIFO    => state_wr <= ST_CHK_WORD;
                    when others         => state_wr <= ST_IDLE; -- error!
                    end case;
                else
                    state_wr    <= ST_WAIT;
                end if;

            -- wrote too many packets, or either detected fake SOP, or missed real EOP.
            -- wait for the elink2udp to finish sending, flush, and jump back to IDLE
            when ST_CHK_UDP =>
                dbg_roc_fsm <= "1111";
                packLen_cnt <= (others => '0');
                wr_en_len   <= '0';
                wr_en_daq   <= '0';
                rd_en_fifo  <= '0';
                flush_daq   <= '0';
                wait_cnt    <= (others => '0');

                if(empty_len_s = '1' and udp_tx_busy_s = '0')then
                    state_wr    <= ST_ERROR;
                else
                    state_wr    <= ST_CHK_UDP;
                end if;

            -- create a flush pulse of adequate length
            when ST_ERROR =>
                flush_daq   <= '1';
                wait_cnt    <= wait_cnt + 1;
                if(wait_cnt = "11")then
                    state_wr    <= ST_IDLE;
                else
                    state_wr    <= ST_ERROR;
                end if;

            when others => 
                packLen_cnt <= (others => '0');
                wr_en_len   <= '0';
                wr_en_daq   <= '0';
                rd_en_fifo  <= '0';
                flush_daq   <= '0';
                dbg_roc_fsm <= (others => '0');
                wait_cnt    <= (others => '0');
                state_wr    <= ST_IDLE;

            end case;
        end if;
    end if;
end process;

syncFIFOsigs_proc: process(clk_elink)
begin
    if(rising_edge(clk_elink))then
        udp_tx_busy_i <=  udp_tx_busy;
        udp_tx_busy_s <=  udp_tx_busy_i;
        empty_len_i   <= empty_len;
        empty_len_s   <= empty_len_i;
    end if;
end process;

    hitsLen     <= unsigned(din_prev(9 downto 0));
    dout_len    <= std_logic_vector(packLen_cnt);
    dout_daq    <= din_fifo;
    fsm_roc_o   <= dbg_roc_fsm;

end RTL;
