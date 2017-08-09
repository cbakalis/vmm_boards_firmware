----------------------------------------------------------------------------------
-- Company: NTU ATHENS - BNL
-- Engineer: Paris Moschovakos
-- 
-- Copyright Notice/Copying Permission:
--    Copyright 2017 Paris Moschovakos
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
-- Create Date: 2.6.2017
-- Design Name: 
-- Module Name: art.vhd - Behavioral
-- Project Name:  
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2017.1
--
-- Changelog:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;
library UNISIM;
use UNISIM.vcomponents.all;

entity artReadout is
    Generic( is_mmfe8   : std_logic;
            artEnabled  : std_logic;
            slowTrigger : std_logic);
    Port (
            clk             : in std_logic;
            clk_art         : in std_logic;
            trigger125      : in std_logic;
            trigger160      : in std_logic;
            tr_hold         : in std_logic;
            artData         : in std_logic_vector(8 downto 1);
            art2trigger     : out std_logic_vector(5 downto 0);
            vmmArtData125   : out std_logic_vector(5 downto 0);
            vmmArtReady     : out std_logic;
            artTimeout      : in std_logic_vector(7 downto 0)
            );
end artReadout;

architecture Behavioral of artReadout is

    signal enableReadout125     : std_logic := '0';
    signal enableReadout125_160 : std_logic := '0';
    signal enableReadout160     : std_logic := '0';
    signal enableReadoutSlowTr  : std_logic := '0';
    signal vmmArtReady160       : std_logic := '0';
    signal vmmArtReady160_125   : std_logic := '0';
    signal vmmArtReady125       : std_logic := '0';
    signal artData_i            : std_logic := '0';
    signal artDataBuffed        : std_logic := '0';
    signal vmmArtData160_125    : std_logic_vector(5 downto 0) := ( others => '0' );
    signal tr_hold160           : std_logic := '0';
    signal tr_hold125_160       : std_logic := '0';
    signal art2trigger125       : std_logic_vector(5 downto 0) := ( others => '0' );
    signal art2trigger160_125   : std_logic_vector(5 downto 0) := ( others => '0' );
    
    signal art2triggerCnt       : unsigned(5 downto 0) := ( others => '0' );
    signal vmmArtData           : unsigned(5 downto 0) := ( others => '0' );
    signal artCounter           : unsigned(3 downto 0) := ( others => '0' );
    
    type stateType is (S1, S2, S3, S4);
    signal state            : stateType := S1;
    signal state160         : stateType := S1;
    signal stateReadout     : stateType := S1;
    
    -- Debugging
    signal probe0_out           : std_logic_vector(127 downto 0);
    signal debug1               : std_logic_vector(1 downto 0) := b"00";
    signal debug2               : std_logic_vector(1 downto 0) := b"00";
    signal debug3               : std_logic_vector(1 downto 0) := b"00";

    -- ASYNC_REG attributes
    attribute ASYNC_REG : string;

    attribute ASYNC_REG of vmmArtReady160       : signal is "TRUE";
    attribute ASYNC_REG of vmmArtReady160_125   : signal is "TRUE";
    attribute ASYNC_REG of enableReadout125     : signal is "TRUE";
    attribute ASYNC_REG of enableReadout125_160 : signal is "TRUE";    
    attribute ASYNC_REG of artData_i            : signal is "TRUE";
    attribute ASYNC_REG of artData              : signal is "TRUE";
    attribute ASYNC_REG of vmmArtData160_125    : signal is "TRUE";
    attribute ASYNC_REG of vmmArtData125        : signal is "TRUE"; 
    attribute ASYNC_REG of tr_hold              : signal is "TRUE";
    attribute ASYNC_REG of tr_hold125_160       : signal is "TRUE";
    attribute ASYNC_REG of art2trigger125       : signal is "TRUE";
    attribute ASYNC_REG of art2trigger160_125   : signal is "TRUE";
    
    -------------------------------------------------------------------
    -- Keep signals for ILA
    -----------------------------------------------------------------
--    attribute mark_debug : string;

--    attribute mark_debug of artData                : signal is "true";
--    attribute mark_debug of trigger125             : signal is "true";
--    attribute mark_debug of artCounter             : signal is "true";
--    attribute mark_debug of vmmArtReady160         : signal is "true";
--    attribute mark_debug of enableReadout160       : signal is "true";
--    attribute mark_debug of artDataBuffed          : signal is "true";
--    attribute mark_debug of debug1                 : signal is "true";
--    attribute mark_debug of debug2                 : signal is "true";
--    attribute mark_debug of vmmArtReady125         : signal is "true";
    
    
component ila_art
port(
    clk     : in std_logic;
    probe0  : in std_logic_vector(127 downto 0)
);
end component;

function reverse_any_vector (a: in std_logic_vector)
return std_logic_vector is
  variable result: std_logic_vector(a'RANGE);
  alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
begin
  for i in aa'RANGE loop
    result(i) := aa(i);
  end loop;
  return result;
end;

begin

fastTrigProc: process(clk)
begin
    if slowTrigger = '0' then
        if (rising_edge(clk)) then
            case state is
                when S1 =>
                    debug1   <= b"00";
                    if trigger125 = '1' and artEnabled = '1'  then
                        state   <= S2;
                    end if;
                when S2 =>
                    debug1   <= b"01";
                    enableReadout125    <= '1';
                    if vmmArtReady125 = '1' then
                        state <= S3;
                    end if;
                    --start reading out ART data
                    --when finish move to S3
                when S3 =>
                    debug1   <= b"10";
                    enableReadout125    <= '0';
                    state <= S1;

                when others =>
                    enableReadout125    <= '0';
                    -- reset
            end case;
        end if;
    end if;
end process;

slowTrigPro: process(clk_art)
begin
if slowTrigger = '1' and artEnabled = '1' then
    if (rising_edge(clk_art)) then
        case state160 is
            when S1 =>
                debug3              <= b"00";
                if tr_hold160 = '0' then
                    enableReadoutSlowTr <= '1';
                    state160            <= S2;
                end if;
            when S2 =>
                debug3          <= b"01";
                art2triggerCnt  <= b"000000";
                if vmmArtReady160 = '1' then
                    enableReadoutSlowTr <= '0';
                    state160    <= S3;
                end if;
                --start reading out ART data
                --when finish move to S3
            when S3 =>
                debug3              <= b"10";
                art2triggerCnt      <= art2triggerCnt + 1;
                if tr_hold160 = '1' then
                    state160            <= S1;
                elsif art2triggerCnt = unsigned(artTimeout) then
                    state160            <= S1;
                end if;
                
            when others =>
                enableReadoutSlowTr <= '0';
                -- reset
            end case;
        end if;
    end if;
end process;

readoutProc: process(clk_art)
begin
    if rising_edge(clk_art) then
        if ((enableReadout160 = '1' and slowTrigger ='0') or (enableReadoutSlowTr = '1' and slowTrigger ='1')) then
            case stateReadout is
                when S1 =>
                    --reset
                    debug2   <= b"00";
                    artCounter      <= ( others => '0' );
                    vmmArtReady160  <= '0';
                    
                    if artDataBuffed = '1' then
                        stateReadout        <= S2;
                    end if;

                when S2 =>
                    debug2   <= b"01";
                    if artCounter /= 7 then
                        artCounter  <= artCounter + 1;
                        vmmArtData  <= shift_left(vmmArtData, 1);
                        vmmArtData(0) <= artDataBuffed;
                    else
                        stateReadout    <= S3;
                    end if;
                    
                when S3 =>
                    debug2   <= b"10";
                    vmmArtReady160  <= '1';
                    artCounter      <= artCounter - 1;
                    if artCounter = 0 then
                        stateReadout    <= S1;
                    end if;

                when others =>
                    artCounter      <= ( others => '0' );
                    vmmArtReady160  <= '0';
            end case;
        end if;
    end if;
end process;

-- synchronize Art data
data_pipe: process(clk_art)
begin
    if(rising_edge(clk_art))then
        artData_i       <= artData(1);
        artDataBuffed   <= artData_i;
    end if;
end process;
    
to125Synchronizer: process(clk) --125
begin
    if rising_edge(clk) then 
        vmmArtReady160_125      <= vmmArtReady160;
        vmmArtReady125          <= vmmArtReady160_125;
        vmmArtData160_125       <= std_logic_vector(vmmArtData);
        vmmArtData125           <= vmmArtData160_125;
        art2trigger160_125      <= std_logic_vector(art2triggerCnt);
        art2trigger125          <= art2trigger160_125;
    end if;
end process;

to160Synchronizer: process(clk_art) --40
begin
    if rising_edge (clk_art) then
        tr_hold125_160          <= tr_hold;
        tr_hold160              <= tr_hold125_160;
        enableReadout125_160    <= enableReadout125;
        enableReadout160        <= enableReadout125_160;
    end if;
end process;

vmmArtReady     <= vmmArtReady125;
art2trigger     <= art2trigger125;

--ilaArt: ila_art
--port map
--    (
--        clk                     =>  clk_art,
--        probe0                  =>  probe0_out
--    );

probe0_out(0)               <= artData(1);
probe0_out(1)               <= trigger125;
probe0_out(5 downto 2)      <= std_logic_vector(artCounter); --4
probe0_out(6)               <= enableReadout160;
probe0_out(12 downto 7)     <= std_logic_vector(vmmArtData);
probe0_out(13)              <= vmmArtReady125;
probe0_out(15 downto 14)    <= debug1;
probe0_out(17 downto 16)    <= debug2;
probe0_out(18)              <= artDataBuffed;
probe0_out(19)              <= vmmArtReady160;
probe0_out(127 downto 20)   <= (others => '0');

end Behavioral;