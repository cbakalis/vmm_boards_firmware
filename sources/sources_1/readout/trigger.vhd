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
-- Create Date: 18.05.2016
-- Design Name: 
-- Module Name: trigger.vhd - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
--
-- Changelog:
-- 18.08.2016 Added tr_hold signal to hold trigger when reading out (Reid Pinkham)
-- 26.02.2017 Moved to a global clock domain @125MHz (Paris)
-- 27.02.2017 Synced trout (Paris)
-- 31.03.2017 Added 2 ckbc mode, requests 2 CKBC upon ext trigger (Paris)
-- 06.04.2017 Configurable latency was added for the 2 CKBC mode (Paris)
-- 28.04.2017 Added two processes that assert the level0 signal. (Christos Bakalis)
--
----------------------------------------------------------------------------------

library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity trigger is
    Generic ( vmmReadoutMode : STD_LOGIC;
              useDelay       : STD_LOGIC);
    Port (
            clk             : in STD_LOGIC;
            ckbc            : in STD_LOGIC;
            clk_art         : in STD_LOGIC;
            rst_trig        : in STD_LOGIC;
            
            ckbcMode        : in STD_LOGIC;
            request2ckbc    : out STD_LOGIC;
            cktp_enable     : in std_logic;
            cktp_pulse_width: in STD_LOGIC_VECTOR(4 downto 0);
            CKTP_raw        : in STD_LOGIC;
            pfBusy          : in STD_LOGIC;
            
            tren            : in STD_LOGIC;
            tr_hold         : in STD_LOGIC;
            trmode          : in STD_LOGIC;
            trext           : in STD_LOGIC;
            level_0         : out STD_LOGIC;
            accept_wr       : out STD_LOGIC;
            sel_number      : out STD_LOGIC;
            latency_extra   : in STD_LOGIC_VECTOR(15 DOWNTO 0);
            delay_limit     : in STD_LOGIC_VECTOR(15 DOWNTO 0);
            trigger_pf      : out STD_LOGIC;

            reset           : in STD_LOGIC;

            event_counter   : out STD_LOGIC_VECTOR(31 DOWNTO 0);
            tr_out          : out STD_LOGIC;
            trraw_synced125 : out STD_LOGIC;
            trraw_synced160 : out std_logic;
            latency         : in STD_LOGIC_VECTOR(15 DOWNTO 0)
            );
end trigger;

architecture Behavioral of trigger is

-- Signals

    signal event_counter_i      : std_logic_vector(31 downto 0)    := ( others => '0' );
    signal tr_out_i             : std_logic := '0';
    signal mode                 : std_logic := '0';
    signal trint_pre            : std_logic := '0';
    signal trext_pre            : std_logic := '0';
    signal trext_stage1         : std_logic := '0';
    signal trext_ff_synced      : std_logic := '0';    
    signal tren_buff            : std_logic := '0'; -- buffered enable signal
    signal tr_out_i_stage1      : std_logic := '0';
    signal tr_out_i_ff_synced   : std_logic := '0';
    signal trext_stage_resynced : std_logic := '0';
    signal trext_ff_resynced    : std_logic := '0';
    signal tren_buff_stage1     : std_logic := '0';
    signal tren_buff_ff_synced  : std_logic := '0';
    signal mode_stage1          : std_logic := '0';
    signal mode_ff_synced       : std_logic := '0';
    signal ckbcMode_stage1      : std_logic := '0';
    signal ckbcMode_ff_synced   : std_logic := '0';
    signal trmode_stage1        : std_logic := '0';
    signal trmode_ff_synced     : std_logic := '0';
    signal accept_wr_i          : std_logic := '0';
    signal accept_wr_i_stage1   : std_logic := '0';
    signal accept_wr_synced125  : std_logic := '0';
    signal trraw_synced125_i    : std_logic := '0';
    signal pfBusy_stage1        : std_logic := '0';
    signal pfBusy_stage_synced  : std_logic := '0';
    signal trint_stage_synced   : std_logic := '0';
    signal trint_stage_synced125: std_logic := '0';
    signal trint_ff_synced125   : std_logic := '0';
    signal flag_sent_stage1     : std_logic := '0';
    signal flag_sent_synced     : std_logic := '0';
    signal cktp_width_final     : std_logic_vector(11 downto 0) := "000101000000";           --4 * 80 = 320
    signal trint                : std_logic := '0';
    signal cnt                  : integer range 0 to 7 := 0;
    signal level_0_req          : std_logic := '0';
    signal level_0_25ns         : std_logic := '0';
    signal flag_sent            : std_logic := '0';
    signal trigger_pf_i         : std_logic := '0';
    signal trigger_pf_i_stage1  : std_logic := '0';         
 
    -- Special Readout Mode
    signal request2ckbc_i    : std_logic := '0';
    signal trigLatencyCnt    : unsigned(15 downto 0) := (others => '0');
    signal trigLatency       : unsigned(15 downto 0) := x"008c";
    signal trigLatencyExtra  : unsigned(15 downto 0) := x"0058"; -- 88*6.25=550ns
    
    type stateType is (waitingForTrigger, waitingForLatency, waitingForSingleCKBC, changeNumberOfCKBC, 
                       timeoutThenRequest, reqOneCKBC,  waitingForLatency_1, waitingForLatency_2, 
                       timeoutBeforeIdle, issueRequest, checkTrigger, checkForTrg);
    signal state            : stateType := waitingForTrigger;
    signal state_l0         : stateType := waitingForTrigger;
    
    attribute FSM_ENCODING              : string;
    attribute FSM_ENCODING of state     : signal is "ONE_HOT";
    attribute FSM_ENCODING of state_l0  : signal is "ONE_HOT";

    
---------------------------------------------------------------------------------------------- Uncomment for hold window Start
    signal hold_cnt         : unsigned(15 downto 0) := (others => '0');
    signal start            : std_logic;
    signal hold_delay       : std_logic := '0';
    signal state_hold       : std_logic_vector(1 downto 0) := (others => '0');
---------------------------------------------------------------------------------------------- Uncomment for hold window End
    
    -- Debugging
    signal probe0_out         : std_logic_vector(63 downto 0);
    
-- Attributes
---------------------------------------------------------------------------------------------- Uncomment for hold window Start
--    constant delay : std_logic_vector(31 downto 0) := x"00000002"; -- Number of 200 MHz clock cycles to hold trigger in hex
---------------------------------------------------------------------------------------------- Uncomment for hold window End

    attribute keep : string;
    
    attribute keep of tren      : signal is "true";
    attribute keep of tren_buff : signal is "true";
    attribute keep of tr_out_i  : signal is "true";
    attribute keep of trmode    : signal is "true";
    attribute keep of trint     : signal is "true";
    
-------------------------------------------------------------------
-- Mark debug signals for ILA
-------------------------------------------------------------------    
    attribute mark_debug : string;

--    attribute mark_debug of event_counter_i     :    signal    is    "true";
--    attribute mark_debug of tr_out_i            :    signal    is    "true";
--    attribute mark_debug of tren                :    signal    is    "true";
--    attribute mark_debug of trmode              :    signal    is    "true";
--    attribute mark_debug of trint               :    signal    is    "true";
--    attribute mark_debug of mode                :    signal    is    "true";
--    attribute mark_debug of trint_pre           :    signal    is    "true";
--    attribute mark_debug of trext_pre           :    signal    is    "true";
--    attribute mark_debug of tr_out_i_ff_synced  :    signal    is    "true";
--    attribute mark_debug of trext               :    signal    is    "true";
--    attribute mark_debug of tren_buff           :    signal    is    "true";

-------------------------------------------------------------------
-- Async Regs
-------------------------------------------------------------------
    attribute ASYNC_REG : string;
    
    attribute ASYNC_REG of tr_out_i_stage1      : signal is "true";
    attribute ASYNC_REG of tr_out_i_ff_synced   : signal is "true";
    attribute ASYNC_REG of trext_stage_resynced : signal is "true";
    attribute ASYNC_REG of trext_ff_resynced    : signal is "true";
    attribute ASYNC_REG of trext_stage1         : signal is "true";
    attribute ASYNC_REG of trext_ff_synced      : signal is "true";
    attribute ASYNC_REG of tren_buff_stage1     : signal is "true";
    attribute ASYNC_REG of tren_buff_ff_synced  : signal is "true";
    attribute ASYNC_REG of mode_stage1          : signal is "true";
    attribute ASYNC_REG of mode_ff_synced       : signal is "true";
    attribute ASYNC_REG of trmode_stage1        : signal is "true";
    attribute ASYNC_REG of trmode_ff_synced     : signal is "true";
    attribute ASYNC_REG of accept_wr_i_stage1   : signal is "true";
    attribute ASYNC_REG of accept_wr_synced125  : signal is "true";
    attribute ASYNC_REG of pfBusy_stage1        : signal is "true";
    attribute ASYNC_REG of pfBusy_stage_synced  : signal is "true";
    attribute ASYNC_REG of flag_sent_stage1     : signal is "true";
    attribute ASYNC_REG of flag_sent_synced     : signal is "true";
    attribute ASYNC_REG of ckbcMode_stage1      : signal is "true";
    attribute ASYNC_REG of ckbcMode_ff_synced   : signal is "true";
    attribute ASYNC_REG of trigger_pf_i_stage1  : signal is "true";
    attribute ASYNC_REG of trigger_pf           : signal is "true";
    
-- Components if any

    component ila_trigger
    port(
        clk     : in std_logic;
        probe0  : in std_logic_vector(63 downto 0)
    );
    end component;
    
    component trint_gen
    generic(vmmReadoutMode : std_logic);
    port(
        clk_160     : in  std_logic;
        clk_125     : in  std_logic;
        cktp_start  : in  std_logic;
        cktp_pulse  : in  std_logic;
        ckbc_mode   : in  std_logic;
        cktp_width  : in  std_logic_vector(11 downto 0);
        trint       : out std_logic
    );
    end component;

begin

-- Processes
---------------------------------------------------------------------------------------------- Uncomment for hold window Start
holdDelay: process (clk) -- state machine to manage delay
begin
    if rising_edge(clk) then
        if (reset = '1') then
            hold_delay  <= '0';
            state_hold  <= (others => '0');
            hold_cnt    <= (others => '0');
        else
            case state_hold is 
                when "00" => -- Idle
                    if (start = '1') then -- wait for start signal
                        state_hold <= "01";
                    else
                        state_hold <= "00";
                    end if;

                when "01" => -- st1
                    if (tr_out_i_ff_synced = '0') then -- trigger returned to zero, start the count
                        hold_delay  <= '1';
                        hold_cnt    <= (others => '0'); -- reset the counter
                        state_hold  <= "10";
                    else
                        state_hold  <= "01";
                    end if;

                when "10" => -- st2
                    if (hold_cnt = unsigned(delay_limit)) then -- reached end of deadtime
                        if ((trext_ff_resynced = '0' and mode = '1') or (trint_ff_synced125 = '0' and mode = '0')) then -- No current trigger
                            hold_delay  <= '0';
                            state_hold  <= "00";
                        else
                            state_hold  <= "11";
                        end if;

                        hold_cnt <= (others => '0');
                    else
                        hold_cnt <= hold_cnt + 1;
                    end if;

                when "11" => -- st3
                    if ((trext_ff_resynced = '0' and mode = '1') or (trint_ff_synced125 = '0' and mode = '0')) then -- wait until missed trigger ends
                        state_hold  <= "00";
                        hold_delay  <= '0';
                    else
                        state_hold  <= "11";
                    end if;

                when others =>
                    state_hold  <= "00";
                    hold_delay  <= '0';
                    hold_cnt    <= (others => '0');
            end case ;
        end if;    
    end if;
end process;


triggerLatch: process (tr_out_i_ff_synced, hold_delay)
begin
    if (tr_out_i_ff_synced = '1' and hold_delay = '0') then -- start of trigger
        start <= '1';
    else -- Release the start command
        start <= '0';
    end if;
end process;
---------------------------------------------------------------------------------------------- Uncomment for hold window End
generate_2ckbc: if (vmmReadoutMode = '0') generate

trReadoutMode2CkbcDelayedRequest: process(clk_art)
begin
    if rising_edge(clk_art) then
        if(rst_trig = '1')then
            request2ckbc_i  <= '0';
            trigLatencyCnt  <= (others => '0');
            sel_number      <= '0';
            trigger_pf_i    <= '0';
            state           <= waitingForTrigger;
        else      
            case state is
            
                when waitingForTrigger =>
                    request2ckbc_i      <= '0';
                    sel_number          <= '0';
                    trigger_pf_i        <= '0';
                    trigLatencyCnt      <= (others => '0');
                    if ((tren_buff_ff_synced = '1' and tr_out_i = '1' and ckbcMode_ff_synced = '1' and mode_ff_synced = '1') or
                        (tren_buff_ff_synced = '1' and trint = '1' and ckbcMode_ff_synced = '1' and mode_ff_synced = '0'))then
                        state               <= waitingForLatency;
                    end if;
                    
                when waitingForLatency =>
                    if trigLatencyCnt < trigLatency then
                        trigLatencyCnt  <= trigLatencyCnt + 1;
                    else
                        state           <= issueRequest;
                    end if;
                    
                when issueRequest =>
                    request2ckbc_i      <= '1';
                    trigLatencyCnt      <= (others => '0');
                    state               <= waitingForSingleCKBC;

                when waitingForSingleCKBC =>
                    request2ckbc_i      <= '0';
                    if trigLatencyCnt < trigLatencyExtra then
                        trigLatencyCnt <= trigLatencyCnt + 1;
                    else
                        trigLatencyCnt <= (others => '0');
                        state          <= changeNumberOfCKBC;
                    end if;

                when changeNumberOfCKBC =>
                    sel_number <= '1';
                    state      <= timeoutThenRequest;

                when timeoutThenRequest =>
                    if trigLatencyCnt < 10 then
                        trigLatencyCnt <= trigLatencyCnt + 1;
                    else
                        state          <= reqOneCKBC;
                    end if;

                when reqOneCKBC =>
                    request2ckbc_i <= '1';
                    trigLatencyCnt <= (others => '0');
                    state          <=  timeoutBeforeIdle;

                when timeoutBeforeIdle =>
                    request2ckbc_i <= '0';
                    trigger_pf_i   <= '1';
                    if trigLatencyCnt < 20 then
                        trigLatencyCnt <= trigLatencyCnt + 1;
                    else
                        state          <= checkForTrg;
                    end if;

               when checkForTrg => -- wait for trigs to go low
                    if((trint = '0' and mode_ff_synced = '0') or
                        (tr_out_i = '0' and mode_ff_synced = '1'))then
                        state <= waitingForTrigger;
                    else
                        state <= checkForTrg;
                    end if;
                    
                when others =>
                    request2ckbc_i      <= '0';
                    trigLatencyCnt      <= (others => '0');
                    sel_number          <= '0';
                    trigger_pf_i        <= '0';
                    state               <= waitingForTrigger;

            end case;
        end if;
    end if;
end process;

end generate generate_2ckbc;

generate_level0: if (vmmReadoutMode = '1') generate

-- asserts level0 accept signal at the VMMs with a maximum of ~1.6 us latency
level0Asserter: process(clk_art)
begin
    if(rising_edge(clk_art))then
        if(rst_trig = '1')then
            level_0_req     <= '0';
            trigLatencyCnt  <= (others => '0');
            accept_wr_i     <= '0';
            state_l0        <= waitingForTrigger;
        else
            case state_l0 is

            when waitingForTrigger =>
                level_0_req     <= '0';
                accept_wr_i     <= '0';
                trigLatencyCnt  <= (others => '0');

                -- proceed only if pf is @ idle
                if((trext_ff_synced = '1' and trmode_ff_synced = '1' and pfBusy_stage_synced = '0') or
                    (trint = '1' and trmode_ff_synced = '0' and pfBusy_stage_synced = '0'))then
                    state_l0 <= waitingForLatency_1;
                else
                    state_l0 <= waitingForTrigger;
                end if;

            when waitingForLatency_1 => -- open the acceptance window for the level-0 buffer
                if trigLatencyCnt < trigLatency - 30 then
                    trigLatencyCnt  <= trigLatencyCnt + 1;
                    state_l0        <= waitingForLatency_1;
                else
                    accept_wr_i     <= '1';
                    state_l0        <= waitingForLatency_2;
                end if;

            when waitingForLatency_2 =>
                if trigLatencyCnt < trigLatency then
                    trigLatencyCnt  <= trigLatencyCnt + 1;
                    state_l0        <= waitingForLatency_2;
                else
                    trigLatencyCnt  <= (others => '0');
                    state_l0        <= issueRequest;
                end if;
                
            when issueRequest =>
                level_0_req <= '1';
                accept_wr_i <= '0';
                if(flag_sent_synced = '1')then
                    state_l0 <= checkTrigger;
                else
                    state_l0 <= issueRequest;
                end if;

            when checkTrigger =>
                level_0_req     <= '0';

                if((trext_ff_synced = '0' and trmode_ff_synced = '1') or
                    (trint = '0' and trmode_ff_synced = '0'))then
                    state_l0 <= waitingForTrigger;
                else
                    state_l0 <= checkTrigger;
                end if;

            when others =>
                level_0_req     <= '0';
                trigLatencyCnt  <= (others => '0');
                accept_wr_i     <= '0';
                state_l0        <= waitingForTrigger;
            end case;
        end if;
    end if;
end process;

-- process that ensures a one-CKBC-width level0 pulse is asserted
level0_40_proc: process(ckbc)
begin
    if(rising_edge(ckbc))then
        if(flag_sent = '1' and level_0_req = '1')then null; -- wait
        elsif(flag_sent = '1' and level_0_req = '0')then -- reset everything
            level_0_25ns <= '0';
            flag_sent    <= '0';
        elsif(level_0_25ns = '1')then -- level_0 to VMMs has a width of 25ns
            level_0_25ns <= '0';
            flag_sent    <= '1';
        elsif(level_0_req = '1')then -- level_0 latched from level0Asserter
            level_0_25ns <= '1';
        else
            level_0_25ns <= '0';
            flag_sent    <= '0';
        end if;
    end if;
end process;

end generate generate_level0; 

trenAnd: process(clk)
begin
    if rising_edge(clk) then
        if (tren = '1' and hold_delay = '0' and useDelay = '1') then -- No internal hold command, trigger enabled
            tren_buff <= '1';
        elsif (tren = '1' and tr_hold = '0' and useDelay = '0') then -- No external hold command, trigger enabled
            tren_buff <= '1'; 
        else
            tren_buff <= '0';
        end if;
    end if;
end process;

changeModeCommandProc: process (clk)
    begin
        if rising_edge(clk) then
            if tren_buff = '1' then
                if trmode = '0' then                                -- Internal trigger
                    mode <= '0';
                else                                                -- External trigger
                    mode <= '1';
                end if;
            end if;
        end if;
    end process;

triggerDistrSignalProc: process (clk_art, reset)
    begin
        if reset = '1' then
            tr_out_i            <= '0';
        elsif rising_edge(clk_art) then
            if mode_ff_synced = '0' then
                if (tren_buff_ff_synced = '1' and trmode_ff_synced = '0' and trint = '1') then
                    tr_out_i            <= '1';
                elsif (trmode_ff_synced = '0' and trint = '0') then
                    tr_out_i            <= '0';
                else
                    tr_out_i            <= '0';
                end if;
            else
                if (tren_buff_ff_synced = '1' and trmode_ff_synced = '1' and trext_ff_synced = '1') then
                    tr_out_i            <= '1';
                elsif (trmode_ff_synced = '1' and trext_ff_synced = '0') then
                    tr_out_i            <= '0';
                else
                    tr_out_i            <= '0';
                end if;
            end if;
        end if;
    end process;

troutSyncToFpgaLogic: process(clk)
begin
    if rising_edge(clk) then 
        tr_out_i_stage1         <= tr_out_i;
        tr_out_i_ff_synced      <= tr_out_i_stage1;
        trext_stage_resynced    <= trext_ff_synced;
        trext_ff_resynced       <= trext_stage_resynced;
        trint_stage_synced125   <= trint;
        trint_ff_synced125      <= trint_stage_synced125;
        accept_wr_i_stage1      <= accept_wr_i;
        accept_wr_synced125     <= accept_wr_i_stage1;
        trigger_pf_i_stage1     <= trigger_pf_i;
        trigger_pf              <= trigger_pf_i_stage1;
    end if;
end process;

externalTriggerSynchronizer160: process(clk_art)
begin
    if rising_edge(clk_art) then 
        trext_stage1        <= trext;
        trext_ff_synced     <= trext_stage1;
        tren_buff_stage1    <= tren_buff;
        tren_buff_ff_synced <= tren_buff_stage1;
        mode_stage1         <= mode;
        mode_ff_synced      <= mode_stage1;
        trmode_stage1       <= trmode;
        trmode_ff_synced    <= trmode_stage1;
        pfBusy_stage1       <= pfBusy;
        pfBusy_stage_synced <= pfBusy_stage1;
        flag_sent_stage1    <= flag_sent;
        flag_sent_synced    <= flag_sent_stage1;
        ckbcMode_stage1     <= ckbcMode;
        ckbcMode_ff_synced  <= ckbcMode_stage1;
    end if;
end process;

eventCounterProc: process (clk_art, reset)
    begin
        if reset = '1' then
            event_counter_i     <= x"00000000";
        else
            if rising_edge(clk_art) then
                if mode_ff_synced = '0' then
                    if (tren_buff_ff_synced = '1' and trmode_ff_synced = '0' and trint = '1' and trint_pre = '0') then
                        event_counter_i     <= event_counter_i + 1;
                        trint_pre           <= '1';
                    elsif (trmode_ff_synced = '0' and trint = '0') then
                        event_counter_i     <= event_counter_i;
                        trint_pre           <= '0';
                    else
                        event_counter_i     <= event_counter_i;
                    end if;
                else
                    if (tren_buff_ff_synced = '1' and trmode_ff_synced = '1' and trext_ff_synced = '1' and trext_pre = '0') then
                        event_counter_i     <= event_counter_i + 1;
                        trext_pre           <= '1';
                    elsif (trmode_ff_synced = '1' and trext_ff_synced = '0') then
                        event_counter_i     <= event_counter_i;
                        trext_pre           <= '0';
                    else
                        event_counter_i     <= event_counter_i;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
triggerRawMux:process (trext_ff_resynced, trint_ff_synced125, trmode, reset)
begin
    if reset = '1' then
        trraw_synced125_i   <= '0';
    else
        if trmode = '1' then
            trraw_synced125_i   <= trext_ff_resynced;
        elsif trmode = '0' then
            trraw_synced125_i   <= trint_ff_synced125;
        end if;
    end if;
end process;
    
-- Signal assignments
event_counter       <= event_counter_i;
tr_out              <= tr_out_i_ff_synced;
request2ckbc        <= request2ckbc_i;
trraw_synced125     <= trraw_synced125_i;
trigLatency         <= unsigned(latency);
trigLatencyExtra    <= unsigned(latency_extra);
accept_wr           <= accept_wr_synced125;
level_0             <= level_0_25ns;
cktp_width_final    <= std_logic_vector(unsigned(cktp_pulse_width)*"1010000");  -- input x 80
trraw_synced160     <= tr_out_i;

-- Instantiations if any

cktp_trint_module: trint_gen
    generic map(vmmReadoutMode => vmmReadoutMode)
    port map(
        clk_160         => clk_art,
        clk_125         => clk,
        cktp_start      => cktp_enable,
        cktp_pulse      => CKTP_raw,
        ckbc_mode       => ckbcMode_ff_synced,
        cktp_width      => cktp_width_final,
        trint           => trint -- synced to 160 Mhz
    );

--ilaTRIG: ila_trigger
--port map(
--    clk                     =>  clk_art,
--    probe0                  =>  probe0_out
--    );
    
    probe0_out(0)               <= tr_out_i_ff_synced;
    probe0_out(1)               <= trext;
    probe0_out(2)               <= trmode;
    probe0_out(3)               <= trint;
    probe0_out(4)               <= mode;
    probe0_out(5)               <= trint_pre;
    probe0_out(6)               <= trext_pre;
    probe0_out(7)               <= tren_buff;
    probe0_out(8)               <= request2ckbc_i;
    probe0_out(9)               <= trext_ff_synced;
    probe0_out(63 downto 10)    <= (others => '0');

end Behavioral;