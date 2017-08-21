-- Company: NTUA - BNL
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
-- Create Date: 18.07.2017 16:32:39
-- Design Name: 
-- Module Name: elink_daq_driver - RTL
-- Project Name: 
-- Target Devices: 
-- Target Devices: Artix7 xc7a200t-2fbg484 & xc7a200t-3fbg484 
-- Tool Versions: Vivado 2017.2 
-- 
-- Changelog:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity elink_daq_driver is
    Port(
        ---------------------------
        ---- general interface ---- 
        clk_in      : in  std_logic;
        fifo_flush  : in  std_logic;
        driver_ena  : in  std_logic;
        ---------------------------
        ------- pf interface ------
        din_daq     : in  std_logic_vector(63 downto 0);
        wr_en_daq   : in  std_logic;
        last        : in  std_logic;
        busy        : out std_logic;
        ---------------------------
        ------ elink inteface -----
        empty_elink : in  std_logic;
        wr_en_elink : out std_logic;
        dout_elink  : out std_logic_vector(17 downto 0)
    );
end elink_daq_driver;

architecture RTL of elink_daq_driver is

COMPONENT DAQelinkFIFO
  PORT (
    clk     : IN  STD_LOGIC;
    srst    : IN  STD_LOGIC;
    din     : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
    wr_en   : IN  STD_LOGIC;
    rd_en   : IN  STD_LOGIC;
    dout    : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    full    : OUT STD_LOGIC;
    empty   : OUT STD_LOGIC
  );
END COMPONENT;

    signal rd_en        : std_logic := '0';
    signal dout_fifo    : std_logic_vector(15 downto 0) := (others => '0');
    signal data_out     : std_logic_vector(15 downto 0) := (others => '0');
    signal fifo_full    : std_logic := '0';
    signal fifo_empty   : std_logic := '0';
    signal trailer      : std_logic := '0';
    signal wait_cnt     : unsigned(1 downto 0) := (others => '0');

    signal flag         : std_logic_vector(1 downto 0) := (others => '0');
    constant SOP        : std_logic_vector(1 downto 0) := "10";
    constant MOP        : std_logic_vector(1 downto 0) := "00";
    constant EOP        : std_logic_vector(1 downto 0) := "01";

    type stateType is (ST_IDLE, ST_SOP_L, ST_RD_FIFO, ST_WAIT, ST_WR_LOW, ST_TRAILER, ST_EOP_0, ST_EOP_1, ST_EOP_2, ST_EOP_3); 
    signal state : stateType := ST_IDLE;
    attribute FSM_ENCODING              : string;
    attribute FSM_ENCODING of state     : signal is "ONE_HOT";

begin

FSM_DRV_proc: process(clk_in)
begin
    if(rising_edge(clk_in))then
        if(driver_ena = '0')then
            flag        <= SOP;
            rd_en       <= '0';
            wait_cnt    <= (others => '0');
            trailer     <= '0';
            wr_en_elink <= '0';
            busy        <= '0';
            state       <= ST_IDLE;
        else
            case state is
    
            -- wait for 'last' signal from PF to start sending data to the elinkFIFO
            when ST_IDLE =>
                flag        <= SOP;
                rd_en       <= '0';
                wait_cnt    <= (others => '0');
                trailer     <= '0';
                wr_en_elink <= '0';
                busy        <= '0';
    
                if(last = '1')then
                    wr_en_elink <= '1';
                    state       <= ST_SOP_L;
                else
                    wr_en_elink <= '0';
                    state       <= ST_IDLE;
                end if;
    
            -- write the start of packet, assert BUSY
            when ST_SOP_L =>
                busy        <= '1';
                wr_en_elink <= '0';
                state       <= ST_RD_FIFO;
    
            -- pass a fifo word to the bus if it is not empty
            when ST_RD_FIFO =>
                flag <= MOP;
    
                if(fifo_empty = '0')then
                    rd_en   <= '1';
                    state   <= ST_WAIT;
                else
                    rd_en   <= '0';
                    trailer <= '1';
                    state   <= ST_TRAILER;
                end if;
    
            -- wait 3 cycles (embedded registers and ensure data integrity)
            when ST_WAIT =>
                rd_en <= '0';
    
                if(wait_cnt = "11")then
                    wr_en_elink <= '1';
                    wait_cnt    <= (others => '0');
                    state       <= ST_WR_LOW;
                else
                    wr_en_elink <= '0';
                    wait_cnt    <= wait_cnt + 1;
                    state       <= ST_WAIT;
                end if;
    
            -- wait 3 cycles and then check the fifo
            when ST_WR_LOW =>
                wr_en_elink <= '0';
    
                if(wait_cnt = "11")then
                    wait_cnt    <= (others => '0');
                    state       <= ST_RD_FIFO;
                else
                    wait_cnt    <= wait_cnt + 1;
                    state       <= ST_WR_LOW;
                end if;
    
            -- done. add 4 times 0xFF (32 bits so stay here twice)
            when ST_TRAILER =>
                wr_en_elink <= '1';
    
                if(wait_cnt = "01")then
                    wait_cnt    <= (others => '0');
                    state       <= ST_EOP_0;
                else
                    wait_cnt    <= wait_cnt + 1;
                    state       <= ST_TRAILER;
                end if;
    
            -- ground wr_en and add EOP. go to idle after EOP and elink is done.
            when ST_EOP_0 =>
                wr_en_elink <= '0';
                state       <= ST_EOP_1;
            when ST_EOP_1 =>
                flag        <= EOP;
                state       <= ST_EOP_2;
            when ST_EOP_2 =>
                wr_en_elink <= '1';
                state       <= ST_EOP_3;
            when ST_EOP_3 =>
                wr_en_elink <= '0';
                if(empty_elink = '1')then -- wait here...PF SHOULD FLUSH THE FIFOS ON 'BUSY' TRANSITION FROM 1 TO 0
                    state   <= ST_IDLE;
                else
                    state   <= ST_EOP_3;
                end if;
    
            when others =>
                flag        <= SOP;
                rd_en       <= '0';
                wait_cnt    <= (others => '0');
                trailer     <= '0';
                wr_en_elink <= '0';
                busy        <= '0';
                state       <= ST_IDLE;
    
            end case;
        end if;
    end if;
end process;

driverFIFO : DAQelinkFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_daq,
    wr_en   => wr_en_daq,
    rd_en   => rd_en,
    dout    => dout_fifo,
    full    => fifo_full,
    empty   => fifo_empty
  );

  dout_elink <= flag & data_out;

sel_dout: process(flag, trailer, dout_fifo)
begin
    case flag is
    when SOP    => data_out <= (others => '0');
    when MOP    => if(trailer = '1')then data_out <= x"FFFF"; else data_out <= dout_fifo; end if;
    when EOP    => data_out <= (others => '0');
    when others => data_out <= (others => '0');
    end case;
end process;


end RTL;
