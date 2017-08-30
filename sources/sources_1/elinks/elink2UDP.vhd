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
-- Module Name: elink2UDP - RTL
-- Project Name: MMFE8 
-- Target Devices: Arix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2017.2
-- Description: This module acts as an adapter between the receiving side of the
-- elink, and the UDP interface. If a ROC packet is detected, it is forwarded to
-- the UDP blocks as-is. If the data rate from the elink receiving side is too
-- large, then a mechanicsm that blinks LEDs will be activated.
-- 
-- Changelog:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity elink2UDP is
port(
    ---------------------------
    ---- General Interface ----
    clk_elink       : in  std_logic;
    clk_udp         : in  std_logic;
    rst_rx          : in  std_logic;
    error_led       : out std_logic; -- indicating the data flow is too high
    ---------------------------
    ---- Elink Interface ------
    empty_elink     : in  std_logic;
    rd_en_elink     : out std_logic;
    din_elink       : in  std_logic_vector(15 downto 0);
    ---------------------------
    ---- UDP Interface --------
    udp_tx_dout_rdy : in std_logic;
    udp_tx_start    : out std_logic;
    udp_txi         : out udp_tx_type
    );
end elink2UDP;

architecture RTL of elink2UDP is

component elink2UDP_daq
  port (
    rst         : in  std_logic;
    wr_clk      : in  std_logic;
    rd_clk      : in  std_logic;
    din         : in  std_logic_vector(15 downto 0);
    wr_en       : in  std_logic;
    rd_en       : in  std_logic;
    dout        : out std_logic_vector(7 downto 0);
    full        : out std_logic;
    empty       : out std_logic;
    wr_rst_busy : out std_logic;
    rd_rst_busy : out std_logic
  );
end component;

component elink2UDP_len
  port (
    rst         : in  std_logic;
    wr_clk      : in  std_logic;
    rd_clk      : in  std_logic;
    din         : in  std_logic_vector(15 downto 0);
    wr_en       : in  std_logic;
    rd_en       : in  std_logic;
    dout        : out std_logic_vector(15 downto 0);
    full        : out std_logic;
    empty       : out std_logic;
    wr_rst_busy : out std_logic;
    rd_rst_busy : out std_logic
  );
end component;

    constant ROC_SOP    : std_logic_vector(7 downto 0) := "00111100"; -- K28.1
    --constant ROC_SOP    : std_logic_vector(7 downto 0) := "10011100"; -- K28.4 
    constant ROC_EOP    : std_logic_vector(7 downto 0) := "11011100"; -- K28.6
    constant destIP     : std_logic_vector(31 downto 0) := x"c0a80010";
    
    signal packLen_cnt  : unsigned(15 downto 0)         := (others => '0');
    signal din_len      : std_logic_vector(15 downto 0) := (others => '0');
    signal packLen_udp  : unsigned(15 downto 0)         := (others => '0');
    signal dout_len     : std_logic_vector(15 downto 0) := (others => '0');
    signal wr_en_len    : std_logic := '0';
    signal wr_en_daq    : std_logic := '0';
    signal wait_cnt     : unsigned(1 downto 0) := (others => '0');
    
    signal rd_en_len    : std_logic := '0';
    signal wait_udp     : unsigned(1 downto 0) := (others => '0');
    signal rd_en_daq    : std_logic := '0';
    signal last         : std_logic := '0';
    signal empty_len    : std_logic := '0';
    signal empty_daq    : std_logic := '0';
    signal full_len     : std_logic := '0';
    signal full_daq     : std_logic := '0';
    signal tx_start_i   : std_logic := '0';
    
    signal dout_last    : std_logic := '0';
    signal dout_valid   : std_logic := '0';
    signal dout_valid_i : std_logic := '0';
    signal dout_daq     : std_logic_vector(7 downto 0) := (others => '0');
    
    signal rst_rx_i     : std_logic := '0';
    signal rst_rx_s     : std_logic := '0';
    signal error_led_i  : std_logic := '0';
    signal error_led_s  : std_logic := '0';

    signal wr_Rbusy_len : std_logic := '0';  
    signal rd_Rbusy_len : std_logic := '0';
    signal wr_Rbusy_daq : std_logic := '0';  
    signal rd_Rbusy_daq : std_logic := '0';

    attribute ASYNC_REG                 : string;
    attribute ASYNC_REG of rst_rx_i     : signal is "TRUE";
    attribute ASYNC_REG of rst_rx_s     : signal is "TRUE";
    attribute ASYNC_REG of error_led_s  : signal is "TRUE";
    attribute ASYNC_REG of error_led    : signal is "TRUE";

    type stateType_wrFSM is (ST_IDLE, ST_CHK_SOP, ST_WR_WORD, ST_CHK_FIFO, ST_CHK_EOP, ST_WR_EOP, ST_WR_LEN, ST_WAIT, ST_DONE);
    signal state_wr         : stateType_wrFSM := ST_IDLE;
    signal state_prv        : stateType_wrFSM := ST_IDLE;

    type stateType_udpFSM is (ST_IDLE, ST_WAIT, ST_START, ST_CHK_RDY, ST_RD_FIFO, ST_DONE);
    signal state_udp         : stateType_udpFSM := ST_IDLE;

    attribute FSM_ENCODING              : string;
    attribute FSM_ENCODING of state_wr  : signal is "ONE_HOT";
    attribute FSM_ENCODING of state_udp : signal is "ONE_HOT";
    

begin

-- FSM that writes the data to the two FIFOs
FSM_wr_din: process(clk_elink)
begin
    if(rising_edge(clk_elink))then
        if(rst_rx = '1')then
            packLen_cnt <= (others => '0');
            wr_en_len   <= '0';
            wr_en_daq   <= '0';
            rd_en_elink <= '0';
            error_led_i <= '0';
            wait_cnt    <= (others => '0');
            state_wr    <= ST_IDLE; 
        else
            case state_wr is

            -- is the elink fifo empty?
            when ST_IDLE =>
                packLen_cnt <= (others => '0');
                wr_en_len   <= '0';
                wr_en_daq   <= '0';
                state_prv   <= ST_IDLE;

                if(empty_elink = '0')then
                    rd_en_elink <= '1';
                    state_wr    <= ST_WAIT; -- to ST_CHK_SOP
                else
                    rd_en_elink <= '0';
                    state_wr    <= ST_IDLE;
                end if;

            -- is this the ROC_SOP?
            when ST_CHK_SOP =>
                wait_cnt        <= (others => '0');
                if(din_elink(15 downto 8) = ROC_SOP)then
                    state_wr    <= ST_WR_WORD;
                elsif(din_elink(7 downto 0) = ROC_EOP)then -- missed the SOP, we are too slow
                    error_led_i <= '1';
                    state_wr    <= ST_IDLE;
                else -- not a ROC packet, back to idle
                    state_wr    <= ST_IDLE;
                end if;

            -- write the word
            when ST_WR_WORD =>
                if(full_daq = '1')then
                    error_led_i <= '1';    
                else null;
                end if;

                wr_en_daq   <= '1';
                packLen_cnt <= packLen_cnt + 2; -- two bytes in each word
                state_wr    <= ST_CHK_FIFO;

            -- is the fifo empty?
            when ST_CHK_FIFO =>
                wr_en_daq       <= '0';
                state_prv       <= ST_CHK_FIFO;
                if(empty_elink = '0')then
                    rd_en_elink <= '1';
                    state_wr    <= ST_WAIT; -- to ST_CHK_EOP
                else
                    rd_en_elink <= '0';
                    state_wr    <= ST_CHK_FIFO;
                end if;

            -- is this the ROC_EOP?
            when ST_CHK_EOP =>
                if(din_elink(7 downto 0) = ROC_EOP)then
                    state_wr <= ST_WR_EOP;
                else
                    state_wr <= ST_WR_WORD; -- not EOP, but still a packet...
                end if;

            -- write the ROC EOP
            when ST_WR_EOP =>
                if(full_daq = '1')then
                    error_led_i <= '1';    
                else null;
                end if;

                wait_cnt    <= (others => '0');
                wr_en_daq   <= '1';
                packLen_cnt <= packLen_cnt + 2; -- two bytes in each word
                state_wr    <= ST_WR_LEN;

            -- write the length of the packet to the length FIFO
            when ST_WR_LEN =>
                if(full_len = '1')then
                    error_led_i <= '1';    
                else null;
                end if;

                wr_en_daq   <= '0';
                wr_en_len   <= '1';
                state_wr    <= ST_DONE;

            -- back to IDLE
            when ST_DONE =>
                wr_en_len   <= '0';
                state_wr    <= ST_IDLE;

            -- generic state that waits...
            when ST_WAIT =>
                rd_en_elink     <= '0';
                if(wait_cnt = "10")then
                    case state_prv is
                    when ST_IDLE        => state_wr <= ST_CHK_SOP;
                    when ST_CHK_FIFO    => state_wr <= ST_CHK_EOP;
                    when others         => state_wr <= ST_IDLE; -- error!
                    end case;
                else
                    wait_cnt    <= wait_cnt + 1;
                    state_wr    <= ST_WAIT;
                end if;

            when others => 
                packLen_cnt <= (others => '0');
                wr_en_len   <= '0';
                wr_en_daq   <= '0';
                rd_en_elink <= '0';
                error_led_i <= '0';
                wait_cnt    <= (others => '0');
                state_wr    <= ST_IDLE; 
            end case;
        end if;
    end if;
end process;

-- FSM that reads the data from the FIFOs and forwards them to UDP
FSM_UDP: process(clk_udp)
begin
    if(rising_edge(clk_udp))then
        if(rst_rx_s = '1')then
            rd_en_len   <= '0';
            wait_udp    <= (others => '0');
            tx_start_i  <= '0';
            rd_en_daq   <= '0';
            last        <= '0';
            state_udp   <= ST_IDLE;
        else
            case state_udp is

            -- check the status of the two FIFOs
            when ST_IDLE =>
                if(empty_len = '0' and empty_daq = '0')then -- we have a packet ready
                    rd_en_len <= '1';
                    state_udp <= ST_WAIT;
                else
                    state_udp <= ST_IDLE;
                end if;

            when ST_WAIT =>
                rd_en_len   <= '0';
                wait_udp    <= wait_udp + 1;
                if(wait_udp = "11")then
                    state_udp   <= ST_START;
                else                  
                    state_udp   <= ST_WAIT;
                end if;

            -- start the UDP sending process
            when ST_START =>
                packLen_udp <= unsigned(dout_len);
                tx_start_i  <= '1';
                state_udp   <= ST_CHK_RDY;

            -- if ready, ground the start signal
            when ST_CHK_RDY =>
                if(udp_tx_dout_rdy = '1')then
                    tx_start_i  <= '0';
                    state_udp   <= ST_RD_FIFO;
                else
                    tx_start_i  <= '1';
                    state_udp   <= ST_CHK_RDY;
                end if;

            -- read the FIFO until the entire packet has been read
            when ST_RD_FIFO =>
                packLen_udp <= packLen_udp - 1;
                if(packLen_udp = x"0000")then
                    rd_en_daq   <= '0';
                    last        <= '1';
                    state_udp   <= ST_DONE;
                else
                    rd_en_daq   <= '1';
                    last        <= '0';
                    state_udp   <= ST_RD_FIFO;
                end if;

            when ST_DONE =>
                last        <= '0';
                state_udp   <= ST_IDLE;

            when others =>
                rd_en_len   <= '0';
                wait_udp    <= (others => '0');
                tx_start_i  <= '0';
                rd_en_daq   <= '0';
                last        <= '0';
                state_udp   <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

-- register the USP signals, synchronize the reset and the error_led
reg_udp_proc: process(clk_udp)
begin
    if(rising_edge(clk_udp))then
        -- synchronizer
        error_led_s                 <= error_led_i;
        error_led                   <= error_led_s;

        rst_rx_i                    <= rst_rx;
        rst_rx_s                    <= rst_rx_i;

        udp_txi.hdr.dst_ip_addr     <= destIP;
        udp_txi.hdr.src_port        <= x"19CB";        -- set src and dst ports
        udp_txi.hdr.dst_port        <= x"1778";
        udp_txi.hdr.data_length     <= dout_len;                         
        udp_txi.hdr.checksum        <= x"0000";
        udp_txi.data.data_out_last  <= dout_last;
        udp_txi.data.data_out_valid <= dout_valid;
        udp_txi.data.data_out       <= dout_daq;
        udp_tx_start                <= tx_start_i;

        -- delay 'valid' and 'last' signal to sync with data packet
        dout_valid_i                <= rd_en_daq;
        dout_valid                  <= dout_valid_i;
        dout_last                   <= last; 
    end if;
end process;

FIFO_length: elink2UDP_daq
  port map (
    rst         => rst_rx,
    wr_clk      => clk_elink,
    rd_clk      => clk_udp,
    din         => din_elink,
    wr_en       => wr_en_daq,
    rd_en       => rd_en_daq,
    dout        => dout_daq,
    full        => full_daq,
    empty       => empty_daq,
    wr_rst_busy => wr_Rbusy_daq,
    rd_rst_busy => rd_Rbusy_daq
  ); 

FIFO_daq: elink2UDP_len
  port map (
    rst         => rst_rx,
    wr_clk      => clk_elink,
    rd_clk      => clk_udp,
    din         => din_len,
    wr_en       => wr_en_len,
    rd_en       => rd_en_len,
    dout        => dout_len,
    full        => full_len,
    empty       => empty_len,
    wr_rst_busy => wr_Rbusy_len,
    rd_rst_busy => rd_Rbusy_len
   );

    din_len   <= std_logic_vector(packLen_cnt);

end RTL;
