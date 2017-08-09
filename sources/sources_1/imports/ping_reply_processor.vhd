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
-- Create Date: 02.04.2017
-- Design Name: Ping Reply Processor
-- Module Name: ping_reply_processor - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: Vivado 2016.2
-- Description: This module receives a ping/echo request packet from ICMP_RX and 
-- forwards an appropriate echo reply to ICMP_TX.
-- 
-- Dependencies: Xilinx FIFO IP
-- 
-- Changelog:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.axi.all;
use work.ipv4_types.all;

entity ping_reply_processor is
    Port(
        -- ICMP RX interface
        icmp_rx_start           : in std_logic;
        icmp_rxi                : in icmp_rx_type;
        -- system signals
        tx_clk                  : in std_logic;
        rx_clk                  : in std_logic;
        reset                   : in std_logic;
        fifo_init               : in std_logic;
        -- ICMP/UDP mux interface
        sel_icmp                : out std_logic;
        -- ICMP TX interface
        icmp_tx_start           : out std_logic;
        icmp_tx_ready           : in  std_logic;
        icmp_txo                : out icmp_tx_type;
        icmp_tx_is_idle         : in  std_logic
    );
end ping_reply_processor;

architecture Behavioral of ping_reply_processor is

    COMPONENT icmp_payload_buffer
        PORT(
        rst     : IN STD_LOGIC;
        wr_clk  : IN STD_LOGIC;
        rd_clk  : IN STD_LOGIC;
        din     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        wr_en   : IN STD_LOGIC;
        rd_en   : IN STD_LOGIC;
        dout    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        full    : OUT STD_LOGIC;
        empty   : OUT STD_LOGIC
        );
    END COMPONENT;

    type rx_state_type   is (IDLE, CNT_LEN, CHK_TYPE_CODE, WAIT_FOR_TX);
    type tx_state_type   is (IDLE, SET_HDR, START, WAIT_FOR_EMPTY, DELAY);

    signal ping_rx_state  : rx_state_type    := IDLE;
    signal ping_tx_state  : tx_state_type    := IDLE;
    
    signal payLen_count_ug      : unsigned (15 downto 0) := (others => '0');
    signal chksum_out_ug        : unsigned (15 downto 0) := (others => '0');
    signal tx_ena               : std_logic := '0';

    signal rd_ena               : std_logic := '0';
    signal rst_fifo_fsm         : std_logic := '0';
    signal rst_fifo             : std_logic := '0'; 
    signal fifo_empty           : std_logic := '0';
    signal fifo_full            : std_logic := '0';
    signal data_last            : std_logic := '0';
    signal data_valid           : std_logic := '0';
    signal data_valid_reg       : std_logic := '0';

begin

    --------------------------------------------------------------------------
    -- combinatorial process to implement FSM RX and determine control signals
    --------------------------------------------------------------------------

ping_FSM_RX: process(rx_clk)
begin
    if(rising_edge(rx_clk))then
        if(reset = '1')then
            payLen_count_ug <= (others => '0');
            chksum_out_ug   <= (others => '0');
            tx_ena          <= '0';
            ping_rx_state   <= IDLE;
        else
            case ping_rx_state is

            when IDLE =>
                if(icmp_rx_start = '1' and icmp_rxi.hdr.icmp_type = x"08")then
                    if(icmp_rxi.payload.data_in_valid = '1' and icmp_rxi.payload.data_in_last = '0')then
                        payLen_count_ug <= payLen_count_ug + 1;
                        ping_rx_state   <= CNT_LEN;
                    elsif(icmp_rx_start = '1' and icmp_rxi.payload.data_in_valid = '1' and icmp_rxi.payload.data_in_last = '1')then
                    -- payload is only one-byte long
                        payLen_count_ug <= payLen_count_ug + 1;
                        ping_rx_state   <= CHK_TYPE_CODE;
                    else
                        ping_rx_state   <= IDLE;
                    end if;
                else
                    payLen_count_ug <= (others => '0');
                    chksum_out_ug   <= (others => '0');
                    tx_ena          <= '0';
                    ping_rx_state   <= IDLE;
                end if;
                    

            when CNT_LEN =>           

                payLen_count_ug <= payLen_count_ug + 1;

                if(icmp_rxi.payload.data_in_last = '1')then
                    chksum_out_ug   <= unsigned(icmp_rxi.hdr.icmp_chksum);
                    ping_rx_state   <= CHK_TYPE_CODE;
                else
                    ping_rx_state   <= CNT_LEN;
                end if;

            when CHK_TYPE_CODE =>            

                if(icmp_rxi.hdr.icmp_type = x"08" and icmp_rxi.hdr.icmp_code = x"00")then -- echo request
                    chksum_out_ug   <= chksum_out_ug + "0000100000000000"; -- plus 2048 in dec
                    payLen_count_ug <= payLen_count_ug;
                    tx_ena          <= '1';
                    ping_rx_state   <= WAIT_FOR_TX;
                else
                    chksum_out_ug   <= (others => '0');
                    payLen_count_ug <= (others => '0');
                    tx_ena          <= '0';
                    ping_rx_state   <= IDLE;
                end if;

            when WAIT_FOR_TX =>               
                
                chksum_out_ug   <= chksum_out_ug;
                if(fifo_empty = '1')then
                    tx_ena          <= '0';
                    ping_rx_state   <= IDLE;
                else
                    tx_ena          <= '1';
                    ping_rx_state   <= WAIT_FOR_TX;    
                end if;

            when others =>
                ping_rx_state <= IDLE;
            end case;
        end if;
    end if;
end process;

ping_FSM_TX: process(tx_clk)
begin
    if(rising_edge(tx_clk))then
        if(reset = '1')then
            rd_ena          <= '0';
            rst_fifo_fsm    <= '0';
            data_last       <= '0';
            data_valid      <= '0';
            icmp_tx_start   <= '0';
            sel_icmp        <= '0';
            ping_tx_state   <= IDLE;
        else
            case ping_tx_state is
            when IDLE =>
                rst_fifo_fsm <= '0';

                if(tx_ena = '1')then
                    sel_icmp        <= '1';
                    ping_tx_state   <= SET_HDR;
                else
                    sel_icmp        <= '0';
                    ping_tx_state   <= IDLE;
                end if;

            when SET_HDR =>
                icmp_txo.hdr.dst_ip_addr    <= icmp_rxi.hdr.src_ip_addr;
                icmp_txo.hdr.icmp_pay_len   <= std_logic_vector(payLen_count_ug); -- payload length in bytes
                ------------------------
                icmp_txo.hdr.icmp_type      <= x"00";                             -- reply
                icmp_txo.hdr.icmp_code      <= x"00";                             -- reply
                icmp_txo.hdr.icmp_chksum    <= std_logic_vector(chksum_out_ug);   -- old checksum + 2048(in dec)
                icmp_txo.hdr.icmp_ident     <= icmp_rxi.hdr.icmp_ident;           -- CC
                icmp_txo.hdr.icmp_seqNum    <= icmp_rxi.hdr.icmp_seqNum;          -- CC

                icmp_tx_start   <= '1';
                ping_tx_state   <= START;

            when START =>
                if(icmp_tx_ready = '1')then
                    rd_ena          <= '1';
                    data_valid      <= '1';
                    icmp_tx_start   <= '0';
                    ping_tx_state   <= WAIT_FOR_EMPTY;
                else
                    rd_ena          <= '0';
                    data_valid      <= '0';
                    icmp_tx_start   <= '1';
                    ping_tx_state   <= START;
                end if;

            when WAIT_FOR_EMPTY =>
                if(fifo_empty = '1')then
                    rd_ena          <= '0';
                    data_valid      <= '0';
                    data_last       <= '1';
                    rst_fifo_fsm    <= '1';
                    ping_tx_state   <= DELAY;
                else
                    rd_ena          <= '1';
                    data_valid      <= '1';
                    data_last       <= '0';
                    ping_tx_state   <= WAIT_FOR_EMPTY;
                end if;

            when DELAY =>
                data_last       <= '0';
                rst_fifo_fsm    <= '1';

                if(icmp_tx_is_idle = '1')then
                    ping_tx_state   <= IDLE;
                else
                    ping_tx_state   <= DELAY;
                end if;

            when others =>
                ping_tx_state <= IDLE;
            end case;
        end if;
    end if;
end process;

fdre_valid_0 : process(tx_clk)
begin
    if(rising_edge(tx_clk))then
        if(reset = '1')then
            data_valid_reg <= '0';
        else
            data_valid_reg <= data_valid;
        end if;
    end if;
end process;

fdre_valid_1 : process(tx_clk)
begin
    if(rising_edge(tx_clk))then
        if(reset = '1')then
            icmp_txo.payload.data_out_valid <= '0';
        else
            icmp_txo.payload.data_out_valid <= data_valid_reg;
        end if;
    end if;
end process;

fifo_payload_buffer: icmp_payload_buffer
    PORT MAP (
        rst     => rst_fifo,
        wr_clk  => rx_clk,
        rd_clk  => tx_clk,
        din     => icmp_rxi.payload.data_in,
        wr_en   => icmp_rxi.payload.data_in_valid,
        rd_en   => rd_ena,
        dout    => icmp_txo.payload.data_out,
        full    => fifo_full,
        empty   => fifo_empty
    );
 
    icmp_txo.payload.data_out_last  <= data_last;
    rst_fifo                        <= rst_fifo_fsm or fifo_init;

end Behavioral;


