----------------------------------------------------------------------------------
-- Company: NTU ATHENS - BNL
-- Engineer: Paris Moschovakos
-- 
-- Create Date: 25.06.2016
-- Design Name: 
-- Module Name: packet_formation.vhd - Behavioral
-- Project Name: MMFE8 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
--
-- Changelog:
-- 22.08.2016 Changed readout trigger pulse from 125 to 100 ns long (Reid Pinkham)
-- 09.09.2016 Added two signals for ETR interconnection (Christos Bakalis)
-- 26.02.2016 Moved to a global clock domain @125MHz (Paris)
--
----------------------------------------------------------------------------------

library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity packet_formation is
    Port(
        clk         : in std_logic;

        newCycle    : in std_logic;
        
        trigVmmRo   : out std_logic;
        vmmId       : out std_logic_vector(2 downto 0);
        vmmWord     : in std_logic_vector(63 downto 0);
        vmmWordReady: in std_logic;
        vmmEventDone: in std_logic;

        UDPDone     : in std_logic;
        pfBusy      : out std_logic;				        -- Control signal to ETR
        glBCID      : in std_logic_vector(11 downto 0);		-- glBCID counter from ETR

        packLen     : out std_logic_vector(11 downto 0);
        dataout     : out std_logic_vector(63 downto 0);
        wrenable    : out std_logic;
        end_packet  : out std_logic;
        
        flush_elink : out std_logic;
        elink_busy  : in  std_logic;
        elink_daq   : in  std_logic;
        
        tr_hold     : out std_logic;
        reset       : in std_logic;
        rst_vmm     : out std_logic;
        resetting   : in std_logic;
        rst_FIFO    : out std_logic;
        dbg_state_o : out std_logic_vector(4 downto 0);
        
        latency     : in std_logic_vector(15 downto 0)

        --trigger     : in std_logic -- is not used
    );
end packet_formation;

architecture Behavioral of packet_formation is

    signal header           : std_logic_vector(63 downto 0) := ( others => '0' );
    signal vmmId_i          : std_logic_vector(2 downto 0)  := b"000";
    signal globBcid         : std_logic_vector(15 downto 0) := x"FFFF"; --( others => '0' );
    signal precCnt          : std_logic_vector(7 downto 0)  := x"00"; --( others => '0' );
    signal globBcid_i       : std_logic_vector(15 downto 0);
    signal globBCID_etr		: std_logic_vector(11 downto 0) := (others => '0'); --globBCID counter as it is coming from ETR
    signal eventCounter_i   : unsigned(31 downto 0) := to_unsigned(0, 32);
    signal wait_Cnt         : integer := 0;
    signal vmmId_cnt        : integer := 0;
    signal trigLatencyCnt   : integer := 0;
    signal trigLatency      : integer := 140; -- 700ns (140x5ns)
    signal pfBusy_i         : std_logic	:= '0';               -- control signal to be sent to ETR

    signal daqFIFO_wr_en        : std_logic                     := '0';
    signal daqFIFO_wr_en_i      : std_logic                     := '0';
    signal daqFIFO_din          : std_logic_vector(63 downto 0) := ( others => '0' );
    signal triggerVmmReadout_i  : std_logic := '0';
    signal selectDataInput      : std_logic := '0';

    signal vmmWord_i        : std_logic_vector(63 downto 0) := ( others => '0' );
    signal packLen_i        : std_logic_vector(11 downto 0) := x"000";
    signal packLen_cnt      : unsigned(11 downto 0) := x"000";
    signal end_packet_int   : std_logic                     := '0';
    
    signal resetting_i      : std_logic := '0';
    signal resetting_s      : std_logic := '0';
    
    attribute ASYNC_REG                 : string;
    attribute ASYNC_REG of resetting_i  : signal is "TRUE";
    attribute ASYNC_REG of resetting_s  : signal is "TRUE";

    type stateType is (waitingForNewCycle, increaseCounter, waitForLatency, S2, flushElinks, captureEventID, setEventID, sendHeaderStep1, sendHeaderStep2, 
                       triggerVmmReadout, waitForData, resetVMMs, resetDone, sendVmmDataStep1, sendVmmDataStep2, formTrailer, sendTrailer, packetDone, isUDPDone,
                       isTriggerOff, eventDone);
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

-----------------------------------------------------------------

begin

packetCaptureProc: process(clk, newCycle, vmmEventDone, vmmWordReady, wait_Cnt, UDPDone)
begin

    if rising_edge(clk) then
        if reset = '1' then
            debug_state             <= "11111";
            eventCounter_i          <= to_unsigned(0, 32);
            pfBusy_i		        <= '0';
            triggerVmmReadout_i     <= '0';
            rst_FIFO                <= '1';
            daqFIFO_wr_en           <= '0';
            packLen_cnt             <= x"000";
            wait_Cnt                <= 0;
            flush_elink             <= '0';
            triggerVmmReadout_i     <= '0';
            end_packet_int          <= '0';
            selectDataInput         <= '0';
            state                   <= waitingForNewCycle;
        else
        case state is
            when waitingForNewCycle =>
                debug_state             <= "00000";
                pfBusy_i                <= '0';
                triggerVmmReadout_i     <= '0';
                trigLatencyCnt          <= 0;
                rst_FIFO                <= '0';
                if newCycle = '1' then
                    pfBusy_i        <= '1';
                	daqFIFO_wr_en   <= '0';
                	state           <= increaseCounter;
                else
                    tr_hold         <= '0';
                end if;
                
            when increaseCounter =>
                debug_state <= "00001";
                eventCounter_i  <= eventCounter_i + 1;
                state           <= waitForLatency;
                
            when waitForLatency =>
                debug_state <= "00010";
                tr_hold         <= '1';                 -- Prevent new triggers
                if trigLatencyCnt > trigLatency then 
                    state           <= S2;
                else
                    trigLatencyCnt  <= trigLatencyCnt + 1;
                end if;

            when S2 =>          -- wait for the header elements to be formed
                debug_state <= "00010";
                tr_hold         <= '1';                 -- Prevent new triggers
                selectDataInput <= '0';
                packLen_cnt     <= x"000";              -- Reset length count
                vmmId_i         <= std_logic_vector(to_unsigned(vmmId_cnt, 3));
                if(elink_daq = '1' and elink_busy = '0')then -- elink DAQ is on, flush the elink tx FIFOs
                    flush_elink     <= '1';
                    state           <= flushElinks;
                elsif(elink_daq = '1' and elink_busy = '1')then -- stay here until elink has sent all data
                    flush_elink     <= '0';
                    state           <= S2;
                else
                    flush_elink     <= '0';
                     state          <= captureEventID;
                end if;
            
            -- wait until Elink FIFOs are flushed    
            when flushElinks =>
                flush_elink     <= '0';
                    if wait_Cnt < 70 then
                        wait_Cnt    <= wait_Cnt + 1;
                        state       <= flushElinks;
                    else
                        wait_Cnt    <= 0;
                        state       <= captureEventID;
                    end if;
                    
            when captureEventID =>      -- Form Header
                debug_state             <= "00011";
                packLen_cnt             <= x"000";
                state                   <= setEventID;
                
            when setEventID =>
                debug_state             <= "00100";
                rst_FIFO                <= '0';
                daqFIFO_wr_en           <= '0';
                state                   <= sendHeaderStep1;

            when sendHeaderStep1 =>
                debug_state     <= "00101";
                daqFIFO_wr_en   <= '1';
                packLen_cnt     <= packLen_cnt + 1;
                state           <= sendHeaderStep2;

            when sendHeaderStep2 =>
                debug_state     <= "00110";
                daqFIFO_wr_en   <= '0';
                state           <= triggerVmmReadout;

            when triggerVmmReadout =>   -- Creates an 136ns pulse to trigger the readout
                debug_state                 <= "00111";
                selectDataInput <= '1';
                if wait_Cnt < 30 then
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
                    daqFIFO_wr_en   <= '0';
                    state           <= sendVmmDataStep1;
                elsif (vmmEventDone = '1') then
                    daqFIFO_wr_en   <= '0';
                    state           <= sendTrailer; 
                end if;

            when sendVmmDataStep1 =>
                debug_state     <= "01001";
                daqFIFO_wr_en   <= '1';
                packLen_cnt     <= packLen_cnt + 1;
                state           <= sendVmmDataStep2;

            when sendVmmDataStep2 =>
                debug_state     <= "01010";
                daqFIFO_wr_en   <= '0';
                state           <= formTrailer;

            when formTrailer =>
                debug_state         <= "01011";
                if (vmmEventDone = '1') then
                    daqFIFO_wr_en   <= '0';
                    state           <= sendTrailer;
                elsif (vmmEventDone = '0' and vmmWordReady = '0') then  
                    state           <= waitForData;
                else -- (vmmWordReady = '1') then
                    state           <= formTrailer;
                end if;

            when sendTrailer =>
                debug_state     <= "01100";
                packLen_i       <= std_logic_vector(packLen_cnt);
                state           <= packetDone;

            when packetDone =>
                debug_state     <= "01101";
                end_packet_int  <= '1';
                state           <= eventDone;

            when eventDone =>
                debug_state     <= "01110";
                end_packet_int  <= '0';
                if vmmId_cnt >= 7 then
                    vmmId_cnt   <= 0;
                    state       <= resetVMMs;
                else
                    vmmId_cnt   <= vmmId_cnt + 1;
                    state       <= S2;
                end if;
                
            when resetVMMs =>
                debug_state <= "01111";
                rst_vmm     <= '1';
                state       <= resetDone;
                
            when resetDone =>
                debug_state <= "10000";
                if resetting_s = '0' then
                    state       <= isUDPDone;
                    rst_vmm     <= '0'; -- Prevent from continuously resetting while waiting for UDP Packet
                end if;

            when isUDPDone =>
                debug_state 	<= "01110";
                pfBusy_i        <= '0';
                if (UDPDone = '1') then -- Wait for the UDP packet to be sent
                    state       <= isTriggerOff;
                end if;
                
            when isTriggerOff =>            -- Wait for whatever ongoing trigger pulse to go to 0
                debug_state <= "01111";
                tr_hold         <= '0';     -- Allow new triggers
                if newCycle /= '1' then
                    tr_hold         <= '0';
                    state           <= waitingForNewCycle;
                end if;

            when others =>
                tr_hold         <= '0';
                state           <= waitingForNewCycle;
        end case;
    end if;
end if;
end process;

muxFIFOData: process(selectDataInput, header, vmmWord_i)
begin
case selectDataInput is
    when '0' =>
        daqFIFO_din     <= header;
    when '1' =>
        daqFIFO_din     <= vmmWord_i;
    when others =>
        daqFIFO_din     <= header;
    end case;
end process;

syncETRsig: process(clk)
begin
    if(rising_edge(clk))then
        resetting_i <= resetting;
        resetting_s <= resetting_i;
    end if;
end process;

    globBcid_i      <= globBcid;
    daqFIFO_wr_en_i <= daqFIFO_wr_en;
    vmmWord_i       <= vmmWord;
    dataout         <= daqFIFO_din;
    wrenable        <= daqFIFO_wr_en_i;
    packLen         <= packLen_i;
    end_packet      <= end_packet_int;
    trigVmmRo       <= triggerVmmReadout_i;
    vmmId           <= vmmId_i;
    trigLatency     <= 140;
    pfBusy		    <= pfBusy_i;
    globBCID_etr	<= glBCID;
    header(63 downto 32)    <= std_logic_vector(eventCounter_i);
    header(31 downto 0)     <= precCnt & globBcid & b"00000" & vmmId_i;  
                            --    8    &    16    &     5    &   3
    dbg_state_o     <= debug_state;

--ilaPacketFormation: ila_pf
--port map(
--    clk                     =>  clk,
--    probe0                  =>  probe0_out,
--    probe1                  =>  probe1_out
--);

    probe0_out(9 downto 0)             <= std_logic_vector(to_unsigned(trigLatencyCnt, 10));--header;             -- OK
    probe0_out(19 downto 10)           <= std_logic_vector(to_unsigned(trigLatency, 10));          -- OK
    probe0_out(20)                     <= '0';
    probe0_out(21)                     <= '0';
    probe0_out(132 downto 22)          <= (others => '0');--vmmId_i;

    probe1_out(63 downto 0)             <= (others => '0');--daqFIFO_din;        -- OK
    probe1_out(64)                      <= vmmWordReady;       -- OK
    probe1_out(65)                      <= vmmEventDone;       -- OK
    probe1_out(66)                      <= daqFIFO_wr_en_i;    -- OK
    probe1_out(67)                      <= newCycle;           -- OK
    probe1_out(79 downto 68)            <= packLen_i;
    probe1_out(91 downto 80)            <= std_logic_vector(packLen_cnt);
    probe1_out(92)                      <= end_packet_int;        -- Not tested
    probe1_out(93)                      <= triggerVmmReadout_i;    --Not tested
    probe1_out(109 downto 94)           <= latency;
    probe1_out(110)                     <= '0';
    probe1_out(142 downto 111)          <= std_logic_vector(eventCounter_i);
    probe1_out(147 downto 143)          <= debug_state;
    
    probe1_out(200 downto 148)          <= (others => '0');

end Behavioral;