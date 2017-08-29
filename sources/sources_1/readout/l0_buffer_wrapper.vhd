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
-- Create Date: 28.04.2017 14:18:44
-- Design Name: Level-0 Buffer Wrapper
-- Module Name: l0_buffer_wrapper - RTL
-- Project Name: NTUA-BNL VMM3 Readout Firmware
-- Target Devices: Xilinx xc7a200t-2fbg484
-- Tool Versions: Vivado 2016.4
-- Description: Wrapper that contains the FIFO that buffers level-0 data, and the
-- necessary acomppanying logic (packet_formation interface)
-- 
-- Dependencies: 
-- 
-- Changelog: 
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity l0_buffer_wrapper is
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt        : in  std_logic;
        clk             : in  std_logic;
        rst_buff        : in  std_logic;
        wr_accept       : in  std_logic;
        level_0         : in  std_logic;
        null_event_out  : out std_logic;
        ------------------------------------
        --- Deserializer Interface ---------
        inhib_wr        : out std_logic;
        commas_true     : in  std_logic;
        dout_dec        : in  std_logic_vector(7 downto 0);
        wr_en           : in  std_logic;
        null_event      : in  std_logic;
        ------------------------------------
        ---- Packet Formation Interface ----
        rd_ena_buff     : in  std_logic;
        rst_intf_proc   : in  std_logic;
        vmmWordReady    : out std_logic;
        vmmWord         : out std_logic_vector(15 downto 0);
        vmmEventDone    : out std_logic
    );
end l0_buffer_wrapper;

architecture RTL of l0_buffer_wrapper is

component level0_buffer
  port (
    wr_clk      : in  std_logic;
    rd_clk      : in  std_logic;
    rst         : in  std_logic;
    din         : in  std_logic_vector(7 downto 0);
    wr_en       : in  std_logic;
    rd_en       : in  std_logic;
    dout        : out std_logic_vector(15 downto 0);
    full        : out std_logic;
    empty       : out std_logic;
    wr_rst_busy : out std_logic;
    rd_rst_busy : out std_logic
  );
end component;

component ila_l0_buf
    port(
        clk    : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
end component;

    signal fifo_full        : std_logic := '0';
    signal fifo_empty       : std_logic := '0';
    signal commas_true_i    : std_logic := '0';
    signal commas_true_s    : std_logic := '0';
    signal inhibit_write    : std_logic := '1';
    signal inhib_wr_i       : std_logic := '0';
    signal inhib_wr_s       : std_logic := '0';
    signal enable_timeout   : std_logic := '0';
    signal timeout_cnt      : integer range 0 to 511 := 0;
    signal timeout          : std_logic := '0';
    signal null_event_i     : std_logic := '0';
    signal null_event_s     : std_logic := '0';
    constant timeout_max    : integer := 511;      
    
    type stateType is (ST_IDLE, ST_WAIT_FOR_DATA, ST_LATCH_NULL, ST_READING, ST_DONE);
    signal state : stateType := ST_IDLE;

    attribute FSM_ENCODING                  : string;
    attribute FSM_ENCODING of state         : signal is "ONE_HOT";

    attribute ASYNC_REG                     : string;
    attribute ASYNC_REG of commas_true_i    : signal is "TRUE";
    attribute ASYNC_REG of commas_true_s    : signal is "TRUE";
    attribute ASYNC_REG of inhib_wr_i       : signal is "TRUE";
    attribute ASYNC_REG of inhib_wr_s       : signal is "TRUE";
    attribute ASYNC_REG of null_event_i     : signal is "TRUE";
    attribute ASYNC_REG of null_event_s     : signal is "TRUE";

begin

-- Moore FSM that interfaces with packet_formation and vmm_driver
pf_interface_FSM: process(clk)
begin
    if(rising_edge(clk))then
        if(rst_intf_proc = '1')then
            vmmEventDone    <= '0';
            inhibit_write   <= '1';
            vmmWordReady    <= '0';
            enable_timeout  <= '0';
            null_event_out  <= '1';
            state           <= ST_IDLE;
        else
            case state is

            -- wait for the trigger module to open the window
            when ST_IDLE =>
                vmmEventDone    <= '0';
                inhibit_write   <= '1';
                vmmWordReady    <= '0';
                enable_timeout  <= '0';
                null_event_out  <= '1';

                if(wr_accept = '1')then
                    state <= ST_WAIT_FOR_DATA;
                else
                    state <= ST_IDLE;
                end if;

            -- if there are data in the buffer and commas are being detected => ready to be read
            when ST_WAIT_FOR_DATA =>
                vmmEventDone    <= '0';
                vmmWordReady    <= '0';
                inhibit_write   <= '0';
                enable_timeout  <= '1';
                null_event_out  <= '1';

                if(fifo_empty = '0' and commas_true_s = '1')then
                    state   <= ST_LATCH_NULL;
--                elsif(timeout = '1')then -- timeout of 4us reached
--                    state   <= ST_DONE;
                else
                    state   <= ST_WAIT_FOR_DATA;
                end if;

            -- sample and keep the event_null signal for the elink module
            when ST_LATCH_NULL =>
                vmmEventDone    <= '0';
                vmmWordReady    <= '0';
                inhibit_write   <= '0';
                enable_timeout  <= '1';
                null_event_out  <= null_event_s;
                state           <= ST_READING;


            -- wait for pf to empty the buffer and prevent any further writes
            when ST_READING =>     
                inhibit_write   <= '1';
                enable_timeout  <= '0';
                vmmWordReady    <= '1';
                vmmEventDone    <= '0';
                           
                if(fifo_empty = '0')then
                    state   <= ST_READING;
                else
                    state   <= ST_DONE;
                end if;

            -- stay here until reset by pf
            when ST_DONE =>
                vmmWordReady    <= '0';
                inhibit_write   <= '1';
                vmmEventDone    <= '1';
                enable_timeout  <= '0';
                state           <= ST_DONE;

            when others =>
                vmmWordReady    <= '0';
                vmmEventDone    <= '0';
                inhibit_write   <= '0';
                enable_timeout  <= '0';
                state           <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

-- sync inhibit write signals
inhib_wr_sync_proc: process(clk_ckdt)
begin
    if(rising_edge(clk_ckdt))then
        inhib_wr_i  <= inhibit_write;
        inhib_wr_s  <= inhib_wr_i;
    end if;
end process;

-- sync 'commas_true' and 'null_event'
clk_sync_proc: process(clk)
begin
    if(rising_edge(clk))then
        commas_true_i  <= commas_true;
        commas_true_s  <= commas_true_i;
        null_event_i   <= null_event;
        null_event_s   <= null_event_i;
    end if;
end process;

-- timeout process
--to_proc: process(clk)
--begin
--    if(rising_edge(clk))then
--        if(enable_timeout = '1')then
--            if(timeout_cnt = timeout_max)then
--                timeout <= '1';
--            else
--                timeout_cnt <= timeout_cnt + 1;
--            end if;
--        else
--           timeout_cnt <= 0;
--           timeout     <= '0';
--        end if;
--    end if;
--end process;

l0_buffering_fifo: level0_buffer
    port map(
        rst         => rst_buff,
        wr_clk      => clk_ckdt,
        rd_clk      => clk,
        din         => dout_dec,
        wr_en       => wr_en,
        rd_en       => rd_ena_buff,
        dout        => vmmWord,
        full        => fifo_full,
        empty       => fifo_empty,
        wr_rst_busy => open,
        rd_rst_busy => open
    );
    
--ila_level0_buf: ila_l0_buf
--      PORT MAP (
--          clk                   => clk_ckdt,
--          probe0(0)             => wr_en,
--          probe0(8 downto 1)    => dout_dec,
--          probe0(9)             => fifo_empty,
--          probe0(10)            => rd_ena_buff,
--          probe0(12 downto 11)  => state_debug,
--          probe0(13)            => level_0,
--          probe0(15 downto 14)  => (others => '0')
--      );

    inhib_wr     <= inhib_wr_s;

end RTL;