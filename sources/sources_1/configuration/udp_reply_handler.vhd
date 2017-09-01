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
-- Create Date: 25.04.2017 11:05:21
-- Design Name: UDP Reply Handler
-- Module Name: udp_reply_handler - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: Module that sends UDP replies to the configuration software 
-- via UDP.
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity udp_reply_handler is
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk             : in  std_logic;
        enable          : in  std_logic;
        serial_number   : in  std_logic_vector(31 downto 0);
        bit_mask        : in  std_logic_vector(7 downto 0);
        command         : in  std_logic_vector(15 downto 0);
        vmm_d_in        : in  std_logic;
        vmm_sck         : in  std_logic;
        second_rd_start : in  std_logic;
        sample_end      : in  std_logic;
        reply_done      : out std_logic;
        reply_st_o      : out std_logic_vector(3 downto 0);
        head_wr_done    : out std_logic;
        second_rcv      : out std_logic;
        vmm_fsm_reset   : in  std_logic;   
        ------------------------------------
        ---- FIFO Data Select Interface ----
        wr_en_conf      : out std_logic;
        dout_conf       : out std_logic_vector(15 downto 0);
        packet_len_conf : out std_logic_vector(11 downto 0);
        end_conf        : out std_logic       
    );
end udp_reply_handler;

architecture RTL of udp_reply_handler is

    signal sn_i          : std_logic_vector(31 downto 0) := (others => '0');
    signal bit_mask_i    : std_logic_vector(7 downto 0)  := (others => '0');
    signal command_i     : std_logic_vector(15 downto 0) := (others => '0');
    signal cnt_packet    : unsigned(11 downto 0)         := (others => '0');
    signal cnt_len       : integer range 0 to 2048       := 0;
    signal buff_vector   : std_logic_vector(15 downto 0) := (others => '0');
    signal buff_bit_cnt  : integer range 0 to 15         := 0;
    signal reply_st      : std_logic_vector(3 downto 0)  := "0000";
    signal udp_cnt       : unsigned(11 downto 0 ) := (others => '0');
    
    signal vmm_sck_0     : std_logic := '0';
    signal vmm_sck_1     : std_logic := '0';
    signal second_rd_0   : std_logic := '0';
    signal second_rd_1   : std_logic := '0';

    type stateType is (ST_IDLE, ST_WAIT_0, ST_WR_HIGH, ST_WR_LOW, ST_WAIT_1, ST_COUNT_AND_DRIVE, ST_DONE, ST_RD_START,ST_DATA,ST_WAIT_2, ST_WAIT_SCK_1);
    signal state : stateType := ST_IDLE;

begin

-- FSM that samples the S/N and sends it back to the configuration software
-- as a UDP reply
UDP_reply_FSM: process(clk)
begin
    if(rising_edge(clk))then
        if(enable = '0')then
            sn_i         <= (others => '0');
            bit_mask_i   <= (others => '0');
            command_i    <= (others => '0');
            udp_cnt      <= (others => '0');
            cnt_len      <= 0;
            buff_bit_cnt <= 0;
            wr_en_conf   <= '0';
            end_conf     <= '0';
            reply_done   <= '0';
            head_wr_done <= '0';
            second_rcv    <= '0';
            state        <= ST_IDLE;
            reply_st     <= "0000";
        else
         --   if(sample_end = '1') then
                case state is
    
                -- sample the serial number and start writing data
                when ST_IDLE =>
                    sn_i        <= serial_number;
                    bit_mask_i  <= bit_mask;
                    command_i   <= command;
                    state       <= ST_WAIT_0;
                    reply_done  <= '0';
                    wr_en_conf  <= '0';
                    end_conf    <= '0';
                    reply_st    <= "0000";
                
                -- a wait state   
                when ST_WAIT_0 =>
                    state <= ST_WR_HIGH;
                    reply_st    <= "0001";  
    
                -- wr_en FIFO high
                when ST_WR_HIGH =>
                    wr_en_conf <= '1';
                    udp_cnt    <= udp_cnt + 1;  
                    state      <= ST_WR_LOW;
                    reply_st    <= "0010";
    
                -- wr_en FIFO low
                when ST_WR_LOW =>
                    wr_en_conf <= '0';
                    state      <= ST_WAIT_1;
                    reply_st    <= "0011";
                    
                -- a wait state
                when ST_WAIT_1 =>
                    state <= ST_COUNT_AND_DRIVE;
                    reply_st    <= "0100"; 
                
                --wait for the second reading to start
                when ST_RD_START =>
                    if (second_rd_1 = '1') then
                        second_rcv  <= '1';
                        state       <= ST_WAIT_SCK_1;
                    end if;
                    reply_st    <= "0101";
                
                -- wait for the sck to be asserted
                when ST_WAIT_SCK_1 =>
                    if (vmm_sck_1 = '1') then
                        state       <= ST_WAIT_2;
                    elsif(vmm_fsm_reset = '1' )then
                        end_conf    <= '1';
                        state       <= ST_DONE;                
                    end if;
                    reply_st    <= "0110";
                
                when ST_WAIT_2 =>
                    if(vmm_sck_1 = '0') then
                        state       <= ST_DATA;
                    end if;
                    reply_st    <= "0111";
                    
                --drives the correct data to the buffer    
                when ST_DATA =>
                    if (buff_bit_cnt = 15) then
                        state        <= ST_WAIT_0;
                    else
                        buff_bit_cnt <= buff_bit_cnt + 1;
                        state        <= ST_WAIT_SCK_1;
                    end if;
                    reply_st    <= "1000";
    
                -- increment the counter to select a different dout
                when ST_COUNT_AND_DRIVE =>
                    if(cnt_len < 3)then
                        --cnt_packet  <= cnt_packet + 1;
                        cnt_len     <= cnt_len + 1;
                        state       <= ST_WAIT_0;
                    elsif(cnt_len = 3) then
                        head_wr_done   <= '1';
                        buff_bit_cnt   <= 0;
                        cnt_len        <= cnt_len + 1;
                        state          <= ST_RD_START;
                    elsif(cnt_len > 3)then-- and (cnt_len < 108) then
                         head_wr_done   <= '0';
                         buff_bit_cnt   <= 0;
                         cnt_len        <= cnt_len + 1;
                         state          <= ST_WAIT_SCK_1;
                    --else
                    --    end_conf    <= '1';
                    --    state       <= ST_DONE;
                    end if;
                    reply_st    <= "1001";
    
                -- stay here until reset by flow_fsm
                when ST_DONE =>
                    reply_done  <= '1';
                    end_conf    <= '0';
                    reply_st    <= "1010";
    
                when others =>
                    sn_i         <= (others => '0');
                    bit_mask_i   <= (others => '0');
                    command_i    <= (others => '0');
                    buff_bit_cnt <= 0;               
                    wr_en_conf   <= '0';
                    cnt_len      <= 0;
                    end_conf     <= '0';
                    reply_done   <= '0';
                    second_rcv    <= '0';
                    state        <= ST_IDLE;
                    reply_st     <= "0000";
                end case;
           -- end if;
        end if;
    end if;
end process;

reply_st_o  <= reply_st;

-- MUX that drives the apporpiate data to the UDP FIFO
dout_conf_MUX: process(cnt_len, sn_i, bit_mask_i, command_i, buff_vector)
begin
    case cnt_len is
    when 0 =>
        dout_conf <= sn_i(31 downto 16);
    when 1 => 
        dout_conf <= sn_i(15 downto 0);
    when 2 =>
        dout_conf <= "11111111" & bit_mask_i;
    when 3 =>
        dout_conf <= command_i;
    when 4 to 108 =>
        dout_conf <= buff_vector;
    when others =>
        dout_conf <= (others => '0');
    end case;
end process;

-- MUX that drives data bits into the buffer vector
bit_buffer_MUX: process(buff_bit_cnt, vmm_d_in)
begin
    case buff_bit_cnt is
        when 0      => buff_vector(8)   <= vmm_d_in;
        when 1      => buff_vector(9)   <= vmm_d_in;
        when 2      => buff_vector(10)   <= vmm_d_in;
        when 3      => buff_vector(11)   <= vmm_d_in;
        when 4      => buff_vector(12)   <= vmm_d_in;
        when 5      => buff_vector(13)   <= vmm_d_in;
        when 6      => buff_vector(14)   <= vmm_d_in;
        when 7      => buff_vector(15)   <= vmm_d_in;
        when 8      => buff_vector(0)   <= vmm_d_in;
        when 9      => buff_vector(1)   <= vmm_d_in;
        when 10     => buff_vector(2)  <= vmm_d_in;
        when 11     => buff_vector(3)  <= vmm_d_in;
        when 12     => buff_vector(4)  <= vmm_d_in;
        when 13     => buff_vector(5)  <= vmm_d_in;
        when 14     => buff_vector(6)  <= vmm_d_in;
        when 15     => buff_vector(7)  <= vmm_d_in;
        when others => buff_vector      <= (others => '0');
    end case;
end process;

    packet_len_conf <= std_logic_vector(udp_cnt);

-- Syncronsing process for signal vmm_sck    
sync_proc_sck : process(clk)
begin
    if (rising_edge(clk)) then
        vmm_sck_0 <= vmm_sck;
        vmm_sck_1 <= vmm_sck_0;
    end if;
end process;

-- Syncronsing process for signal second_rd_start    
sync_proc_second_rd : process(clk)
begin
    if (rising_edge(clk)) then
        second_rd_0 <= second_rd_start;
        second_rd_1 <= second_rd_0;
    end if;
end process;

    
end RTL;
