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
-- Create Date: 19.02.2017 12:07:30
-- Design Name: 
-- Module Name: clk_gen_wrapper - RTL
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Wrapper that contains the CKTP and CKBC generators. It also 
-- instantiates a skewing module with 2 ns resolution. See skew_gen for more
-- information.
-- 
-- Dependencies: "Configurable CKBC/CKTP Constraints" .xdc snippet must be added to 
-- the main .xdc file of the design. Can be found at the project repository.
-- 
-- Changelog: 
-- 23.02.2017 Slowed down the skewing process to 500 Mhz. (Christos Bakalis)
-- 09.03.2017 Shortened the bus widths and added conversion multipliers for
-- area usage optimization. (Christos Bakalis)
-- 26.03.2017 Added CKTP counting module. (Christos Bakalis)
--
----------------------------------------------------------------------------------
library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use UNISIM.VComponents.all;


entity clk_gen_wrapper is
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_500             : in  std_logic;
        clk_160             : in  std_logic;
        clk_125             : in  std_logic;
        rst                 : in  std_logic;
        mmcm_locked         : in  std_logic;
        CKTP_raw            : out std_logic;
        ------------------------------------
        ----- Configuration Interface ------
        cktp_enable         : in  std_logic;
        cktp_primary        : in  std_logic;
        readout_mode        : in  std_logic;
        enable_ro_ckbc      : in  std_logic;
        cktp_pulse_width    : in  std_logic_vector(4 downto 0);
        cktp_max_num        : in  std_logic_vector(15 downto 0);
        cktp_period         : in  std_logic_vector(15 downto 0);
        cktp_skew           : in  std_logic_vector(4 downto 0);        
        ckbc_freq           : in  std_logic_vector(5 downto 0);
        ckbc_max_num        : in  std_logic_vector(7 downto 0);
        ------------------------------------
        ---------- VMM Interface -----------
        CKTP                : out std_logic;
        CKBC                : out std_logic
    );
end clk_gen_wrapper;

architecture RTL of clk_gen_wrapper is

    component cktp_gen
    port(
        clk_160         : in  std_logic;
        cktp_start      : in  std_logic;
        vmm_ckbc        : in  std_logic; -- CKBC clock currently dynamic
        cktp_primary    : in  std_logic;
        ckbc_mode       : in  std_logic;
        ckbc_freq       : in  std_logic_vector(5 downto 0);
        skew            : in  std_logic_vector(4 downto 0);
        pulse_width     : in  std_logic_vector(11 downto 0);
        period          : in  std_logic_vector(21 downto 0);
        CKTP            : out std_logic
    );
    end component;

    component cktp_counter
    port(
        clk_160         : in  std_logic;
        cktp_start      : in  std_logic;
        cktp_pulse      : in  std_logic;
        cktp_max        : in  std_logic_vector(15 downto 0);
        cktp_inhibit    : out std_logic
    );
    end component;

    component ckbc_gen
    port(  
        clk_160         : in  std_logic;
        duty_cycle      : in  std_logic_vector(7 downto 0);
        freq            : in  std_logic_vector(5 downto 0);
        readout_mode    : in  std_logic;
        enable_ro_ckbc  : in  std_logic;
        ready           : in  std_logic;
        ckbc_ro_out     : out std_logic;
        ckbc_out        : out std_logic;
        ckbc_max_num    : in  std_logic_vector(7 downto 0)
    );
    end component;
    
    component skew_gen
    port(
        clk_500         : in std_logic;
        CKTP_preSkew    : in std_logic;
        skew            : in std_logic_vector(4 downto 0);
        CKTP_skewed     : out std_logic
    );    
    end component;

    signal ckbc_start           : std_logic := '0';
    signal cktp_start           : std_logic := '0';
    signal cktp_gen_start       : std_logic := '0';
    signal cktp_inhibit         : std_logic := '0';

    signal CKBC_preBuf          : std_logic := '0';
    signal CKBC_ro_preBuf       : std_logic := '0';
    signal CKBC_glbl            : std_logic := '0';
    
    signal CKTP_from_orig_gen   : std_logic := '0';
    signal CKTP_from_skew_gen   : std_logic := '0';
    signal CKTP_glbl            : std_logic := '0';
    
    signal sel_skew_gen         : std_logic := '0';
    signal skew_cktp_gen        : std_logic_vector(4 downto 0)  := (others => '0');
    
    signal cktp_width_final     : std_logic_vector(11 downto 0) := "000101000000";           --4 * 80 = 320
    signal cktp_period_final    : std_logic_vector(21 downto 0) := "0000100111000100000000"; --5'000 * 32 = 160'000 
    
begin

ckbc_generator: ckbc_gen
    port map(  
        clk_160         => clk_160,
        duty_cycle      => (others => '0'), -- unused
        readout_mode    => readout_mode,
        enable_ro_ckbc  => enable_ro_ckbc,
        freq            => ckbc_freq,
        ready           => ckbc_start,
        ckbc_ro_out     => CKBC_ro_preBuf,
        ckbc_out        => CKBC_preBuf,
        ckbc_max_num    => ckbc_max_num
    );
      
CKBC_BUFGMUX: BUFGMUX
    port map(O => CKBC_glbl, I0 => CKBC_preBuf, I1 => CKBC_ro_preBuf, S => readout_mode);

cktp_generator: cktp_gen
    port map(
        clk_160         => clk_160,
        cktp_start      => cktp_gen_start,
        cktp_primary    => cktp_primary,
        vmm_ckbc        => CKBC_preBuf,
        ckbc_mode       => readout_mode,
        ckbc_freq       => ckbc_freq,
        skew            => skew_cktp_gen,
        pulse_width     => cktp_width_final,
        period          => cktp_period_final,
        CKTP            => CKTP_from_orig_gen
    );

cktp_max_module: cktp_counter
    port map(
        clk_160         => clk_160,
        cktp_start      => cktp_start,
        cktp_pulse      => CKTP_from_orig_gen,
        cktp_max        => cktp_max_num,
        cktp_inhibit    => cktp_inhibit
    );
    
skewing_module: skew_gen
    port map(
        clk_500         => clk_500,
        CKTP_preSkew    => CKTP_from_orig_gen,
        skew            => cktp_skew,
        CKTP_skewed     => CKTP_from_skew_gen
    );

CKTP_BUFGMUX: BUFGMUX
    port map(O => CKTP_glbl, I0 => CKTP_from_orig_gen, I1 => CKTP_from_skew_gen, S => sel_skew_gen);
    
skew_sel_proc: process(ckbc_freq, cktp_skew)
begin
    case ckbc_freq is
    when "101000" => -- 40
        skew_cktp_gen   <= (others => '0'); -- skewing controlled by skew_gen
        if(cktp_skew = "00000")then
            sel_skew_gen <= '0'; -- no skew
        else
            sel_skew_gen <= '1'; -- select high granularity skewing module (2 ns step size)
        end if;
             
    when others =>
        sel_skew_gen    <= '0'; -- select low granularity skewing from cktp_gen (6.125 ns step size)
        skew_cktp_gen   <= cktp_skew;
    end case;
end process;

    cktp_start      <= not rst and cktp_enable and mmcm_locked;
    cktp_gen_start  <= not rst and cktp_enable and mmcm_locked and not cktp_inhibit;
    ckbc_start      <= not rst and mmcm_locked;

    CKBC            <= CKBC_glbl;
    CKTP            <= CKTP_glbl;
    CKTP_raw        <= CKTP_from_orig_gen;
    
    --- conversions ----
    cktp_width_final    <= std_logic_vector(unsigned(cktp_pulse_width)*"1010000");  -- input x 80
    cktp_period_final   <= std_logic_vector(unsigned(cktp_period)*"100000");        -- input x 32
    
end RTL;
