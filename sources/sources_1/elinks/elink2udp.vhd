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
-- Module Name: elink2udp - RTL
-- Project Name: MMFE8 
-- Target Devices: Arix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2017.2
-- Description: This module forwards the data to the UDP interface.
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

entity elink2udp is
Port(
    ---------------------------
    ---- General Interface ----
    clk_elink       : in  std_logic;
    clk_udp         : in  std_logic;
    rst_rx          : in  std_logic;
    rst_rx_125      : out std_logic;
    flush_rx        : in  std_logic;
    ---------------------------
    ---- roc2udp Interface ----
    flush_daq       : in  std_logic;
    wr_en_len       : in  std_logic;
    wr_en_daq       : in  std_logic;
    din_len         : in  std_logic_vector(15 downto 0);
    din_daq         : in  std_logic_vector(15 downto 0);
    full_len        : out std_logic;
    full_daq        : out std_logic;
    empty_len       : out std_logic;
    udp_tx_busy     : out std_logic;
    ---------------------------
    ---- UDP Interface --------
    udp_tx_dout_rdy : in std_logic;
    udp_tx_start    : out std_logic;
    udp_txi         : out udp_tx_type
    );
end elink2udp;

architecture RTL of elink2udp is

component  elink2UDP_daq
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

    
    signal packLen_udp  : unsigned(15 downto 0)         := (others => '0');
    signal dout_len     : std_logic_vector(15 downto 0) := (others => '0');
    
    signal rd_en_len    : std_logic := '0';
    signal wait_udp     : unsigned(1 downto 0) := (others => '0');
    signal rd_en_daq    : std_logic := '0';
    signal last         : std_logic := '0';
    signal empty_len_i  : std_logic := '0';
    signal empty_daq    : std_logic := '0';
    signal tx_start_i   : std_logic := '0';
    
    signal dout_last    : std_logic := '0';
    signal dout_valid   : std_logic := '0';
    signal dout_valid_i : std_logic := '0';
    signal dout_daq     : std_logic_vector(7 downto 0) := (others => '0');
    
    signal rst_rx_i     : std_logic := '0';
    signal rst_rx_s     : std_logic := '0';

    signal wr_Rbusy_len : std_logic := '0';  
    signal rd_Rbusy_len : std_logic := '0';
    signal wr_Rbusy_daq : std_logic := '0';  
    signal rd_Rbusy_daq : std_logic := '0';
    
    signal flush_daq_i  : std_logic := '0';

    attribute ASYNC_REG                 : string;
    attribute ASYNC_REG of rst_rx_i     : signal is "TRUE";
    attribute ASYNC_REG of rst_rx_s     : signal is "TRUE";
    
    signal debug_wr_fsm  : std_logic_vector(3 downto 0) := (others => '0');
    signal dbg_udp_fsm : std_logic_vector(3 downto 0) := (others => '0');

    type stateType_udpFSM is (ST_IDLE, ST_WAIT, ST_START, ST_CHK_RDY, ST_RD_FIFO, ST_DONE);
    signal state_udp         : stateType_udpFSM := ST_IDLE;

    attribute FSM_ENCODING              : string;
    attribute FSM_ENCODING of state_udp : signal is "ONE_HOT";
    
begin

-- FSM that reads the data from the FIFOs and forwards them to UDP
FSM_UDP: process(clk_udp)
begin
    if(rising_edge(clk_udp))then
        if(rst_rx_s = '1')then
            rd_en_len   <= '0';
            wait_udp    <= (others => '0');
            dbg_udp_fsm <= (others => '0');
            tx_start_i  <= '0';
            udp_tx_busy <= '0';
            rd_en_daq   <= '0';
            last        <= '0';
            state_udp   <= ST_IDLE;
        else
            case state_udp is

            -- check the status of the two FIFOs
            when ST_IDLE =>
                dbg_udp_fsm <= "0001";
                udp_tx_busy <= '0';
                if(empty_len_i = '0' and empty_daq = '0')then -- we have a packet ready
                    rd_en_len <= '1';
                    state_udp <= ST_WAIT;
                else
                    rd_en_len <= '0';
                    state_udp <= ST_IDLE;
                end if;

            when ST_WAIT =>
                dbg_udp_fsm <= "0010";
                rd_en_len   <= '0';
                udp_tx_busy <= '1';
                wait_udp    <= wait_udp + 1;
                if(wait_udp = "11")then
                    state_udp   <= ST_START;
                else                  
                    state_udp   <= ST_WAIT;
                end if;

            -- start the UDP sending process
            when ST_START =>
                dbg_udp_fsm <= "0011";
                packLen_udp <= unsigned(dout_len);
                tx_start_i  <= '1';
                state_udp   <= ST_CHK_RDY;

            -- if ready, ground the start signal
            when ST_CHK_RDY =>
                dbg_udp_fsm <= "0100";
                if(udp_tx_dout_rdy = '1')then
                    tx_start_i  <= '0';
                    state_udp   <= ST_RD_FIFO;
                else
                    tx_start_i  <= '1';
                    state_udp   <= ST_CHK_RDY;
                end if;

            -- read the FIFO until the entire packet has been read
            when ST_RD_FIFO =>
                dbg_udp_fsm <= "0101";
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
                dbg_udp_fsm <= "0110";
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

        rst_rx_i    <= rst_rx;
        rst_rx_s    <= rst_rx_i;

        udp_txi.hdr.dst_ip_addr     <= destinationIP;         -- set a generic ip adrress (192.168.0.255)
        udp_txi.hdr.src_port        <= x"19CB";               -- set src and dst ports
        udp_txi.hdr.dst_port        <= x"1778";
        udp_txi.hdr.data_length     <= dout_len;                         
        udp_txi.hdr.checksum        <= x"0000";
        udp_txi.data.data_out_last  <= data_out_last;
        udp_txi.data.data_out_valid <= data_out_valid;
        udp_txi.data.data_out       <= data_out;
        udp_tx_start                <= tx_start_i;

        dout_valid_i       <= rd_en_daq;
        dout_valid         <= dout_valid_i;
        dout_last          <= last; 
    end if;
end process;

    rst_rx_125  <= rst_rx_s;
    flush_daq_i <= flush_daq or flush_rx;

FIFO_daq: elink2UDP_daq
  port map (
    rst         => flush_daq_i,
    wr_clk      => clk_elink,
    rd_clk      => clk_udp,
    din         => din_daq,
    wr_en       => wr_en_daq,
    rd_en       => rd_en_daq,
    dout        => dout_daq,
    full        => full_daq,
    empty       => empty_daq,
    wr_rst_busy => wr_Rbusy_daq,
    rd_rst_busy => rd_Rbusy_daq
  ); 

FIFO_length: elink2UDP_len
  port map (
    rst         => flush_rx,
    wr_clk      => clk_elink,
    rd_clk      => clk_udp,
    din         => din_len,
    wr_en       => wr_en_len,
    rd_en       => rd_en_len,
    dout        => dout_len,
    full        => full_len,
    empty       => empty_len_i,
    wr_rst_busy => wr_Rbusy_len,
    rd_rst_busy => rd_Rbusy_len
   );
   
   empty_len <= empty_len_i;

end RTL;
