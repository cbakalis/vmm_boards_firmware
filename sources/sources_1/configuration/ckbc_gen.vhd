----------------------------------------------------------------------------------
-- Company: Westf??lische Hochschule
-- Engineer: Pia Piekarek (piapiekarek@googlemail.com)
-- 
-- Copyright Notice/Copying Permission:
--    Copyright 2017 Pia Piekarek
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
-- Create Date: 13.01.2017 11:56:04
-- Design Name: 
-- Module Name: ckbc_gen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: CKBC Generator
-- 
-- Dependencies: 
-- 
-- Changelog:
-- 20.02.2017 Changed the FSM to create a multicycle path. Changed the input clock
-- frequency to 160 Mhz. (Christos Bakalis)
-- 12.03.2017 Removed FSM. (Christos Bakalis)
-- 31.03.2017 Added CKBC for readout mode. (Christos Bakalis)
-- 25.06.2017 Fix for CKBC strobbing mode. Allowing greater values that 7 in order
-- to allow a default to 32. CKBC minimum should no less than 12. (Paris)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ckbc_gen is
    port(  
        clk_160         : in  std_logic;
        duty_cycle      : in  std_logic_vector(7 downto 0);
        freq            : in  std_logic_vector(5 downto 0);
        readout_mode    : in  std_logic;
        enable_ro_ckbc  : in  std_logic;
        ready           : in  std_logic;
        ckbc_ro_out     : out std_logic;
        ckbc_out        : out std_logic
    );
end ckbc_gen;


architecture Behavioral of ckbc_gen is
    
    signal t_high        : unsigned(16 downto 0) := to_unsigned(0,17);
    signal t_low         : unsigned(16 downto 0) := to_unsigned(0,17);
    
    signal count         : unsigned(7 downto 0) := to_unsigned(0,8);
    signal p_high        : unsigned(16 downto 0) := to_unsigned(0,17);        --number of clock cycles while high
    signal p_low         : unsigned(16 downto 0) := to_unsigned(0,17);        --number of clock cycles while low
    
    signal ready_i       : std_logic := '0';
    signal ready_sync    : std_logic := '0';

    type ckbc_ro_type is (ST_IDLE, ST_SEND, ST_WAIT);
    type ckbc_cnt_type is (ST_IDLE, ST_WAIT_CKBC, ST_WAIT_ENABLE, ST_INCR);
    signal state            : ckbc_ro_type  := ST_IDLE;
    signal state_cnt        : ckbc_cnt_type := ST_IDLE;

    signal ckbc_inhibit     : std_logic := '0';
    signal readout_mode_i   : std_logic := '0';
    signal readout_mode_s   : std_logic := '0';
    signal count_ro         : unsigned(7 downto 0) := to_unsigned(0,8);
    signal ckbc_max_cnt     : unsigned(6 downto 0) := to_unsigned(0,7);
    signal ckbc_ro          : std_logic := '0';
    constant ckbc_max_limit : integer := 12;


    attribute ASYNC_REG : string;
    attribute ASYNC_REG of ready_i         : signal is "TRUE";
    attribute ASYNC_REG of ready_sync      : signal is "TRUE";
    attribute ASYNC_REG of readout_mode_i  : signal is "TRUE";
    attribute ASYNC_REG of readout_mode_s  : signal is "TRUE";

begin

-- 2 FF synchronizer
sync_ready: process(clk_160)
begin
    if(rising_edge(clk_160))then
        ready_i             <= ready;
        ready_sync          <= ready_i;
        readout_mode_i      <= readout_mode;
        readout_mode_s      <= readout_mode_i;
    end if;
end process;

clocking_proc: process(clk_160)
  begin
    if (rising_edge(clk_160)) then
        if(ready_sync = '0') then
            ckbc_out <= '0';
            count    <= to_unsigned(0,8);
        else
            if(count < (p_high+p_low)) then
                if(count < p_high)then
                    ckbc_out <= '1';
                elsif (count < (p_high+p_low)) then
                    ckbc_out <= '0';
                end if;
                count <= count + 1;
            elsif (p_high >= 1 and p_low >= 1) then
                count <= to_unsigned(1,8);
                ckbc_out <= '1';
            end if;
        end if;
    end if;
end process;

readout_mode_proc: process(clk_160)
begin
    if(rising_edge(clk_160))then
        if(readout_mode_s = '1')then

            case state is

            -- wait for enable signal to go high
            when ST_IDLE =>
                if(enable_ro_ckbc = '1')then
                    state <= ST_SEND;
                else
                    state <= ST_IDLE;
                end if;

            -- send two CKBC pulses    
            when ST_SEND =>
                if(ckbc_inhibit = '0')then
                    if(count_ro < (p_high+p_low)) then
                        if(count_ro < p_high)then
                            ckbc_ro <= '1';
                        elsif (count_ro < (p_high+p_low)) then
                            ckbc_ro <= '0';
                        end if;
                        count_ro <= count_ro + 1;
                    elsif (p_high >= 1 and p_low >= 1) then
                        count_ro <= to_unsigned(1,8);
                        ckbc_ro  <= '1';
                    end if;
                else
                    count_ro    <= (others => '0');
                    state       <= ST_WAIT;
                    ckbc_ro     <= '0';
                end if;

            -- wait for inhibit to go low
            when ST_WAIT =>
                if(ckbc_inhibit = '0')then
                    state   <= ST_IDLE;
                else
                    state   <= ST_WAIT;
                end if;

            when others => state <= ST_IDLE;
            end case;

        else
           ckbc_ro  <= '0';
           count_ro <= (others => '0');
           state    <= ST_IDLE;
        end if; 
    end if;
end process;

count_ckbc_proc: process(clk_160)
begin
    if(rising_edge(clk_160))then
        if(readout_mode_s = '1')then
            case state_cnt is

            when ST_IDLE =>
                if(ckbc_ro = '1')then
                    state_cnt <= ST_WAIT_CKBC;
                else
                    state_cnt <= ST_IDLE;
                end if;

            when ST_WAIT_CKBC =>
                if(ckbc_ro = '0')then
                    state_cnt       <= ST_INCR;
                    ckbc_max_cnt    <= ckbc_max_cnt + 1;
                else
                    state_cnt       <= ST_WAIT_CKBC;
                end if;

            when ST_INCR =>
                if(ckbc_max_cnt = ckbc_max_limit)then
                    ckbc_inhibit    <= '1';
                    state_cnt       <= ST_WAIT_ENABLE;    
                else
                    state_cnt       <= ST_IDLE;
                end if;

            when ST_WAIT_ENABLE =>
                if(enable_ro_ckbc = '0')then
                    state_cnt       <= ST_IDLE;
                    ckbc_inhibit    <= '0';
                else
                    state_cnt       <= ST_WAIT_ENABLE;
                end if;

                ckbc_max_cnt <= (others => '0');

            when others =>
                ckbc_inhibit    <= '0';
                state_cnt       <= ST_IDLE;
                ckbc_max_cnt    <= (others => '0');

            end case;
        else
            ckbc_inhibit    <= '0';
            state_cnt       <= ST_IDLE;
            ckbc_max_cnt    <= (others => '0');
        end if;    
    end if;
end process;

t_high_proc: process(freq)
begin
    case freq is
    when "101000" => -- 40
        t_high <= to_unsigned(6250,17);
        t_low  <= to_unsigned(18750,17);
    when "010100" => -- 20
        t_high <= to_unsigned(12500,17);
        t_low  <= to_unsigned(37500,17);
    when "001010" => -- 10
        t_high <= to_unsigned(18750,17);
        t_low  <= to_unsigned(81250,17);
    when others =>
        t_high <= to_unsigned(6250,17);
        t_low  <= to_unsigned(18750,17);
    end case;
end process;
      
      p_high        <= (t_high / to_unsigned(6250, 16)); -- input clock period: 160 Mhz = 6.250 ns
      p_low         <= (t_low  / to_unsigned(6250, 16));
      ckbc_ro_out   <= ckbc_ro;

end Behavioral;
