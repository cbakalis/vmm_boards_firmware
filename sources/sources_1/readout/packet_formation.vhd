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
-- Create Date: 25.06.2016
-- Design Name: 
-- Module Name: packet_formation.vhd - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2017.1
--
-- Changelog:
-- 22.08.2016 Changed readout trigger pulse from 125 to 100 ns long (Reid Pinkham)
-- 09.09.2016 Added two signals for ETR interconnection (Christos Bakalis)
-- 26.02.2016 Moved to a global clock domain @125MHz (Paris)
-- 06.04.2017 Hard setting latency to 300ns as configurable latency was moved to trigger module (Paris)
-- 25.04.2017 Added vmm_driver module. (Christos Bakalis)
-- 06.06.2017 Added ART header a handling (Paris)
-- 
----------------------------------------------------------------------------------

library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity packet_formation is
    Generic(is_mmfe8        : std_logic;
            vmmReadoutMode  : std_logic;
            artEnabled      : std_logic);
    Port(
        clk             : in std_logic;

        newCycle        : in std_logic;
        
        trigVmmRo       : out std_logic;
        vmmId           : out std_logic_vector(2 downto 0);
        vmmWord         : in std_logic_vector(15 downto 0);
        vmmWordReady    : in std_logic;
        vmmEventDone    : in std_logic;

        UDPDone         : in std_logic;
        pfBusy          : out std_logic;                        -- Control signal to ETR
        glBCID          : in std_logic_vector(11 downto 0);     -- glBCID counter from ETR

        packLen         : out std_logic_vector(11 downto 0);
        dataout         : out std_logic_vector(15 downto 0);
        wrenable        : out std_logic;
        end_packet      : out std_logic;
        
        rd_ena_buff     : out std_logic;
        rst_l0          : out std_logic;
        
        tr_hold         : out std_logic;
        reset           : in std_logic;
        rst_vmm         : out std_logic;
        linkHealth_bmsk : in std_logic_vector(8 downto 1);
        rst_FIFO        : out std_logic;
        
        latency         : in std_logic_vector(15 downto 0);
        dbg_st_o        : out std_logic_vector(4 downto 0);
        trraw_synced125 : in std_logic;
        vmmArtData125   : in std_logic_vector(5 downto 0);
        vmmArtReady     : in std_logic;
        art2trigger     : in std_logic_vector(5 downto 0)
    );
end packet_formation;

architecture Behavioral of packet_formation is

    signal header           : std_logic_vector(63 downto 0) := ( others => '0' );
    signal header_l0        : std_logic_vector(47 downto 0) := ( others => '0' );
    signal vmmId_i          : std_logic_vector(2 downto 0)  := b"000";
    signal globBcid         : std_logic_vector(15 downto 0) := x"FFFF"; --( others => '0' );
    signal precCnt          : std_logic_vector(7 downto 0)  := x"00"; --( others => '0' );
    signal globBcid_i       : std_logic_vector(15 downto 0);
    signal globBCID_etr		: std_logic_vector(11 downto 0) := (others => '0'); --globBCID counter as it is coming from ETR
    signal eventCounter_i   : unsigned(31 downto 0) := to_unsigned(0, 32);
    signal wait_Cnt         : integer range 0 to 31 := 0;
    signal vmmId_cnt        : integer range 0 to 7 := 0;
    signal trigLatencyCnt   : integer := 0;
    signal trigLatency      : integer := 140; -- 700ns (140x5ns)
    signal pfBusy_i         : std_logic	:= '0';               -- control signal to be sent to ETR

    signal daqFIFO_wr_en_hdr    : std_logic                     := '0';
    signal daqFIFO_wr_en_drv    : std_logic                     := '0';
    signal sel_wrenable         : std_logic                     := '0';
    signal drv_enable           : std_logic                     := '0';
    signal drv_done             : std_logic                     := '0';
    signal daqFIFO_din          : std_logic_vector(15 downto 0) := ( others => '0' );
    signal triggerVmmReadout_i  : std_logic := '0';
    signal selectDataInput      : std_logic_vector(2 downto 0) := (others => '0');
    signal sel_cnt              : unsigned(2 downto 0)         := (others => '0');

    signal vmmWord_i            : std_logic_vector(15 downto 0) := ( others => '0' );
    signal packLen_i            : unsigned(11 downto 0)         := x"000";
    signal packLen_drv2pf_unsg  : unsigned(11 downto 0)         := x"000";
    signal packLen_drv2pf       : std_logic_vector(11 downto 0) := x"000";
    signal packLen_cnt          : unsigned(11 downto 0)         := x"000";
    signal end_packet_int       : std_logic                     := '0';
    signal artValid             : std_logic                     := '0';
    signal trraw_synced125_prev : std_logic                     := '0';
    signal clearValid           : std_logic                     := '0'; 

    type stateType is (waitingForNewCycle, increaseCounter, waitForLatency, captureEventID, setEventID, sendHeaderStep1, sendHeaderStep2, 
                       sendHeaderStep3, triggerVmmReadout, waitForData, sendVmmDataStep1, sendVmmDataStep2, formTrailer, sendTrailer, packetDone, 
                       isUDPDone, isTriggerOff, S2, eventDone);
    signal state            : stateType;

--------------------  Debugging ------------------------------
    signal probe0_out           : std_logic_vector(132 downto 0);
    signal probe1_out           : std_logic_vector(200 downto 0);
    signal debug_state          : std_logic_vector(4 downto 0);
-----------------------------------------------------------------

----------------------  Debugging ------------------------------
--    attribute mark_debug : string;

--    attribute mark_debug of header                :    signal    is    "true";
--    attribute mark_debug of globBcid              :    signal    is    "true";
--    attribute mark_debug of globBcid_i            :    signal    is    "true";
--    attribute mark_debug of precCnt               :    signal    is    "true";
--    attribute mark_debug of vmmId_i               :    signal    is    "true";
--    attribute mark_debug of daqFIFO_din           :    signal    is    "true";
--    attribute mark_debug of vmmWord_i             :    signal    is    "true";
--    attribute mark_debug of packLen_i             :    signal    is    "true";
--    attribute mark_debug of packLen_cnt           :    signal    is    "true";
--    attribute mark_debug of end_packet_int        :    signal    is    "true";
--    attribute mark_debug of triggerVmmReadout_i   :    signal    is    "true";
--    attribute mark_debug of debug_state           :    signal    is    "true";
--    attribute mark_debug of artValid              :    signal    is    "true";
--    attribute mark_debug of trraw_synced125       :    signal    is    "true";
--    attribute mark_debug of vmmArtReady           :    signal    is    "true";

    component ila_pf
    port (
        clk     : in std_logic;
        probe0  : in std_logic_vector(132 downto 0);
        probe1  : in std_logic_vector(200 downto 0)
    );
    end component;

    component vio_0
    port ( 
        clk         : in std_logic;
        probe_out0  : out std_logic_vector ( 11 downto 0 )
    );
    end component;

    component vmm_driver
    port(
        ------------------------------------
        ------ General/PF Interface --------
        clk             : in  std_logic;
        drv_enable      : in  std_logic;
        drv_done        : out std_logic;
        pack_len_drv    : out std_logic_vector(11 downto 0);
        ------------------------------------
        ----- VMM_RO/FIFO2UDP Interface ----
        wr_en_fifo2udp  : out std_logic;
        rd_en_buff      : out std_logic;
        vmmWordReady    : in  std_logic
    );
    end component;

-----------------------------------------------------------------

begin

packetCaptureProc: process(clk, newCycle, vmmEventDone, vmmWordReady, wait_Cnt, UDPDone)
begin

    if rising_edge(clk) then
        if reset = '1' then
            debug_state             <= "11111";
            eventCounter_i          <= to_unsigned(0, 32);
            tr_hold                 <= '0';
            pfBusy_i                <= '0';
            triggerVmmReadout_i     <= '0';
            rst_l0                  <= '1';
            sel_wrenable            <= '0';
            rst_FIFO                <= '1';
            daqFIFO_wr_en_hdr       <= '0';
            packLen_cnt             <= x"000";
            wait_Cnt                <= 0;
            sel_cnt                 <= (others => '0');
            drv_enable              <= '0';
            triggerVmmReadout_i     <= '0';
            end_packet_int          <= '0';
            state                   <= waitingForNewCycle;
        else
        case state is
            when waitingForNewCycle =>
                debug_state             <= "00000";
                pfBusy_i                <= '0';
                triggerVmmReadout_i     <= '0';
                rst_l0                  <= '0';
                sel_wrenable            <= '0';
                drv_enable              <= '0';
                trigLatencyCnt          <= 0;
                sel_cnt                 <= (others => '0');
                rst_FIFO                <= '0';
                if newCycle = '1' then
                    pfBusy_i        <= '1';
                    state           <= increaseCounter;
                end if;
                
            when increaseCounter =>
                debug_state     <= "00001";
                eventCounter_i  <= eventCounter_i + 1;
                state           <= waitForLatency;
                
            when waitForLatency =>
                debug_state <= "00010";
                tr_hold             <= '1'; -- Prevent new triggers
                if(trigLatencyCnt > trigLatency and is_mmfe8 = '1')then 
                    state           <= S2;
                elsif(trigLatencyCnt > trigLatency and is_mmfe8 = '0')then
                    state           <= captureEventID;
                else
                    trigLatencyCnt  <= trigLatencyCnt + 1;
                end if;

            when S2 =>          -- wait for the header elements to be formed
                debug_state     <= "00010";
                packLen_cnt     <= x"000";              -- Reset length count
                sel_wrenable    <= '0';
                vmmId_i         <= std_logic_vector(to_unsigned(vmmId_cnt, 3));
                state           <= captureEventID;

            when captureEventID =>      -- Form Header
                debug_state         <= "00011";
                packLen_cnt         <= x"000";
                state               <= setEventID;
                
            when setEventID =>
                debug_state         <= "00100";
                rst_FIFO            <= '0';
                daqFIFO_wr_en_hdr   <= '0';
                if(wait_Cnt < 3)then
                    wait_Cnt <= wait_Cnt + 1;
                    state    <= setEventID;
                else
                    wait_Cnt <= 0;
                    state    <= sendHeaderStep1;
                end if;

            when sendHeaderStep1 =>
                debug_state         <= "00101";
                daqFIFO_wr_en_hdr   <= '1';
                packLen_cnt         <= packLen_cnt + 1;
                state               <= sendHeaderStep2;

            when sendHeaderStep2 =>
                debug_state         <= "00110";
                daqFIFO_wr_en_hdr   <= '0';
                if(wait_Cnt < 3)then
                    wait_Cnt <= wait_Cnt + 1;
                    state    <= sendHeaderStep2;
                else
                    wait_Cnt <= 0;
                    state    <= sendHeaderStep3;
                end if;

            when sendHeaderStep3 =>
                if(sel_cnt < 5 and vmmReadoutMode = '0')then -- incr the counter to select the other parts of the header
                    sel_cnt <= sel_cnt + 1;   
                    state   <= setEventID;
                elsif(sel_cnt < 4 and vmmReadoutMode = '1')then
                    sel_cnt <= sel_cnt + 1;   
                    state   <= setEventID;
                else -- the whole header has been sent
                    state   <= triggerVmmReadout;
                end if;

            when triggerVmmReadout =>   -- Creates an 136ns pulse to trigger the readout if not at level0 mode
                                        
                debug_state                 <= "00111";
                sel_cnt                     <= "110"; -- fix the counter to 4 to select the VMM data for the next steps
                sel_wrenable                <= '1';   -- grant control to driver
                if wait_Cnt < 30 and vmmReadoutMode = '0' then
                    wait_Cnt                <= wait_Cnt + 1;
                    triggerVmmReadout_i     <= '1';
                else
                    triggerVmmReadout_i     <= '0';
                    wait_Cnt                <= 0;
                    state                   <= waitForData;
                end if;

            when waitForData =>
                debug_state <= "01000";
                if (vmmWordReady = '1') then
                    state           <= sendVmmDataStep1;
                elsif (vmmEventDone = '1') then
                    state           <= sendTrailer; 
                end if;

            when sendVmmDataStep1 =>
                debug_state     <= "01001";
                drv_enable      <= '1';
                state           <= sendVmmDataStep2;

            when sendVmmDataStep2 =>
                debug_state     <= "01010";

                if(drv_done = '1')then
                    state       <= formTrailer;
                else    
                    state       <= sendVmmDataStep2;
                end if;

            when formTrailer =>
                debug_state         <= "01011";
                if (vmmEventDone = '1') then
                    state           <= sendTrailer;
                elsif (vmmEventDone = '0' and vmmWordReady = '0') then  
                    state           <= waitForData;
                else -- (vmmWordReady = '1') then
                    state           <= formTrailer;
                end if;

            when sendTrailer =>
                debug_state   <= "01100";
                packLen_i     <= packLen_cnt + packLen_drv2pf_unsg; 
                state         <= packetDone;

            when packetDone =>
                debug_state     <= "01101";
                end_packet_int  <= '1';
                if(is_mmfe8 = '1')then
                    state       <= eventDone;
                else
                    state       <= isUDPDone;
                end if;

            when eventDone =>
                debug_state     <= "01110";
                end_packet_int  <= '0';
                drv_enable      <= '0';
                if vmmId_cnt = 7 then
                    vmmId_cnt   <= 0;
                    state       <= isUDPDone;
                else
                    vmmId_cnt    <= vmmId_cnt + 1;
                    sel_cnt      <= "000";
                    sel_wrenable <= '0';
                    state        <= S2;
                end if;
                
--            when resetVMMs =>
--                debug_state <= "01111";
--                rst_vmm     <= '1';
--                state       <= resetDone;
                
--            when resetDone =>
--                debug_state <= "10000";
--                if resetting = '0' then
--                    rst_vmm         <= '0';
--                    state       <= isUDPDone;
--                    rst_vmm     <= '0'; -- Prevent from continuously resetting while waiting for UDP Packet
--                end if;

            when isUDPDone =>
                debug_state     <= "01110";
                drv_enable      <= '0';
                end_packet_int  <= '0';
                rst_l0          <= '1'; -- reset the level0 buffers and the interface with packet_formation
               -- pfBusy_i        <= '0';
                if (UDPDone = '1') then -- Wait for the UDP packet to be sent
                    state       <= isTriggerOff;
                end if;
                
            when isTriggerOff =>            -- Wait for whatever ongoing trigger pulse to go to 0
                debug_state <= "01111";
                if trraw_synced125 /= '1' then
                    tr_hold                 <= '0'; -- Allow new triggers
                    state           <= waitingForNewCycle;
                end if;

            when others =>
                tr_hold         <= '0';
                state           <= waitingForNewCycle;
        end case;
    end if;
end if;
end process;

muxFIFOData: process( sel_cnt, header, header_l0, vmmWord, vmmArtData125, art2trigger, artValid )
begin
    case sel_cnt is
    when "000"  => daqFIFO_din <= art2trigger & b"0" & artValid & "00" & vmmArtData125(0) & vmmArtData125(1) & vmmArtData125(2) & vmmArtData125(3) & vmmArtData125(4) & vmmArtData125(5);
    when "001"  => daqFIFO_din <= art2trigger & b"0" & artValid & "01" & vmmArtData125(0) & vmmArtData125(1) & vmmArtData125(2) & vmmArtData125(3) & vmmArtData125(4) & vmmArtData125(5);
    when "010"  => if (vmmReadoutMode = '0') then daqFIFO_din <= header(63 downto 48); else daqFIFO_din <= header_l0(47 downto 32); end if;
    when "011"  => if (vmmReadoutMode = '0') then daqFIFO_din <= header(47 downto 32); else daqFIFO_din <= header_l0(31 downto 16); end if;
    when "100"  => if (vmmReadoutMode = '0') then daqFIFO_din <= header(31 downto 16); else daqFIFO_din <= header_l0(15 downto 0); end if;
    when "101"  => daqFIFO_din <= header(15 downto 0);
    when "110"  => daqFIFO_din <= vmmWord;
    when others => daqFIFO_din <= (others => '0');
    end case;
end process;

muxWrEn: process( sel_wrenable, daqFIFO_wr_en_hdr, daqFIFO_wr_en_drv )
begin
    case sel_wrenable is
    when '0'    => wrenable <= daqFIFO_wr_en_hdr;
    when '1'    => wrenable <= daqFIFO_wr_en_drv;
    when others => wrenable <= '0';
    end case;
end process;

vmm_driver_inst: vmm_driver
    port map(
        ------------------------------------
        ------ General/PF Interface --------
        clk             => clk,
        drv_enable      => drv_enable,
        drv_done        => drv_done,
        pack_len_drv    => packLen_drv2pf,
        ------------------------------------
        ----- VMM_RO/FIFO2UDP Interface ----
        wr_en_fifo2udp  => daqFIFO_wr_en_drv,
        rd_en_buff      => rd_ena_buff,
        vmmWordReady    => vmmWordReady
    );
    
triggerEdgeDetection: process(clk) --125
begin
    if rising_edge(clk) then 
        if trraw_synced125_prev = '0' and trraw_synced125 = '1' then 
            clearValid              <= '1';
            trraw_synced125_prev    <= trraw_synced125;
        else
            clearValid              <= '0';
            trraw_synced125_prev    <= trraw_synced125;
        end if;
    end if;
end process;
    
LDCE_inst : LDCE
generic map (
  INIT => '0')
port map (
  Q => artValid,
  CLR => clearValid,
  D => '1',
  G => vmmArtReady,
  GE => artEnabled
);			
					
    globBcid_i      <= globBcid;
    vmmWord_i       <= vmmWord;
    dataout         <= daqFIFO_din;
    packLen         <= std_logic_vector(packLen_i);
    end_packet      <= end_packet_int;
    trigVmmRo       <= triggerVmmReadout_i;
    vmmId           <= vmmId_i;
    trigLatency     <= 50 + to_integer(unsigned(latency)); --(hard set to 400ns )--to_integer(unsigned(latency));
    pfBusy          <= pfBusy_i;
    globBCID_etr    <= glBCID;
    
    -- header of level 0 has three 16-bit words from FPGA + one 16-bit word from VMM
    header_l0(47 downto 16) <= std_logic_vector(eventCounter_i);
    header_l0(15 downto 0)  <=  b"00000" & vmmId_i & linkHealth_bmsk;
    --                              5    &   3     &       8    ; 

    header(63 downto 32)    <= std_logic_vector(eventCounter_i);
    header(31 downto 0)     <= precCnt & globBcid & b"00000" & vmmId_i;  
                            --    8    &    16    &     5    &   3
    dbg_st_o                <= debug_state;
    packLen_drv2pf_unsg     <= unsigned(packLen_drv2pf);

--ilaPacketFormation: ila_pf
--port map(
--    clk                     =>  clk,
--    probe0                  =>  probe0_out,
--    probe1                  =>  probe1_out
--);

    probe0_out(9 downto 0)             <= std_logic_vector(to_unsigned(trigLatencyCnt, 10));
    probe0_out(19 downto 10)           <= std_logic_vector(to_unsigned(trigLatency, 10));
    probe0_out(20)                     <= '0';
    probe0_out(21)                     <= artValid;
    probe0_out(22)                     <= trraw_synced125;
    probe0_out(23)                     <= vmmArtReady;
    probe0_out(29 downto 24)           <= vmmArtData125;
    probe0_out(132 downto 30)          <= (others => '0');--vmmId_i;

    probe1_out(63 downto 0)             <= (others => '0');--daqFIFO_din;
    probe1_out(64)                      <= vmmWordReady;
    probe1_out(65)                      <= vmmEventDone;
    probe1_out(66)                      <= '0';
    probe1_out(67)                      <= newCycle;
    probe1_out(79 downto 68)            <= std_logic_vector(packLen_i);
    probe1_out(91 downto 80)            <= std_logic_vector(packLen_cnt);
    probe1_out(92)                      <= end_packet_int;
    probe1_out(93)                      <= triggerVmmReadout_i;
    probe1_out(109 downto 94)           <= latency;
    probe1_out(110)                     <= '0';
    probe1_out(142 downto 111)          <= std_logic_vector(eventCounter_i);
    probe1_out(147 downto 143)          <= debug_state;
    
    probe1_out(200 downto 148)          <= (others => '0');

end Behavioral;