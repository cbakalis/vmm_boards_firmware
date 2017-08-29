-----------------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 10/27/2016 03:35:29 PM
-- Design Name: ELINK_TX_RX_WRAPPER
-- Module Name: elink_wrapper- RTL
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484
-- Tool Versions: Vivado 2016.2
-- Description: E-LINK WRAPPER: This component receives and sends data via e-link,
-- if provided with a 40 Mhz clock from the e-link clk bus. It is integrated with
-- the packet formation of the MMFE8 readout firmware, to accept DAQ data and send 
-- them via e-link.
-- 
-- Dependencies: MMFE8 NTUA Radout Firmware 
--               FELIX E-LINK TX/RX modules
-- 
-- Changelog: 
-- 17.11.2016 Added the DAQ to elink connection functionality which allows DAQ data
-- to be sent over the e-link transmission line. (Christos Bakalis) 
-- 23.11.2016 Added an extra MMCM status monitoring port. (Christos Bakalis)
-- 29.11.2016 Added the Elink2FIFO rx-module which receives data from the e-link
-- transmission line. Minor changes to other tx-related user logic components.
-- Removed BUFGs from MMCM and placed phsically the whole wrapper near the MMCM via
-- Vivado's floorplanning. (Christos Bakalis)
-- 03.12.2016 Added a loopback functionality, and an enable DAQ input. Removed the
-- internal ILAs and merged them into one at the top of the wrapper. The clocking 
-- of the auxilliary logic is now provided by the e-link MMCM. Added BUFGs to the
-- MMCM clocks and removed floorplanning. (Christos Bakalis)
-- 13.12.2016 Added an option to swap the incoming or outcoming bits of the RX or
-- TX side respectively. (Christos Bakalis)
-- 05.07.2017 Updated the module. E-link MMCM is now external and link speed can 
-- go up to 320 Mbps. Also added a TTC auxiliary module. (Christos Bakalis)
-- 24.08.2017 Updated the module to comply with the ROC e-link format. (Christos Bakalis)
--
-----------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity elink_wrapper is
generic(DataRate        : integer;  -- 80 / 160 / 320 MHz
        elinkEncoding   : std_logic_vector (1 downto 0)); -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding
port(
    ---------------------------------
    ----- General/VIO Interface -----
    user_clock      : in  std_logic;  -- user logic clocking
    pattern_ena     : in  std_logic;  -- if high, test packets are sent.
    daq_ena         : in  std_logic;  -- if high, DAQ data are sent.
    loopback_ena    : in  std_logic;  -- if high, internal loopback mode is enabled
    glbl_rst        : in  std_logic;  -- reset the entire component
    rst_tx          : in  std_logic;  -- reset the e-link tx sub-component
    rst_rx          : in  std_logic;  -- reset the e-link rx sub-component
    swap_tx         : in  std_logic;  -- swap the tx-side bits
    swap_rx         : in  std_logic;  -- swap the rx-side bits
    ttc_detected    : out std_logic;  -- TTC signal detected
    ---------------------------------
    -------- E-link clocking --------
    clk_40          : in  std_logic;
    clk_80          : in  std_logic;
    clk_160         : in  std_logic;
    clk_320         : in  std_logic;
    elink_locked    : in  std_logic;
    ---------------------------------
    ---- E-link Serial Interface ----
    elink_tx        : out std_logic;                    -- elink tx bus
    elink_rx        : in  std_logic;                    -- elink rx bus
    ---------------------------------
    ------ Readout Interface --------
    ro_rdy          : in  std_logic;                    -- every VMM has been read out
    bitmask_null    : in  std_logic_vector(7 downto 0); -- which VMMs have data?
    health_bitmask  : in  std_logic_vector(7 downto 0); -- which VMMs have a healthy link?
    ---------------------------------
    --------- PF Interface ----------
    din_daq         : in  std_logic_vector(15 downto 0); -- data packets from packet formation
    inhibit_pf      : out std_logic;                     -- pf inhibitor
    trigger_cnt     : in  std_logic_vector(15 downto 0); -- trigger counter (in ROC header)
    vmm_id          : in  std_logic_vector(2 downto 0);  -- vmm that is being read
    pf_busy         : in  std_logic;                     -- pf is in the middle of readout
    pf_rdy          : in  std_logic;                     -- pf is ready to write DAQ data
    wr_en_daq       : in  std_logic                      -- write enable from packet formation
    );
end elink_wrapper;

architecture RTL of elink_wrapper is

component elink_daq_tester
  Port(
    -----------------------------
    ---- general interface ------
    clk_in          : in  std_logic; 
    rst             : in  std_logic;
    tester_ena      : in  std_logic;
    ------------------------------
    ------ elink interface -------
    empty_elink     : in  std_logic;
    wr_en           : out std_logic;
    dout            : out std_logic_vector(17 downto 0)
    );
end component;

component elink_daq_driver
    Port(
    ---------------------------
    ---- general interface ---- 
    clk_in      : in  std_logic;
    fifo_flush  : in  std_logic;
    driver_ena  : in  std_logic;
    ---------------------------
    ------- pf interface ------
    din_daq     : in  std_logic_vector(15 downto 0);
    wr_en_daq   : in  std_logic;
    trigger_cnt : in  std_logic_vector(15 downto 0);
    vmm_id      : in  std_logic_vector(2 downto 0);
    pf_busy     : in  std_logic;
    pf_rdy      : in  std_logic;
    inhibit_pf  : out std_logic;
    ---------------------------
    ----- readout interface ---
    all_rdy     : in  std_logic;
    bitmask_null: in  std_logic_vector(7 downto 0);
    health_bmsk : in  std_logic_vector(7 downto 0);
    ---------------------------
    ------ elink inteface -----
    empty_elink : in  std_logic;
    wr_en_elink : out std_logic;
    flush_elink : out std_logic;
    dout_elink  : out std_logic_vector(17 downto 0)
    );
end component;

component FIFO2Elink
generic (
    OutputDataRate  : integer := 80; -- 80 / 160 / 320 MHz
    elinkEncoding   : std_logic_vector (1 downto 0) -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
    );
port ( 
    clk40       : in  std_logic;
    clk80       : in  std_logic;
    clk160      : in  std_logic;
    clk320      : in  std_logic;
    rst         : in  std_logic;
    fifo_flush  : in  std_logic;
    swap_output : in  std_logic;
    ------   
    efifoDin    : in  std_logic_vector (17 downto 0);   -- [data_code,2bit][data,16bit]
    efifoWe     : in  std_logic;
    efifoPfull  : out std_logic;
    efifoEmpty  : out std_logic;
    efifoWclk   : in  std_logic; 
    ------
    DATA1bitOUT : out std_logic; -- serialized output
    elink2bit   : out std_logic_vector (1 downto 0); -- 2 bits @ clk40, can interface 2-bit of GBT frame
    elink4bit   : out std_logic_vector (3 downto 0); -- 4 bits @ clk40, can interface 4-bit of GBT frame
    elink8bit   : out std_logic_vector (7 downto 0)  -- 8 bits @ clk40, can interface 8-bit of GBT frame
    ------
    );
end component;

component Elink2FIFO
generic (
    InputDataRate       : integer := 80; -- 80 / 160 / 320 / 640 MHz
    elinkEncoding       : std_logic_vector (1 downto 0); -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
    serialized_input    : boolean := true
    );
port ( 
    clk40       : in  std_logic;
    clk80       : in  std_logic;
    clk160      : in  std_logic;    
    clk320      : in  std_logic;
    rst         : in  std_logic;
    fifo_flush  : in  std_logic;
    swap_input  : in  std_logic; -- new
    ------
    DATA1bitIN  : in std_logic := '0';
    elink2bit   : in std_logic_vector (1 downto 0) := (others=>'0'); -- 2 bits @ clk40, can interface 2-bit of GBT frame
    elink4bit   : in std_logic_vector (3 downto 0) := (others=>'0'); -- 4 bits @ clk40, can interface 4-bit of GBT frame
    elink8bit   : in std_logic_vector (7 downto 0) := (others=>'0'); -- 8 bits @ clk40, can interface 8-bit of GBT frame
    -- 640 Mbps e-link can't come in as a serial input yet (additional clock is needed)
    elink16bit  : in std_logic_vector (15 downto 0) := (others=>'0'); -- 16 bits @ clk40, can interface 16-bit of GBT frame
    ------
    efifoRclk   : in  std_logic;
    efifoRe     : in  std_logic; 
    efifoHF     : out std_logic; -- half-full flag: 1 KByte block is ready to be read
    efifoEmpty  : out std_logic; -- new
    efifoDout   : out std_logic_vector (15 downto 0)
    ------
    );
end component;
    
    signal rst_i_tx             : std_logic := '1';
    signal rst_i_tx_s0          : std_logic := '1';
    signal rst_i_tx_s1          : std_logic := '1'; -- sync to 80 Mhz
    signal rst_i_rx_s0          : std_logic := '1';
    signal rst_i_rx_s1          : std_logic := '1'; -- sync to 80 Mhz
    signal rst_i_rx             : std_logic := '1';
    signal flush_rx             : std_logic := '1';
    signal flush_tx             : std_logic := '1';
    signal flush_tx_final       : std_logic := '1';
    signal rst_pf_i             : std_logic := '1';
    signal flush_elink_i        : std_logic := '1';
    signal cnt_init_rx          : integer   := 0;
    signal cnt_init_tx          : integer   := 0;

    signal data_elink_tx        : std_logic_vector(17 downto 0) := (others => '0');
    signal wr_en_elink_tx       : std_logic := '0';
    signal data_elink_tester    : std_logic_vector(17 downto 0) := (others => '0');
    signal wr_en_elink_tester   : std_logic := '0';
    signal data_elink_daq       : std_logic_vector(17 downto 0) := (others => '0');
    signal wr_en_elink_daq      : std_logic := '0';
    signal sel_din              : std_logic_vector(1 downto 0) := (others => '0'); 
    signal elink_tx_i           : std_logic := '0';
    signal elink_rx_i           : std_logic := '0';
    
    signal full_elink_tx        : std_logic := '0';
    signal empty_elink_tx       : std_logic := '0';
    signal empty_elink_rx       : std_logic := '0';
    signal dout_elink2fifo      : std_logic_vector(15 downto 0) := (others => '0');
    signal dout_elink2fifo_inv  : std_logic_vector(15 downto 0) := (others => '0'); -- byte-reversed
    signal half_full_rx         : std_logic := '0';
    signal driver_ena           : std_logic := '0';
    signal rd_ena               : std_logic := '0';
    signal tester_ena           : std_logic := '0'; 
    
    attribute mark_debug        : string;
    attribute dont_touch        : string;
    attribute ASYNC_REG         : string;

    attribute ASYNC_REG of rst_i_tx_s0    : signal is "true";
    attribute ASYNC_REG of rst_i_tx_s1    : signal is "true";
    attribute ASYNC_REG of rst_i_rx_s0    : signal is "true";
    attribute ASYNC_REG of rst_i_rx_s1    : signal is "true";
    
    -- debugging
    attribute mark_debug of dout_elink2fifo_inv     : signal is "true";
    attribute dont_touch of dout_elink2fifo_inv     : signal is "true";
    attribute mark_debug of rd_ena                  : signal is "true";
    
--    attribute mark_debug of empty_elink_tx      : signal is "true";
--    attribute mark_debug of empty_elink_rx      : signal is "true";
    
--    attribute mark_debug of elink_tx_i          : signal is "true";
--    attribute mark_debug of elink_rx_i          : signal is "true";
    
--    attribute mark_debug of data_elink_tx       : signal is "true";
--    attribute mark_debug of wr_en_elink_tx      : signal is "true";
    

begin

testing_instance: elink_daq_tester
port map(
    -----------------------------
    ---- general interface ------
    clk_in          => user_clock, -- must be the same with efifoWclk of FIFO2ELINK
    rst             => rst_i_tx,
    tester_ena      => tester_ena,
    ------------------------------
    ------ elink interface -------
    empty_elink     => empty_elink_tx,
    wr_en           => wr_en_elink_tester,
    dout            => data_elink_tester
    );
    
DAQ2ELINK_instance: elink_daq_driver
port map(
    ---------------------------
    ---- general interface ---- 
    clk_in      => user_clock,
    fifo_flush  => flush_tx,
    driver_ena  => driver_ena,
    ---------------------------
    ------- pf interface ------
    din_daq     => din_daq,
    wr_en_daq   => wr_en_daq,
    trigger_cnt => trigger_cnt,
    vmm_id      => vmm_id,
    pf_busy     => pf_busy,
    pf_rdy      => pf_rdy,
    inhibit_pf  => inhibit_pf,
    ---------------------------
    ----- readout interface ---
    all_rdy     => ro_rdy,
    bitmask_null=> bitmask_null,
    health_bmsk => health_bitmask,
    ---------------------------
    ------ elink inteface -----
    empty_elink => empty_elink_tx,
    wr_en_elink => wr_en_elink_daq,
    flush_elink => flush_elink_i,
    dout_elink  => data_elink_daq
    );
    
elink_tx_instance: FIFO2Elink
generic map(OutputDataRate => DataRate, -- 80 / 160 / 320 MHz
            elinkEncoding  => elinkEncoding) -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
port map(  
    clk40           => clk_40,
    clk80           => clk_80,
    clk160          => clk_160,
    clk320          => clk_320,
    rst             => rst_i_tx_s1,
    fifo_flush      => flush_tx_final,
    swap_output     => swap_tx,
    ------   
    efifoDin        => data_elink_tx,
    efifoWe         => wr_en_elink_tx,
    efifoPfull      => full_elink_tx,
    efifoEmpty      => empty_elink_tx,
    efifoWclk       => user_clock, -- must be the same with clk_in of tester and driver
    ------
    DATA1bitOUT     => elink_tx_i,
    elink2bit       => open,
    elink4bit       => open,
    elink8bit       => open
    );

elink_rx_instance: Elink2FIFO
generic map( InputDataRate  => DataRate, -- 80 / 160 / 320 MHz
             elinkEncoding  => elinkEncoding) -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding
port map( 
    clk40       => clk_40,
    clk80       => clk_80,
    clk160      => clk_160,
    clk320      => clk_320,
    rst         => rst_i_rx_s1,
    fifo_flush  => flush_rx,
    swap_input  => swap_rx,
    ------
    DATA1bitIN  => elink_rx_i,
    elink2bit   => (others => '0'),
    elink4bit   => (others => '0'),
    elink8bit   => (others => '0'),
    elink16bit  => (others => '0'),
    ------
    efifoRclk   => clk_160,
    efifoRe     => rd_ena, 
    efifoHF     => half_full_rx,
    efifoEmpty  => empty_elink_rx,
    efifoDout   => dout_elink2fifo
    ------
    );

-- use TTC signal recognition module
UseTTC: if elinkEncoding = "00" generate
-- ttc_detected <= '1';
-- TBD
end generate UseTTC; 

-- MUX that chooses between data from the pattern generator, or the DAQ data from the VMMs
elinkDinMux: process(sel_din, pattern_ena, daq_ena, data_elink_daq, wr_en_elink_daq, data_elink_tester, wr_en_elink_tester)
begin
    case sel_din is
    when "00" =>
        data_elink_tx  <= (others => '0');
        wr_en_elink_tx <= '0';
    when "01"    =>
        data_elink_tx  <= data_elink_daq;
        wr_en_elink_tx <= wr_en_elink_daq;
    when "10"    =>
        data_elink_tx  <= data_elink_tester;
        wr_en_elink_tx <= wr_en_elink_tester;
    when "11" =>
        data_elink_tx  <= (others => '0');
        wr_en_elink_tx <= '0';
    when others =>
        data_elink_tx  <= (others => '0');
        wr_en_elink_tx <= '0';
    end case;
end process;

-- MUX that chooses the loopback state
loopMux: process(loopback_ena, elink_rx, elink_tx_i)
begin
    case loopback_ena is
    when '0' =>
        elink_tx    <= elink_tx_i;
        elink_rx_i  <= elink_rx;
    when '1' =>
        elink_tx    <= '0';
        elink_rx_i  <= elink_tx_i;
    when others =>
        elink_tx    <= '0';
        elink_rx_i  <= '0';
    end case;
end process;

-- reads data from the Elink2FIFO module when it is not empty
readFIFOproc: process(clk_160)
begin
    if(rising_edge(clk_160))then
        if(elink_locked = '1' and empty_elink_rx = '0')then
            rd_ena <= '1';
        else
            rd_ena <= '0';
        end if;
    end if;
end process;

-- creates an internal reset pulse for FIFO2Elink initialization/reset
initRstProc_tx: process(user_clock)
begin
    if(rising_edge(user_clock))then
        if(glbl_rst = '1' or rst_tx = '1')then
            cnt_init_tx <= 0;
            rst_i_tx    <= '1';
            flush_tx    <= '1';
        else
            if(elink_locked = '1')then
                case cnt_init_tx is
                when 0 to 39  =>
                    cnt_init_tx <= cnt_init_tx + 1;
                    rst_i_tx    <= '1';
                    flush_tx    <= '1';
                when 40 to 59 =>    -- first release the flush signal
                    cnt_init_tx <= cnt_init_tx + 1; 
                    rst_i_tx    <= '1';
                    flush_tx    <= '0';
                when 60 =>          -- remain in this state until reset by top
                    cnt_init_tx <= 60;
                    rst_i_tx    <= '0';
                    flush_tx    <= '0';
                when others =>
                    cnt_init_tx <= 0;
                    rst_i_tx    <= '1';
                    flush_tx    <= '1';
                end case;
            else
                cnt_init_tx <= 0;
                rst_i_tx    <= '1';
                flush_tx    <= '1';
            end if;
        end if; 
    end if;
end process;

-- creates an internal reset pulse for Elink2FIFO initialization/reset
initRstProc_rx: process(user_clock)
begin
    if(rising_edge(user_clock))then
        if(glbl_rst = '1' or rst_rx = '1')then
            cnt_init_rx <= 0;
            rst_i_rx    <= '1';
            flush_rx    <= '1';
        else
            if(elink_locked = '1')then
                case cnt_init_rx is
                when 0 to 39  =>
                    cnt_init_rx <= cnt_init_rx + 1;
                    rst_i_rx    <= '1';
                    flush_rx    <= '1';
                when 40 to 59 =>    -- first release the flush signal
                    cnt_init_rx <= cnt_init_rx + 1;
                    rst_i_rx    <= '1';
                    flush_rx    <= '0';
                when 60 =>          -- remain in this state until reset by top
                    cnt_init_rx <= 60;
                    rst_i_rx    <= '0';
                    flush_rx    <= '0';
                when others =>
                    cnt_init_rx <= 0;
                    rst_i_rx    <= '1';
                    flush_rx    <= '1';
                end case;
            else
                cnt_init_rx <= 0;
                rst_i_rx    <= '1';
                flush_rx    <= '1';
            end if;
        end if; 
    end if;
end process;

-- reset synchronizer (enabled reset syncing at FIFOs so no worries there)
syncModuleSigs_proc: process(clk_80)
begin
    if(rising_edge(clk_80))then
        rst_i_tx_s0     <= rst_i_tx;
        rst_i_tx_s1     <= rst_i_tx_s0;
        rst_i_rx_s0     <= rst_i_rx;
        rst_i_rx_s1     <= rst_i_rx_s0;
    end if;
end process;
 
  tester_ena        <= elink_locked and pattern_ena;
  driver_ena        <= elink_locked and daq_ena;
  flush_tx_final    <= flush_tx or flush_elink_i;
  dout_elink2fifo_inv(15) <= dout_elink2fifo(7);
  dout_elink2fifo_inv(14) <= dout_elink2fifo(6);
  dout_elink2fifo_inv(13) <= dout_elink2fifo(5);
  dout_elink2fifo_inv(12) <= dout_elink2fifo(4);
  dout_elink2fifo_inv(11) <= dout_elink2fifo(3);
  dout_elink2fifo_inv(10) <= dout_elink2fifo(2);
  dout_elink2fifo_inv(9) <= dout_elink2fifo(1);
  dout_elink2fifo_inv(8) <= dout_elink2fifo(0);
  dout_elink2fifo_inv(7) <= dout_elink2fifo(15);
  dout_elink2fifo_inv(6) <= dout_elink2fifo(14);
  dout_elink2fifo_inv(5) <= dout_elink2fifo(13);
  dout_elink2fifo_inv(4) <= dout_elink2fifo(12);
  dout_elink2fifo_inv(3) <= dout_elink2fifo(11);
  dout_elink2fifo_inv(2) <= dout_elink2fifo(10);
  dout_elink2fifo_inv(1) <= dout_elink2fifo(9);
  dout_elink2fifo_inv(0) <= dout_elink2fifo(8);
  
  sel_din(1)        <= pattern_ena;
  sel_din(0)        <= daq_ena;
    
end RTL;