-------------------------------------------------------------------------------------
-- Company: NTU ATHENS - BNL
-- Engineer: Paris Moschovakos, Panagiotis Gkountoumis & Christos Bakalis
-- 
-- Create Date: 16.3.2016
-- Design Name: MMFE8
-- Module Name: mmfe8_top
-- Project Name: MMFE8 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
--
-- Changelog:
-- 04.08.2016 Added the XADC Component and multiplexer to share fifo UDP Signals
-- (Reid Pinkham)
-- 10.08.2016 Changed the FIFO2UDP rstFIFO input signals (swapped rstDAQFIFO <--> daqFIFO_reset)
-- at the OR gate. (Christos Bakalis)
-- 11.08.2016 Corrected the fifo resets to go through select_data (Reid Pinkham)
-- 16.09.2016 Added Dynamic IP configuration. (Lev Kurilenko)
-- 16.02.2017 Added new configuration component (udp_data_in_handler). Changes
-- at flow_fsm and axi4-spi flash module. (Christos Bakalis)
-- 27.02.2017 Added CDCC to top level. Added sel_cs mux to avoid clock domain
-- crossing. (Christos Bakalis)
-- 27.02.2017 Changed main logic clock to 125MHz (Paris)
-- 10.03.2017 Added configurable CKTP/CKBC module. For the moment controlled by
-- a VIO. Added new internal_trigger process (Christos Bakalis)
-- 12.03.2017 Changed flow_fsm's primary cktp assertion to comply with cktp_gen
-- module. (Christos Bakalis)
-- 14.03.2017 Added register address/value configuration scheme. (Christos Bakalis)
-- 28.03.2017 Changes to accomodate to MMFE8 VMM3. (Christos Bakalis)
-- 19.04.2017 VMM2 version migrated from VMM3 design. (Christos Bakalis)
-- 05.07.2017 Added E-link RX/TX for DAQ and TTC.   (Christos Bakalis)
--
----------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity mmfe8_top is
    port(
        -- Trigger pins
        EXT_TRIGGER_P       : in std_logic;
        EXT_TRIGGER_N       : in std_logic;
--        EXT_TRIG_IN         : in std_logic;

--        TRIGGER_LOOP_P      : out std_logic;
--        TRIGGER_LOOP_N      : out std_logic;

        -- 200.0359MHz from bank 14
        -------------------------------------
        X_2V5_DIFF_CLK_P      : IN STD_LOGIC;
        X_2V5_DIFF_CLK_N      : IN STD_LOGIC;

        -- Transceiver Interface
        -------------------------------------
        gtrefclk_p            : IN  STD_LOGIC;                     -- Differential +ve of reference clock for tranceiver: 125MHz, very high quality
        gtrefclk_n            : IN  STD_LOGIC;                     -- Differential -ve of reference clock for tranceiver: 125MHz, very high quality
        txp                   : OUT STD_LOGIC;                     -- Differential +ve of serial transmission from PMA to PMD.
        txn                   : OUT STD_LOGIC;                     -- Differential -ve of serial transmission from PMA to PMD.
        rxp                   : IN  STD_LOGIC;                     -- Differential +ve for serial reception from PMD to PMA.
        rxn                   : IN  STD_LOGIC;                     -- Differential -ve for serial reception from PMD to PMA.
        phy_int               : OUT STD_LOGIC;
        phy_rstn_out          : OUT STD_LOGIC;

        -- VMM3 Signals
        -------------------------------------
        DATA0_1_P, DATA0_1_N  : IN STD_LOGIC;
        DATA0_2_P, DATA0_2_N  : IN STD_LOGIC;
        DATA0_3_P, DATA0_3_N  : IN STD_LOGIC;
        DATA0_4_P, DATA0_4_N  : IN STD_LOGIC;
        DATA0_5_P, DATA0_5_N  : IN STD_LOGIC;
        DATA0_6_P, DATA0_6_N  : IN STD_LOGIC;
        DATA0_7_P, DATA0_7_N  : IN STD_LOGIC;
        DATA0_8_P, DATA0_8_N  : IN STD_LOGIC;

        DATA1_1_P, DATA1_1_N  : IN STD_LOGIC;
        DATA1_2_P, DATA1_2_N  : IN STD_LOGIC;
        DATA1_3_P, DATA1_3_N  : IN STD_LOGIC;
        DATA1_4_P, DATA1_4_N  : IN STD_LOGIC;
        DATA1_5_P, DATA1_5_N  : IN STD_LOGIC;
        DATA1_6_P, DATA1_6_N  : IN STD_LOGIC;
        DATA1_7_P, DATA1_7_N  : IN STD_LOGIC;
        DATA1_8_P, DATA1_8_N  : IN STD_LOGIC;

        DI_1_P, DI_1_N        : OUT STD_LOGIC;
        DI_2_P, DI_2_N        : OUT STD_LOGIC;
        DI_3_P, DI_3_N        : OUT STD_LOGIC;
        DI_4_P, DI_4_N        : OUT STD_LOGIC;
        DI_5_P, DI_5_N        : OUT STD_LOGIC;
        DI_6_P, DI_6_N        : OUT STD_LOGIC;
        DI_7_P, DI_7_N        : OUT STD_LOGIC;
        DI_8_P, DI_8_N        : OUT STD_LOGIC;

        DO_1_P, DO_1_N        : IN STD_LOGIC;
        DO_2_P, DO_2_N        : IN STD_LOGIC;
        DO_3_P, DO_3_N        : IN STD_LOGIC;
        DO_4_P, DO_4_N        : IN STD_LOGIC;
        DO_5_P, DO_5_N        : IN STD_LOGIC;
        DO_6_P, DO_6_N        : IN STD_LOGIC;
        DO_7_P, DO_7_N        : IN STD_LOGIC;
        DO_8_P, DO_8_N        : IN STD_LOGIC;

        ENA_1_P, ENA_1_N      : OUT STD_LOGIC;
        ENA_2_P, ENA_2_N      : OUT STD_LOGIC;
        ENA_3_P, ENA_3_N      : OUT STD_LOGIC;
        ENA_4_P, ENA_4_N      : OUT STD_LOGIC;
        ENA_5_P, ENA_5_N      : OUT STD_LOGIC;
        ENA_6_P, ENA_6_N      : OUT STD_LOGIC;
        ENA_7_P, ENA_7_N      : OUT STD_LOGIC;
        ENA_8_P, ENA_8_N      : OUT STD_LOGIC;
        
        WEN_1_P, WEN_1_N      : OUT STD_LOGIC;
        WEN_2_P, WEN_2_N      : OUT STD_LOGIC;
        WEN_3_P, WEN_3_N      : OUT STD_LOGIC;
        WEN_4_P, WEN_4_N      : OUT STD_LOGIC;
        WEN_5_P, WEN_5_N      : OUT STD_LOGIC;
        WEN_6_P, WEN_6_N      : OUT STD_LOGIC;
        WEN_7_P, WEN_7_N      : OUT STD_LOGIC;
        WEN_8_P, WEN_8_N      : OUT STD_LOGIC;

        CKTK_1_P, CKTK_1_N    : OUT STD_LOGIC;
        CKTK_2_P, CKTK_2_N    : OUT STD_LOGIC;
        CKTK_3_P, CKTK_3_N    : OUT STD_LOGIC;
        CKTK_4_P, CKTK_4_N    : OUT STD_LOGIC;
        CKTK_5_P, CKTK_5_N    : OUT STD_LOGIC;
        CKTK_6_P, CKTK_6_N    : OUT STD_LOGIC;
        CKTK_7_P, CKTK_7_N    : OUT STD_LOGIC;
        CKTK_8_P, CKTK_8_N    : OUT STD_LOGIC;

        CKTP_1_P, CKTP_1_N    : OUT STD_LOGIC;
        CKTP_2_P, CKTP_2_N    : OUT STD_LOGIC;
        CKTP_3_P, CKTP_3_N    : OUT STD_LOGIC;
        CKTP_4_P, CKTP_4_N    : OUT STD_LOGIC;
        CKTP_5_P, CKTP_5_N    : OUT STD_LOGIC;
        CKTP_6_P, CKTP_6_N    : OUT STD_LOGIC;
        CKTP_7_P, CKTP_7_N    : OUT STD_LOGIC;
        CKTP_8_P, CKTP_8_N    : OUT STD_LOGIC;
    
        CKBC_1_P, CKBC_1_N    : OUT STD_LOGIC;
        CKBC_2_P, CKBC_2_N    : OUT STD_LOGIC;
        CKBC_3_P, CKBC_3_N    : OUT STD_LOGIC;
        CKBC_4_P, CKBC_4_N    : OUT STD_LOGIC;
        CKBC_5_P, CKBC_5_N    : OUT STD_LOGIC;
        CKBC_6_P, CKBC_6_N    : OUT STD_LOGIC;
        CKBC_7_P, CKBC_7_N    : OUT STD_LOGIC;
        CKBC_8_P, CKBC_8_N    : OUT STD_LOGIC;
    
        CKDT_1_P, CKDT_1_N    : OUT STD_LOGIC;
        CKDT_2_P, CKDT_2_N    : OUT STD_LOGIC;
        CKDT_3_P, CKDT_3_N    : OUT STD_LOGIC;
        CKDT_4_P, CKDT_4_N    : OUT STD_LOGIC;
        CKDT_5_P, CKDT_5_N    : OUT STD_LOGIC;
        CKDT_6_P, CKDT_6_N    : OUT STD_LOGIC;
        CKDT_7_P, CKDT_7_N    : OUT STD_LOGIC;
        CKDT_8_P, CKDT_8_N    : OUT STD_LOGIC;

        CKART_1_P, CKART_1_N  : OUT STD_LOGIC;
        CKART_2_P, CKART_2_N  : OUT STD_LOGIC;
        CKART_3_P, CKART_3_N  : OUT STD_LOGIC;
        CKART_4_P, CKART_4_N  : OUT STD_LOGIC;
        CKART_5_P, CKART_5_N  : OUT STD_LOGIC;
        CKART_6_P, CKART_6_N  : OUT STD_LOGIC;
        CKART_7_P, CKART_7_N  : OUT STD_LOGIC;
        CKART_8_P, CKART_8_N  : OUT STD_LOGIC;

        SETT_P,    SETT_N     : OUT STD_LOGIC; 
        SETB_P,    SETB_N     : OUT STD_LOGIC;
        TKI_P,     TKI_N      : OUT STD_LOGIC;
        TKO_P,     TKO_N      : IN  STD_LOGIC;

        -- ADDC ART CLK
        -------------------------------------
        CKART_ADDC_P          : OUT STD_LOGIC;
        CKART_ADDC_N          : OUT STD_LOGIC;

        -- xADC Interface
        -------------------------------------
        VP_0                  : IN STD_LOGIC;
        VN_0                  : IN STD_LOGIC;
        Vaux0_v_n             : IN STD_LOGIC;
        Vaux0_v_p             : IN STD_LOGIC;
        Vaux1_v_n             : IN STD_LOGIC;
        Vaux1_v_p             : IN STD_LOGIC;
        Vaux2_v_n             : IN STD_LOGIC;
        Vaux2_v_p             : IN STD_LOGIC;
        Vaux3_v_n             : IN STD_LOGIC;
        Vaux3_v_p             : IN STD_LOGIC;
        Vaux8_v_n             : IN STD_LOGIC;
        Vaux8_v_p             : IN STD_LOGIC;
        Vaux9_v_n             : IN STD_LOGIC;
        Vaux9_v_p             : IN STD_LOGIC;
        Vaux10_v_n            : IN STD_LOGIC;
        Vaux10_v_p            : IN STD_LOGIC;
        Vaux11_v_n            : IN STD_LOGIC;
        Vaux11_v_p            : IN STD_LOGIC;

        MuxAddr0              : OUT STD_LOGIC;
        MuxAddr1              : OUT STD_LOGIC;
        MuxAddr2              : OUT STD_LOGIC;
        MuxAddr3_p            : OUT STD_LOGIC;
        MuxAddr3_n            : OUT STD_LOGIC;

        ---- E-link Interface, Data
        -----------------------------------------
        ELINK_DAQ_TX_P        : OUT   STD_LOGIC;
        ELINK_DAQ_TX_N        : OUT   STD_LOGIC;
        ELINK_DAQ_RX_P        : IN    STD_LOGIC;
        ELINK_DAQ_RX_N        : IN    STD_LOGIC;
        --ELINK_TTC_RX_P        : IN    STD_LOGIC;
        --ELINK_TTC_RX_N        : IN    STD_LOGIC;

        ---- E-link Interface, Clock
        -----------------------------------------
        ELINK_DAQ_CLK_P       : IN    STD_LOGIC;
        ELINK_DAQ_CLK_N       : IN    STD_LOGIC;
        --ELINK_TTC_CLK_P       : IN    STD_LOGIC;
        --ELINK_TTC_CLK_N       : IN    STD_LOGIC;
        
        -- E-link MMCM locked LED
        LED_LOCKED            : OUT   STD_LOGIC;

        -- AXI4SPI Flash Configuration
        ---------------------------------------
        IO0_IO                : INOUT STD_LOGIC;
        IO1_IO                : INOUT STD_LOGIC;
        SS_IO                 : INOUT STD_LOGIC
      );
end mmfe8_top;

architecture Behavioral of mmfe8_top is

    -- Default IP and MAC address of the board
    signal default_IP     : std_logic_vector(31 downto 0) := x"c0a80002";
    signal default_MAC    : std_logic_vector(47 downto 0) := x"002320212228";
    signal default_destIP : std_logic_vector(31 downto 0) := x"c0a80010";
    
    -- Set to '1' if MMFE8 VMM3 is used
    signal is_mmfe8       : std_logic := '0';
    
    -- clock generation signals for tranceiver
    signal gtrefclkp, gtrefclkn  : std_logic;                    -- Route gtrefclk through an IBUFG.
    signal txoutclk              : std_logic;                    -- txoutclk from GT transceiver
    signal resetdone             : std_logic;                    -- To indicate that the GT transceiver has completed its reset cycle
    signal mmcm_locked           : std_logic;                    -- MMCM locked signal.
    signal mmcm_reset            : std_logic;                    -- MMCM reset signal.
    signal clkfbout              : std_logic;                    -- MMCM feedback clock
    signal userclk               : std_logic;                    -- 62.5MHz clock for GT transceiver Tx/Rx user clocks
    signal userclk2              : std_logic;                    -- 125MHz clock for core reference clock.
    -- PMA reset generation signals for tranceiver
    signal pma_reset_pipe        : std_logic_vector(3 downto 0); -- flip-flop pipeline for reset duration stretch
    signal pma_reset             : std_logic;                    -- Synchronous transcevier PMA reset
    -- An independent clock source used as the reference clock for an
    -- IDELAYCTRL (if present) and for the main GT transceiver reset logic.
    signal independent_clock_bufg: std_logic;
    -- clock generation signals for SGMII clock
    signal sgmii_clk_r           : std_logic;                    -- Clock to client MAC (125MHz, 12.5MHz or 1.25MHz) (to rising edge DDR).
    signal sgmii_clk_f           : std_logic;                    -- Clock to client MAC (125MHz, 12.5MHz or 1.25MHz) (to falling edge DDR).
    -- GMII signals
    signal gmii_isolate          : std_logic;                    -- Internal gmii_isolate signal.
    signal gmii_txd_int          : std_logic_vector(7 downto 0); -- Internal gmii_txd signal (between core and SGMII adaptation module).
    signal gmii_tx_en_int        : std_logic;                    -- Internal gmii_tx_en signal (between core and SGMII adaptation module).
    signal gmii_tx_er_int        : std_logic;                    -- Internal gmii_tx_er signal (between core and SGMII adaptation module).
    signal gmii_rxd_int          : std_logic_vector(7 downto 0); -- Internal gmii_rxd signal (between core and SGMII adaptation module).
    signal gmii_rx_dv_int        : std_logic;                    -- Internal gmii_rx_dv signal (between core and SGMII adaptation module).
    signal gmii_rx_er_int        : std_logic;                    -- Internal gmii_rx_er signal (between core and SGMII adaptation module).
    
    -- Extra registers to ease IOB placement
    signal status_vector_int : std_logic_vector(15 downto 0);
    
    ----------------------------panos---------------------------------
    signal gmii_txd_emac               : std_logic_vector(7 downto 0);
    signal gmii_tx_en_emac             : std_logic; 
    signal gmii_tx_er_emac             : std_logic; 
    signal gmii_rxd_emac               : std_logic_vector(7 downto 0);
    signal gmii_rx_dv_emac             : std_logic; 
    signal gmii_rx_er_emac             : std_logic; 
    signal speed_is_10_100             : std_logic;
    signal speed_is_100                : std_logic;
    signal tx_axis_mac_tready_int      : std_logic;
    signal rx_axis_mac_tuser_int       : std_logic;
    signal rx_axis_mac_tlast_int       : std_logic;
    signal rx_axis_mac_tdata_int       : std_logic_vector(7 downto 0);
    signal rx_axis_mac_tvalid_int      : std_logic;
    signal local_gtx_reset             : std_logic;
    signal rx_reset                    : std_logic;
    signal tx_reset                    : std_logic;
    signal gtx_pre_resetn              : std_logic := '0';
    signal tx_axis_mac_tdata_int       : std_logic_vector(7 downto 0);    
    signal tx_axis_mac_tvalid_int      : std_logic;
    signal tx_axis_mac_tlast_int       : std_logic;  
    signal gtx_resetn                  : std_logic;
    signal glbl_rstn                   : std_logic;
    signal glbl_rst_i                  : std_logic := '0';
    signal gtx_clk_reset_int           : std_logic;
    signal an_restart_config_int       : std_logic;
    signal rx_axis_mac_tready_int      : std_logic;
    signal rx_configuration_vector_int : std_logic_vector(79 downto 0);
    signal tx_configuration_vector_int : std_logic_vector(79 downto 0);
    signal vector_resetn               : std_logic := '0';
    signal vector_pre_resetn           : std_logic := '0';
    signal vector_reset_int            : std_logic;
    signal clk_enable_int              : std_logic;
    signal udp_txi_int                 : udp_tx_type;
    signal control                     : udp_control_type;
    signal udp_rx_int                  : udp_rx_type;
    signal ip_rx_hdr_int               : ipv4_rx_header_type;
    signal udp_tx_data_out_ready_int   : std_logic;
    signal udp_tx_start_int            : std_logic;
    signal icmp_rx_start               : std_logic;
    signal icmp_rxo                    : icmp_rx_type;
    
    signal user_data_out_i             : std_logic_vector(63 downto 0); 
    signal end_packet_i                : std_logic := '0';    
    signal we_conf_int                 : std_logic := '0';    
    signal packet_length_int           : std_logic_vector(11 downto 0);
    signal daq_data_out_i              : std_logic_vector(63 downto 0);
    signal conf_data_out_i             : std_logic_vector(63 downto 0);
    signal daq_wr_en_i                 : std_logic := '0';    
    signal end_packet_daq              : std_logic := '0'; 
    signal start_conf_proc_int         : std_logic := '0';
    
    ------------------------------VMM configuration------------------------------
    signal vmm_di_vec_obuf              : std_logic_vector(8 downto 1);
    signal vmm_do_vec_ibuf              : std_logic_vector(8 downto 1);
    signal vmm_di_all                   : std_logic := '0';
    signal vmm_bitmask                  : std_logic_vector(7 downto 0) := "11111111";
    signal vmm_cktk_conf                : std_logic := '0';
    
    ------------------------------ Select VMM ------------------------------
    signal conf_cktk_out_vec_i          : std_logic_vector(8 downto 1);
    signal conf_vmm_wen_vec             : std_logic_vector(8 downto 1);
    signal conf_vmm_ena_vec             : std_logic_vector(8 downto 1);

    -------------------------------------------------
    -- MMCM/Configuration Signals
    -------------------------------------------------
    signal clk_320_daq        : std_logic;
    signal clk_80_daq         : std_logic;
    signal clk_160_daq        : std_logic;
    signal clk_10_phase45_daq : std_logic;
    signal clk_50_daq         : std_logic;
    signal clk_40_daq         : std_logic;
    signal clk_200_i          : std_logic;
    signal mmcm_delay_locked  : std_logic;
    
    signal clk_320_ttc        : std_logic;
    signal clk_80_ttc         : std_logic;
    signal clk_160_ttc        : std_logic;
    signal clk_10_phase45_ttc : std_logic;
    signal clk_50_ttc         : std_logic;
    signal clk_40_ttc         : std_logic;
    
    signal tko_i              : std_logic;
    signal cnt_reply          : integer := 0;
    
    signal end_packet_conf_int: std_logic := '0';
    signal end_packet_daq_int : std_logic := '0';
    signal is_state           : std_logic_vector(3 downto 0)  := "1010";
    signal latency_conf       : std_logic_vector(15 downto 0) := x"0000";
    
    signal wait_cnt           : unsigned(7 downto 0) := (others => '0');
    signal vmm_id_rdy         : std_logic := '0';
    signal newIP_rdy          : std_logic := '0';
    signal xadc_conf_rdy      : std_logic := '0';
    signal daq_on             : std_logic := '0';
    signal vmmConf_done       : std_logic := '0';
    signal fpga_reset_conf    : std_logic := '0';
    signal flash_busy         : std_logic := '0';
    signal inhibit_conf       : std_logic := '0';
    
    signal conf_wen_i         : std_logic := '0';
    signal conf_ena_i         : std_logic := '0';
    signal clk_ttc_locked     : std_logic := '0';
    signal vmm_cktk_vec       : std_logic_vector(8 downto 1) := (others => '0');
    signal daq_sigs_enable    : std_logic_vector(8 downto 1) := (others => '0');
    signal conf_cktk_vec      : std_logic_vector(8 downto 1) := (others => '0');

    -------------------------------------------------
    -- VMM Signals                   
    -------------------------------------------------
    signal vmm_wen_vec      : std_logic_vector(8 downto 1);
    signal vmm_ena_vec      : std_logic_vector(8 downto 1);

    signal cktk_out_vec     : std_logic_vector(8 downto 1);
    signal ckdt_out_vec     : std_logic_vector(8 downto 1);
    signal data0_in_vec     : std_logic_vector(8 downto 1);
    signal data1_in_vec     : std_logic_vector(8 downto 1);
    
    signal vmm_ckbc_vec     : std_logic_vector(8 downto 1);
    signal vmm_cktp_vec     : std_logic_vector(8 downto 1);
    signal ckart_vec        : std_logic_vector(9 downto 1);

    signal CKTP_glbl        : std_logic := '0';

    signal CKTP_i           : std_logic := '0';
    signal CKTP_glbl_s125   : std_logic := '0';        

    signal tied_to_gnd_i    : std_logic := '0';

    -------------------------------------------------
    -- Readout Signals
    -------------------------------------------------
    signal daq_enable_i             : std_logic;
    signal cktp_state               : integer := 0;
    signal vmm_cktk_vec_ro          : std_logic_vector(8 downto 1) := ( others => '0' );
    signal daqFIFO_wr_en_i          : std_logic := '0';
    signal daqFIFO_din_i            : std_logic_vector(63 downto 0);
    signal vmmWordReady_i           : std_logic := '0';
    signal vmmWord_i                : std_logic_vector(63 downto 0);
    signal vmmEventDone_i           : std_logic := '0';
    signal daqFIFO_reset            : std_logic := '0';
    signal UDPDone                  : std_logic;
    signal ckbc_enable              : std_logic := '1';
    signal cktp_enable              : std_logic := '0';
    signal daq_is_on                : std_logic := '0';
    signal daq_is_on_i              : std_logic := '0';
    signal daq_is_on_s              : std_logic := '0';
   
    -------------------------------------------------
    -- Trigger Signals
    -------------------------------------------------
    signal tren               : std_logic := '0';
    signal tr_hold            : std_logic := '0';
    signal trmode             : std_logic := '0';
    signal ext_trigger_in     : std_logic := '0';
    signal trint              : std_logic := '0';
    signal tr_reset           : std_logic := '0';
    signal event_counter_i    : std_logic_vector(31 downto 0);
    signal tr_out_i           : std_logic;
    signal trig_mode_int      : std_logic := '0';   
    signal trig_mode_int_i    : std_logic := '0';
    signal trig_mode_int_s    : std_logic := '0';
    signal ext_trigger_i      : std_logic;  
  
    -------------------------------------------------
    -- Event Timing & Soft Reset
    -------------------------------------------------
    signal etr_vmm_wen_vec  : std_logic_vector(8 downto 1)  := ( others => '0' );
    signal etr_vmm_ena_vec  : std_logic_vector(8 downto 1)  := ( others => '0' );
    signal etr_reset_latched: std_logic;
    signal glBCID_i         : std_logic_vector(11 downto 0) := ( others => '0' );
    signal state_rst_etr_i  : std_logic_vector(2 downto 0)  := ( others => '0' );
    signal rst_etr_i        : std_logic;
    signal rst_done_etr_i   : std_logic;

    -------------------------------------------------
    -- Packet Formation Signals
    -------------------------------------------------
    signal pf_newCycle  : std_logic;
    signal pf_packLen   : std_logic_vector(11 downto 0);
    signal pf_trigVmmRo : std_logic := '0';
    signal pf_vmmIdRo   : std_logic_vector(2 downto 0) := b"000";
    signal pf_reset     : std_logic := '0';
    signal rst_vmm      : std_logic := '0';
    signal pf_rst_FIFO  : std_logic := '0';
    signal pfBusy_i     : std_logic := '0';
    signal daq_data_out_pf_i : std_logic_vector(63 downto 0) := (others => '0');
    signal daq_wr_en_pf_i : std_logic := '0';
    
    ------------------------------------------------------------------
    -- xADC signals
    ------------------------------------------------------------------
    signal xadc_start           : std_logic;
    signal vmm_id_xadc          : std_logic_vector (15 downto 0) := (others => '0');
    signal xadc_sample_size     : std_logic_vector (10 downto 0) := "01111111111"; -- 1023 packets
    signal xadc_delay           : std_logic_vector (17 downto 0) := "011111111111111111"; -- 1023 samples over ~0.7 seconds
    signal xadc_end_of_data     : std_logic;
    signal xadc_fifo_bus        : std_logic_vector (63 downto 0);
    signal xadc_fifo_enable     : std_logic;
    signal xadc_packet_len      : std_logic_vector (11 downto 0);
    signal xadc_busy            : std_logic;
    signal MuxAddr0_i           : std_logic := '0';
    signal MuxAddr1_i           : std_logic := '0';
    signal MuxAddr2_i           : std_logic := '0';
    signal MuxAddr3_p_i         : std_logic := '0';
    signal MuxAddr3_n_i         : std_logic := '0';

    ------------------------------------------------------------------
    -- Dynamic IP signals
    ------------------------------------------------------------------
    signal myIP_set             : std_logic_vector (31 downto 0);    
    signal myMAC_set            : std_logic_vector (47 downto 0);    
    signal destIP_set           : std_logic_vector (31 downto 0);
    signal myIP                 : std_logic_vector (31 downto 0);    
    signal myMAC                : std_logic_vector (47 downto 0);    
    signal destIP               : std_logic_vector (31 downto 0);
    signal newIP_start          : std_logic;                        
    signal io0_i                : std_logic:= '0';
    signal io0_o                : std_logic:= '0';
    signal io0_t                : std_logic:= '0';
    signal io1_i                : std_logic:= '0';
    signal io1_o                : std_logic:= '0';
    signal io1_t                : std_logic:= '0';
    signal ss_i                 : std_logic_vector(0 DOWNTO 0):=(others => '0');  
    signal ss_o                 : std_logic_vector(0 DOWNTO 0):=(others => '0');  
    signal ss_t                 : std_logic:= '0'; 

    ------------------------------------------------------------------
    -- CKBC/CKTP Generator signals
    ------------------------------------------------------------------ 
    signal clk_daq_locked     : std_logic := '0';
    signal rst_gen            : std_logic := '0';  
    signal CKBC_glbl          : std_logic := '0';
    signal rst_enable         : std_logic := '0';
    constant rst_enable_conf  : std_logic := '0';
    constant rst_period       : std_logic_vector(15 downto 0)    := x"1388"; -- 1 ms
    constant rst_before_cktp  : std_logic_vector(7 downto 0)     := b"10000000";
    constant cktp_pulse_width : std_logic_vector(7 downto 0)     := x"04";
    constant cktp_period      : std_logic_vector(15 downto 0)    := x"4000";
    constant cktp_skew        : std_logic_vector(7 downto 0)     := x"04"; 
    constant ckbc_freq        : std_logic_vector(7 downto 0)     := x"0a"; --40 Mhz
    constant cktp_max_num     : std_logic_vector(15 downto 0)    := x"ffff";
    constant cktk_max_num     : std_logic_vector(7 downto 0)     := x"07";
    
    ------------------------------------------------------------------
    -- E-LINK signals
    ------------------------------------------------------------------ 
    signal rst_elink_mmcm       : std_logic := '0';
    signal rst_elink_glbl       : std_logic := '0';
    signal rst_elink_tx         : std_logic := '0';
    signal rst_elink_rx         : std_logic := '0';
    signal swap_tx              : std_logic := '0';
    signal swap_rx              : std_logic := '0';
  
    signal pattern_enable       : std_logic := '0'; -- DEFAULT: disable pattern
    signal daq_enable           : std_logic := '0'; -- DEFAULT: disable daq
    signal loopback_enable      : std_logic := '0'; -- DEFAULT: disable loopback
    signal selDAQelinkUDP       : std_logic_vector(1 downto 0) := "01";
    
    signal daq_data_elink_i     : std_logic_vector(63 downto 0) := (others => '0');
    signal daq_wr_en_elink_i    : std_logic := '0';
    
    signal elink_DAQ_tx         : std_logic := '0';
    signal elink_DAQ_rx         : std_logic := '0';
    signal elink_TTC_rx         : std_logic := '0';
    signal flush_pf             : std_logic := '0';
    signal rst_tx_final         : std_logic := '0';
    ------
    signal tap_increase         : std_logic := '0';
    signal tap_decrease         : std_logic := '0';
    signal tap_rst              : std_logic := '0';
    signal ctrl_rst             : std_logic := '0';
    signal rdy_all              : std_logic := '0';
    signal elink_busy           : std_logic := '0';
    signal cnt_delay            : std_logic_vector(4 downto 0) := (others => '0');
    signal sel_tx               : std_logic := '0';

    -------------------------------------------------
    -- Flow FSM signals
    -------------------------------------------------
    type state_t is (IDLE, CONFIGURE, CONF_DONE, CONFIGURE_DELAY, SEND_CONF_REPLY, DAQ_INIT, FIRST_RESET, TRIG, DAQ, XADC_init, XADC_wait, FLASH_init, FLASH_wait);
    signal state        : state_t := IDLE;
    signal rstFIFO_top  : std_logic := '0';

    -------------------------------------------------
    -- Debugging Signals
    -------------------------------------------------
    signal vmmSignalsProbe      : std_logic_vector(63 downto 0);
    signal triggerETRProbe      : std_logic_vector(63 downto 0);
    signal configurationProbe   : std_logic_vector(63 downto 0);
    signal readoutProbe         : std_logic_vector(63 downto 0);
    signal dataOutProbe         : std_logic_vector(63 downto 0);
    signal flowProbe            : std_logic_vector(63 downto 0);
    signal trigger_i            : std_logic;
    signal conf_counter         : std_logic_vector(7 downto 0) := (others => '0');
    signal conf_state           : std_logic_vector(2 downto 0) := (others => '0');
    signal dt_state             : std_logic_vector(3 downto 0) := (others => '0');
    signal dt_cntr_state        : std_logic_vector(3 downto 0) := (others => '0');
    signal pf_state             : std_logic_vector(4 downto 0) := (others => '0');

    -------------------------------------------------------------------
    -- These attribute will stop timing errors being reported in back
    -- annotated SDF simulation.
    -------------------------------------------------------------------
    attribute ASYNC_REG                         : string;
    attribute ASYNC_REG of pma_reset_pipe       : signal is "TRUE";
    attribute ASYNC_REG of trig_mode_int_i      : signal is "TRUE";
    attribute ASYNC_REG of trig_mode_int_s      : signal is "TRUE";
    attribute ASYNC_REG of daq_is_on_i          : signal is "TRUE";
    attribute ASYNC_REG of daq_is_on_s          : signal is "TRUE";
   
    -------------------------------------------------------------------
    -- Keep signals for ILA
    -------------------------------------------------------------------
    attribute keep          : string;
    attribute dont_touch    : string;
    attribute mark_debug    : string;
    attribute IOB           : string;
  
    -------------------------------------------------------------------
    -- Readout Monitoring
    -------------------------------------------------------------------
--    attribute keep of vmm_wen_vec           : signal is "true";
--    attribute dont_touch of vmm_wen_vec     : signal is "true";
--    attribute keep of cktk_out_vec          : signal is "true";
--    attribute dont_touch of cktk_out_vec    : signal is "true";
--    attribute keep of ckdt_out_vec          : signal is "true"; 
--    attribute keep of data0_in_vec          : signal is "true";
--    attribute dont_touch of data0_in_vec    : signal is "true";

    -------------------------------------------------------------------
    -- Trigger
    -------------------------------------------------------------------
--    attribute keep of trint               : signal is "true";
--    attribute keep of tren                : signal is "true";
--    attribute keep of ext_trigger_in      : signal is "true";
--    attribute keep of trig_mode_int       : signal is "true";
--    attribute keep of tr_hold             : signal is "true";
--    attribute dont_touch of tr_hold       : signal is "true";
--    attribute mark_debug of tr_hold       : signal is "true";

    -------------------------------------------------------------------
    -- Event Timing & Soft Reset
    -------------------------------------------------------------------
--    attribute keep of etr_reset_latched      : signal is "true";
--    attribute keep of rst_vmm                : signal is "true";
--    attribute keep of etr_vmm_ena_vec        : signal is "true";
--    attribute keep of daq_enable_i           : signal is "true";
--    attribute keep of glBCID_i               : signal is "true";
--    attribute dont_touch of glBCID_i         : signal is "true";
--    attribute keep of state_rst_etr_i        : signal is "true";
--    attribute dont_touch of state_rst_etr_i  : signal is "true";
--    attribute keep of rst_etr_i              : signal is "true";
--    attribute dont_touch of rst_etr_i        : signal is "true";
--    attribute keep of rst_done_etr_i         : signal is "true";
--    attribute dont_touch of rst_done_etr_i   : signal is "true";
    
    -------------------------------------------------------------------
    -- Packet Formation
    -------------------------------------------------------------------
--    attribute keep of pf_newCycle           : signal is "true";
--    attribute keep of pfBusy_i              : signal is "true";
--    attribute dont_touch of pfBusy_i        : signal is "true";
    
    -------------------------------------------------------------------
    -- Dynamic IP
    -------------------------------------------------------------------   
--    attribute keep of io0_i                         : signal is "TRUE";  
--    attribute keep of io0_o                         : signal is "TRUE";  
--    attribute keep of io0_t                         : signal is "TRUE";  
--    attribute keep of io1_i                         : signal is "TRUE";  
--    attribute keep of io1_o                         : signal is "TRUE";  
--    attribute keep of io1_t                         : signal is "TRUE";  
--    attribute keep of ss_i                          : signal is "TRUE";  
--    attribute keep of ss_o                          : signal is "TRUE";  
--    attribute keep of ss_t                          : signal is "TRUE";  
    
    -------------------------------------------------------------------
    -- Other
    -------------------------------------------------------------------
--    attribute keep of tx_axis_mac_tready_int    : signal is "TRUE";
--    attribute keep of user_data_out_i           : signal is "TRUE";
--    attribute dont_touch of user_data_out_i     : signal is "TRUE";
--    attribute keep of we_conf_int               : signal is "TRUE";
--    attribute keep of daqFIFO_wr_en_i           : signal is "TRUE";
--    attribute keep of daqFIFO_din_i             : signal is "TRUE";
--    attribute keep of udp_tx_start_int          : signal is "TRUE";
--    attribute keep of udp_tx_data_out_ready_int : signal is "TRUE";
--    attribute keep of conf_wen_i                : signal is "TRUE";
--    attribute dont_touch of conf_wen_i          : signal is "TRUE";
--    attribute keep of conf_ena_i                : signal is "TRUE";
--    attribute dont_touch of conf_ena_i          : signal is "TRUE";
--    attribute keep of start_conf_proc_int       : signal is "TRUE";
--    attribute keep of cnt_reply                 : signal is "TRUE";
--    attribute keep of end_packet_conf_int       : signal is "TRUE";
--    attribute keep of xadc_busy                 : signal is "TRUE";
--    attribute keep of daqFIFO_reset             : signal is "TRUE";
--    attribute keep of rstFIFO_top               : signal is "TRUE";
--    attribute keep of pf_rst_FIFO               : signal is "TRUE";  
--    attribute keep of trigger_i                 : signal is "TRUE";
--    attribute dont_touch of trigger_i           : signal is "TRUE";        
--    attribute keep of vmm_ena_vec               : signal is "TRUE";
--    attribute dont_touch of vmm_ena_vec         : signal is "TRUE";           
--    attribute keep of tko_i                     : signal is "TRUE";
--    attribute dont_touch of tko_i               : signal is "TRUE";   
--    attribute keep of default_IP                : signal is "TRUE";
--    attribute dont_touch of default_IP          : signal is "TRUE";    
--    attribute keep of default_MAC               : signal is "TRUE";
--    attribute dont_touch of default_MAC         : signal is "TRUE";

    attribute mark_debug of clk_daq_locked      : signal is "TRUE";
    attribute mark_debug of clk_ttc_locked      : signal is "TRUE";
    attribute dont_touch of clk_ttc_locked      : signal is "TRUE";
    attribute keep of clk_ttc_locked            : signal is "TRUE";
    
    -------------------------------------------------------------------
    -- VIO
    -------------------------------------------------------------------
    attribute keep of pattern_enable          : signal is "TRUE";
    attribute keep of daq_enable              : signal is "TRUE";
    attribute keep of loopback_enable         : signal is "TRUE";
    attribute keep of rst_elink_glbl          : signal is "TRUE";
    attribute keep of rst_elink_mmcm          : signal is "TRUE";
    attribute keep of rst_elink_tx            : signal is "TRUE";
    attribute keep of rst_elink_rx            : signal is "TRUE";
    attribute keep of swap_rx                 : signal is "TRUE";
    attribute keep of swap_tx                 : signal is "TRUE";
    attribute keep of selDAQelinkUDP          : signal is "TRUE";
    
    attribute keep of tap_increase            : signal is "TRUE";
    attribute keep of tap_decrease            : signal is "TRUE";
    attribute keep of tap_rst                 : signal is "TRUE";
    attribute keep of ctrl_rst                : signal is "TRUE";
    attribute keep of rdy_all                 : signal is "TRUE";
    attribute keep of cnt_delay               : signal is "TRUE";
    attribute keep of mmcm_delay_locked       : signal is "TRUE";
    attribute keep of sel_tx                  : signal is "TRUE";
    
    attribute dont_touch of tap_increase      : signal is "TRUE";
    attribute dont_touch of tap_decrease      : signal is "TRUE";
    attribute dont_touch of tap_rst           : signal is "TRUE";
    attribute dont_touch of ctrl_rst          : signal is "TRUE";
    attribute dont_touch of rdy_all           : signal is "TRUE";
    attribute dont_touch of cnt_delay         : signal is "TRUE";
    attribute dont_touch of mmcm_delay_locked : signal is "TRUE";
    attribute dont_touch of sel_tx            : signal is "TRUE";
    
    attribute dont_touch of pattern_enable    : signal is "TRUE";
    attribute dont_touch of daq_enable        : signal is "TRUE";
    attribute dont_touch of loopback_enable   : signal is "TRUE";
    attribute dont_touch of rst_elink_glbl    : signal is "TRUE";
    attribute dont_touch of rst_elink_mmcm    : signal is "TRUE";
    attribute dont_touch of rst_elink_tx      : signal is "TRUE";
    attribute dont_touch of rst_elink_rx      : signal is "TRUE";
    attribute dont_touch of swap_rx           : signal is "TRUE";
    attribute dont_touch of swap_tx           : signal is "TRUE";
    attribute dont_touch of selDAQelinkUDP    : signal is "TRUE";
    
    attribute IOB of ELINK_DAQ_TX_P    : signal is "TRUE";
    attribute IOB of ELINK_DAQ_TX_N    : signal is "TRUE";
    attribute IOB of ELINK_DAQ_RX_P    : signal is "TRUE";
    attribute IOB of ELINK_DAQ_RX_N    : signal is "TRUE";
               
    -------------------------------------------------------------------
    --                       COMPONENTS                              --
    -------------------------------------------------------------------
    -- 1.  master_clk
    -- 2.  event_timing_reset
    -- 3.  vmm_readout
    -- 4.  FIFO2UDP
    -- 5.  trigger
    -- 6.  packet_formation
    -- 7. gig_ethernet_pcs_pma_0
    -- 8. UDP_Complete_nomac
    -- 9. temac_10_100_1000_fifo_block
    -- 10. temac_10_100_1000_reset_sync
    -- 11. temac_10_100_1000_config_vector_sm
    -- 12. i2c_top
    -- 13. udp_data_in_handler
    -- 14. select_data
    -- 15. ila_top_level
    -- 16. xadc
    -- 17. AXI4_SPI
    -- 18. CDCC
    -- 19. VIO_2
    -- 20. clk_gen_wrapper
    -- 21. vmm_oddr_wrapper
    -- 22. elink_wrapper
    -- 23. mmcm_ttc
    -------------------------------------------------------------------
    -- 1
    component master_clk
    port
     (  -- Clock in ports
        clk_in1_p       : in  std_logic;
        clk_in1_n       : in  std_logic;
        -- Clock out ports
        clk_out_40      : out std_logic;
        clk_out_80      : out std_logic;
        clk_out_160     : out std_logic;
        clk_out_320     : out std_logic;
        clk_out_50      : out std_logic;
        clk_out_10_45   : out std_logic;
        -- Status and control signals
        reset           : in  std_logic;
        locked          : out std_logic
     );
    end component;
    -- 2
    component event_timing_reset
      port(
          hp_clk          : in std_logic;
          clk             : in std_logic;
          clk_10_phase45  : in std_logic;
          bc_clk          : in std_logic;
          
          daqEnable       : in std_logic;
          pfBusy          : in std_logic;
          reset           : in std_logic;

          glBCID          : out std_logic_vector(11 downto 0);
          prec_cnt        : out std_logic_vector(4 downto 0);

          state_rst_out   : out std_logic_vector(2 downto 0);
          rst_o           : out std_logic;
          rst_done_o      : out std_logic;

          vmm_ena_vec     : out std_logic_vector(8 downto 1);
          vmm_wen_vec     : out std_logic_vector(8 downto 1);
          reset_latched   : out std_logic
      );
    end component;    
    -- 3
    component vmm_readout is
        port ( 
            clkTkProc               : in std_logic;     -- Used to clock checking for data process
            clkDtProc               : in std_logic;     -- Used to clock word readout process
            clk                     : in std_logic;     -- Used for fast switching between processes

            vmm_data0_vec           : in std_logic_vector(8 downto 1);      -- Single-ended data0 from VMM
            vmm_data1_vec           : in std_logic_vector(8 downto 1);      -- Single-ended data1 from VMM
            vmm_ckdt_vec            : out std_logic_vector(8 downto 1);     -- Strobe to VMM CKDT
            vmm_cktk_vec            : out std_logic_vector(8 downto 1);     -- Strobe to VMM CKTK

            daq_enable              : in std_logic;
            trigger_pulse           : in std_logic;                     -- Trigger
            cktk_max                : in std_logic_vector(7 downto 0);
            vmmId                   : in std_logic_vector(2 downto 0);  -- VMM to be readout
            ethernet_fifo_wr_en     : out std_logic;                    -- To be used for reading out seperate FIFOs in VMMx8 parallel readout
            vmm_data_buf            : buffer std_logic_vector(37 downto 0);
    
            dt_state_o              : out std_logic_vector(3 downto 0);
            dt_cntr_st_o            : out std_logic_vector(3 downto 0);
            
            vmmWordReady            : out std_logic;
            vmmWord                 : out std_logic_vector(63 downto 0);
            vmmEventDone            : out std_logic
        );
    end component;
    -- 4
    component FIFO2UDP
        port ( 
            clk_125                     : in std_logic;
            destinationIP               : in std_logic_vector(31 downto 0);
            daq_data_in                 : in  std_logic_vector(63 downto 0);
            fifo_data_out               : out std_logic_vector (7 downto 0);
            udp_txi                     : out udp_tx_type;    
            udp_tx_start                : out std_logic;
            re_out                      : out std_logic;
            control                     : out std_logic;
            UDPDone                     : out std_logic;
            udp_tx_data_out_ready       : in  std_logic;
            wr_en                       : in  std_logic;
            end_packet                  : in  std_logic;
            global_reset                : in  std_logic;
            packet_length_in            : in  std_logic_vector(11 downto 0);
            reset_DAQ_FIFO              : in  std_logic;
    
            vmmID                       : in  std_logic_vector(2 downto 0);
            
            trigger_out                 : out std_logic
        );
    end component;
    -- 5
    component trigger is
      port (
          clk             : in std_logic;
          
          tren            : in std_logic;
          tr_hold         : in std_logic;
          trmode          : in std_logic;
          trext           : in std_logic;
          trint           : in std_logic;
          reset           : in std_logic;
          
          event_counter   : out std_logic_vector(31 DOWNTO 0);
          tr_out          : out std_logic
      );
    end component;
    -- 6
    component packet_formation is
    port (
            clk         : in std_logic;
    
            newCycle    : in std_logic;
            
            trigVmmRo   : out std_logic;
            vmmId       : out std_logic_vector(2 downto 0);
            vmmWord     : in std_logic_vector(63 downto 0);
            vmmWordReady: in std_logic;
            vmmEventDone: in std_logic;
        
            UDPDone     : in std_logic;
            pfBusy      : out std_logic;
            glBCID      : in std_logic_vector(11 downto 0);

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
            
            --trigger     : in std_logic
    );
    end component;
    -- 7
    component gig_ethernet_pcs_pma_0
        port(
            -- Transceiver Interface
            ---------------------
            gtrefclk_p               : in  std_logic;                          
            gtrefclk_n               : in  std_logic;                         
            
            gtrefclk_out             : out std_logic;                           -- Very high quality clock for GT transceiver.
            gtrefclk_bufg_out        : out std_logic;                           
                
            txp                      : out std_logic;                    -- Differential +ve of serial transmission from PMA to PMD.
            txn                      : out std_logic;                    -- Differential -ve of serial transmission from PMA to PMD.
            rxp                      : in  std_logic;                     -- Differential +ve for serial reception from PMD to PMA.
            rxn                      : in  std_logic;                     -- Differential -ve for serial reception from PMD to PMA.
            resetdone                : out std_logic;                           -- The GT transceiver has completed its reset cycle
            userclk_out              : out std_logic;                           
            userclk2_out             : out std_logic;                           
            rxuserclk_out            : out std_logic;                         
            rxuserclk2_out           : out std_logic;                         
            pma_reset_out            : out std_logic;                           -- transceiver PMA reset signal
            mmcm_locked_out          : out std_logic;                           -- MMCM Locked
            independent_clock_bufg   : in  std_logic;                   
            
            -- GMII Interface
            -----------------
            sgmii_clk_r             : out std_logic;              
            sgmii_clk_f             : out std_logic;              
            sgmii_clk_en            : out std_logic;                    -- Clock enable for client MAC
            gmii_txd                : in std_logic_vector(7 downto 0);  -- Transmit data from client MAC.
            gmii_tx_en              : in std_logic;                     -- Transmit control signal from client MAC.
            gmii_tx_er              : in std_logic;                     -- Transmit control signal from client MAC.
            gmii_rxd                : out std_logic_vector(7 downto 0); -- Received Data to client MAC.
            gmii_rx_dv              : out std_logic;                    -- Received control signal to client MAC.
            gmii_rx_er              : out std_logic;                    -- Received control signal to client MAC.
            gmii_isolate            : out std_logic;                    -- Tristate control to electrically isolate GMII.
            
            -- Management: Alternative to MDIO Interface
            --------------------------------------------
            
            configuration_vector    : in std_logic_vector(4 downto 0);  -- Alternative to MDIO interface.
            
            an_interrupt            : out std_logic;                    -- Interrupt to processor to signal that Auto-Negotiation has completed
            an_adv_config_vector    : in std_logic_vector(15 downto 0); -- Alternate interface to program REG4 (AN ADV)
            an_restart_config       : in std_logic;                     -- Alternate signal to modify AN restart bit in REG0
            
            -- Speed Control
            ----------------
            speed_is_10_100         : in std_logic;                             -- Core should operate at either 10Mbps or 100Mbps speeds
            speed_is_100            : in std_logic;                             -- Core should operate at 100Mbps speed
            
            -- General IO's
            ---------------
            status_vector           : out std_logic_vector(15 downto 0);        -- Core status.
            reset                   : in std_logic;                             -- Asynchronous reset for entire core.
            
            signal_detect           : in std_logic;                             -- Input from PMD to indicate presence of optical input.
            gt0_pll0outclk_out      : out std_logic;
            gt0_pll0outrefclk_out   : out std_logic;
            gt0_pll1outclk_out      : out std_logic;
            gt0_pll1outrefclk_out   : out std_logic;
            gt0_pll0refclklost_out  : out std_logic;
            gt0_pll0lock_out        : out std_logic);
    end component;
    -- 8
    component UDP_ICMP_Complete_nomac
       Port (
            -- UDP TX signals
            udp_tx_start            : in std_logic;                             -- indicates req to tx UDP
            udp_txi                 : in udp_tx_type;                           -- UDP tx cxns
            udp_tx_result           : out std_logic_vector (1 downto 0);        -- tx status (changes during transmission)
            udp_tx_data_out_ready   : out std_logic;                            -- indicates udp_tx is ready to take data
            -- UDP RX signals
            udp_rx_start            : out std_logic;                            -- indicates receipt of udp header
            udp_rxo                 : out udp_rx_type;
            -- ICMP RX signals
            icmp_rx_start           : out std_logic;
            icmp_rxo                : out icmp_rx_type;
            -- IP RX signals
            ip_rx_hdr               : out ipv4_rx_header_type;
            -- system signals
            rx_clk                  : in  STD_LOGIC;
            tx_clk                  : in  STD_LOGIC;
            reset                   : in  STD_LOGIC;
            our_ip_address          : in STD_LOGIC_VECTOR (31 downto 0);
            our_mac_address         : in std_logic_vector (47 downto 0);
            control                 : in udp_control_type;
            -- status signals
            arp_pkt_count           : out std_logic_vector(7 downto 0);         -- count of arp pkts received
            ip_pkt_count            : out std_logic_vector(7 downto 0);         -- number of IP pkts received for us
            -- MAC Transmitter
            mac_tx_tdata            : out  std_logic_vector(7 downto 0);        -- data byte to tx
            mac_tx_tvalid           : out  std_logic;                           -- tdata is valid
            mac_tx_tready           : in std_logic;                             -- mac is ready to accept data
            mac_tx_tfirst           : out  std_logic;                           -- indicates first byte of frame
            mac_tx_tlast            : out  std_logic;                           -- indicates last byte of frame
            -- MAC Receiver
            mac_rx_tdata            : in std_logic_vector(7 downto 0);          -- data byte received
            mac_rx_tvalid           : in std_logic;                             -- indicates tdata is valid
            mac_rx_tready           : out  std_logic;                           -- tells mac that we are ready to take data
            mac_rx_tlast            : in std_logic);                            -- indicates last byte of the trame
    end component;
    -- 9
    component temac_10_100_1000_fifo_block
    port(
            gtx_clk                    : in  std_logic;
            -- asynchronous reset
            glbl_rstn                  : in  std_logic;
            rx_axi_rstn                : in  std_logic;
            tx_axi_rstn                : in  std_logic;
            -- Receiver Statistics Interface
            -----------------------------------------
            rx_reset                   : out std_logic;
            rx_statistics_vector       : out std_logic_vector(27 downto 0);
            rx_statistics_valid        : out std_logic;
            -- Receiver (AXI-S) Interface
            ------------------------------------------
            rx_fifo_clock              : in  std_logic;
            rx_fifo_resetn             : in  std_logic;
            rx_axis_fifo_tdata         : out std_logic_vector(7 downto 0);
            rx_axis_fifo_tvalid        : out std_logic;
            rx_axis_fifo_tready        : in  std_logic;
            rx_axis_fifo_tlast         : out std_logic;
            -- Transmitter Statistics Interface
            --------------------------------------------
            tx_reset                   : out std_logic;
            tx_ifg_delay               : in  std_logic_vector(7 downto 0);
            tx_statistics_vector       : out std_logic_vector(31 downto 0);
            tx_statistics_valid        : out std_logic;
            -- Transmitter (AXI-S) Interface
            ---------------------------------------------
            tx_fifo_clock              : in  std_logic;
            tx_fifo_resetn             : in  std_logic;
            tx_axis_fifo_tdata         : in  std_logic_vector(7 downto 0);
            tx_axis_fifo_tvalid        : in  std_logic;
            tx_axis_fifo_tready        : out std_logic;
            tx_axis_fifo_tlast         : in  std_logic;
            -- MAC Control Interface
            --------------------------
            pause_req                  : in  std_logic;
            pause_val                  : in  std_logic_vector(15 downto 0);
            -- GMII Interface
            -------------------
            gmii_txd                  : out std_logic_vector(7 downto 0);
            gmii_tx_en                : out std_logic;
            gmii_tx_er                : out std_logic;
            gmii_rxd                  : in  std_logic_vector(7 downto 0);
            gmii_rx_dv                : in  std_logic;
            gmii_rx_er                : in  std_logic;
            clk_enable                : in  std_logic;
            speedis100                : out std_logic;
            speedis10100              : out std_logic;
            -- Configuration Vector
            -------------------------
            rx_configuration_vector   : in  std_logic_vector(79 downto 0);
            tx_configuration_vector   : in  std_logic_vector(79 downto 0));
    end component;
    -- 10
    component temac_10_100_1000_reset_sync
        port ( 
            reset_in           : in  std_logic;    -- Active high asynchronous reset
            enable             : in  std_logic;
            clk                : in  std_logic;    -- clock to be sync'ed to
            reset_out          : out std_logic);     -- "Synchronised" reset signal
    end component;
    -- 11
    component temac_10_100_1000_config_vector_sm is
    port(
      gtx_clk                 : in  std_logic;
      gtx_resetn              : in  std_logic;
      mac_speed               : in  std_logic_vector(1 downto 0);
      update_speed            : in  std_logic;
      rx_configuration_vector : out std_logic_vector(79 downto 0);
      tx_configuration_vector : out std_logic_vector(79 downto 0));
    end component;
    -- 12
    component i2c_top is
    port(  
        clk_in                : in    std_logic;        
        phy_rstn_out          : out   std_logic
    );  
    end component;
    -- 13
    component udp_data_in_handler
    port(
    ------------------------------------
    ------- General Interface ----------
    clk_125             : in  std_logic;
    clk_40              : in  std_logic;
    inhibit_conf        : in  std_logic;
    rst                 : in  std_logic;
    ------------------------------------
    -------- FPGA Config Interface -----
    latency             : out std_logic_vector(15 downto 0);
    serial_number       : out std_logic_vector(31 downto 0);
    daq_on              : out std_logic;
    ext_trigger         : out std_logic;
    ------------------------------------
    -------- UDP Interface -------------
    udp_rx              : in  udp_rx_type;
    ------------------------------------
    ---------- AXI4SPI Interface -------
    flash_busy          : in  std_logic;
    newIP_rdy           : out std_logic;
    myIP_set            : out std_logic_vector(31 downto 0);
    myMAC_set           : out std_logic_vector(47 downto 0);
    destIP_set          : out std_logic_vector(31 downto 0);
    ------------------------------------
    ------ VMM Config Interface --------
    vmm_bitmask         : out std_logic_vector(7 downto 0);  
    vmmConf_rdy         : out std_logic;
    vmmConf_done        : out std_logic;
    vmm_cktk            : out std_logic;
    vmm_cfg_bit         : out std_logic;
    top_rdy             : in  std_logic;
    ------------------------------------
    ---------- XADC Interface ----------
    xadc_busy           : in  std_logic;
    xadc_rdy            : out std_logic;
    vmm_id_xadc         : out std_logic_vector(15 downto 0);
    xadc_sample_size    : out std_logic_vector(10 downto 0);
    xadc_delay          : out std_logic_vector(17 downto 0)
    );
    end component;
    -- 14
    component select_data
    port(
        configuring                 : in  std_logic;
        data_acq                    : in  std_logic;
        xadc                        : in  std_logic;
        we_data                     : in  std_logic;
        we_conf                     : in  std_logic;
        we_xadc                     : in  std_logic;
        daq_data_in                 : in  std_logic_vector(63 downto 0);
        conf_data_in                : in  std_logic_vector(63 downto 0);
        xadc_data_in                : in  std_logic_vector(63 downto 0);
        data_packet_length          : in  std_logic_vector(11 downto 0);
        xadc_packet_length          : in  std_logic_vector(11 downto 0);
        end_packet_conf             : in  std_logic;
        end_packet_daq              : in  std_logic;
        end_packet_xadc             : in  std_logic;
        fifo_rst_daq                : in  std_logic;
        fifo_rst_xadc               : in  std_logic;
        rstFIFO_top                 : in std_logic;
    
        data_out                    : out std_logic_vector(63 downto 0);
        packet_length               : out std_logic_vector(11 downto 0);
        we                          : out std_logic;
        end_packet                  : out std_logic;
        fifo_rst                    : out std_logic
    );
    end component;
    -- 15
    component ila_top_level
        PORT (  clk     : in std_logic;
                probe0  : in std_logic_vector(63 DOWNTO 0);
                probe1  : in std_logic_vector(63 DOWNTO 0);
                probe2  : in std_logic_vector(63 DOWNTO 0); 
                probe3  : in std_logic_vector(63 DOWNTO 0); 
                probe4  : in std_logic_vector(63 DOWNTO 0);
                probe5  : in std_logic_vector(63 DOWNTO 0)
                );
    end component;
    -- 16
    component xadcModule
    port(
        clk125              : in std_logic;
        rst                 : in std_logic;
        
        VP_0                : in std_logic;
        VN_0                : in std_logic;
        Vaux0_v_n           : in std_logic;
        Vaux0_v_p           : in std_logic;
        Vaux1_v_n           : in std_logic;
        Vaux1_v_p           : in std_logic;
        Vaux2_v_n           : in std_logic;
        Vaux2_v_p           : in std_logic;
        Vaux3_v_n           : in std_logic;
        Vaux3_v_p           : in std_logic;
        Vaux8_v_n           : in std_logic;
        Vaux8_v_p           : in std_logic;
        Vaux9_v_n           : in std_logic;
        Vaux9_v_p           : in std_logic;
        Vaux10_v_n          : in std_logic;
        Vaux10_v_p          : in std_logic;
        Vaux11_v_n          : in std_logic;
        Vaux11_v_p          : in std_logic;
        data_in_rdy         : in std_logic;
        vmm_id              : in std_logic_vector(15 downto 0);
        sample_size         : in std_logic_vector(10 downto 0);
        delay_in            : in std_logic_vector(17 downto 0);
        UDPDone             : in std_logic;
    
        MuxAddr0            : out std_logic;
        MuxAddr1            : out std_logic;
        MuxAddr2            : out std_logic;
        MuxAddr3_p          : out std_logic;
        MuxAddr3_n          : out std_logic;
        end_of_data         : out std_logic;
        fifo_bus            : out std_logic_vector(63 downto 0);
        data_fifo_enable    : out std_logic;
        packet_len          : out std_logic_vector(11 downto 0);
        xadc_busy           : out std_logic
    );
    end component;
    -- 17
    component AXI4_SPI
    port(
        clk_200                 : in  std_logic;
        clk_125                 : in  std_logic;
        clk_50                  : in  std_logic;
        
        myIP                    : out std_logic_vector(31 downto 0);
        myMAC                   : out std_logic_vector(47 downto 0);
        destIP                  : out std_logic_vector(31 downto 0);

        default_IP              : in std_logic_vector(31 downto 0);
        default_MAC             : in std_logic_vector(47 downto 0);
        default_destIP          : in std_logic_vector(31 downto 0);
        
        myIP_set                : in std_logic_vector(31 downto 0);
        myMAC_set               : in std_logic_vector(47 downto 0);
        destIP_set              : in std_logic_vector(31 downto 0);
        
        newip_start            : in std_logic;
        flash_busy             : out std_logic;
        
        io0_i : IN STD_LOGIC;
        io0_o : OUT STD_LOGIC;
        io0_t : OUT STD_LOGIC;
        io1_i : IN STD_LOGIC;
        io1_o : OUT STD_LOGIC;
        io1_t : OUT STD_LOGIC;
        ss_i : IN std_logic_vector(0 DOWNTO 0);
        ss_o : OUT std_logic_vector(0 DOWNTO 0);
        ss_t : OUT STD_LOGIC
    );
    end component;
    -- 18
    component CDCC
    generic(
        NUMBER_OF_BITS : integer := 8); -- number of signals to be synced
    port(
        clk_src     : in  std_logic;                                        -- input clk (source clock)
        clk_dst     : in  std_logic;                                        -- input clk (dest clock)
        data_in     : in  std_logic_vector(NUMBER_OF_BITS - 1 downto 0);    -- data to be synced
        data_out_s  : out std_logic_vector(NUMBER_OF_BITS - 1 downto 0)     -- synced data to clk_dst
    );
    end component;
    -- 19
    component vio_elink
      port(
        clk         : IN  STD_LOGIC;
        probe_in0   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in1   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out0  : OUT STD_LOGIC_VECTOR(10 DOWNTO 0)
      );
    end component;
    -- 20
    component clk_gen_wrapper
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_500             : in  std_logic;
        clk_160             : in  std_logic;
        clk_125             : in  std_logic;
        rst                 : in  std_logic;
        mmcm_locked         : in  std_logic;
        rst_enable          : in  std_logic;
        pf_busy             : in  std_logic;
        trint               : out std_logic;
        ------------------------------------
        ----- Configuration Interface ------
        ckbc_enable         : in  std_logic;
        cktp_enable         : in  std_logic;
        cktp_primary        : in  std_logic;
        cktp_pulse_width    : in  std_logic_vector(4 downto 0);
        cktp_max_num        : in  std_logic_vector(15 downto 0);
        cktp_period         : in  std_logic_vector(15 downto 0);
        rst_period          : in  std_logic_vector(15 downto 0);
        rst_before_cktp     : in  std_logic_vector(7 downto 0);
        cktp_skew           : in  std_logic_vector(4 downto 0);        
        ckbc_freq           : in  std_logic_vector(5 downto 0);
        ------------------------------------
        ---------- VMM Interface -----------
        CKTP                : out std_logic;
        CKBC                : out std_logic;
        RST_VMM             : out std_logic
    );
    end component;
    -- 21
    component vmm_oddr_wrapper
    Port(
        -------------------------------------------------------
        ckdt_bufg       : in  std_logic;
        ckdt_enable_vec : in  std_logic_vector(8 downto 1);
        ckdt_toBuf_vec  : out std_logic_vector(8 downto 1);
        -------------------------------------------------------
        ckbc_bufg       : in  std_logic;
        ckbc_enable     : in  std_logic;
        ckbc_toBuf_vec  : out std_logic_vector(8 downto 1);
        -------------------------------------------------------
        cktp_bufg       : in  std_logic;
        cktp_toBuf_vec  : out std_logic_vector(8 downto 1);
        -------------------------------------------------------
        ckart_bufg      : in  std_logic;
        ckart_toBuf_vec : out std_logic_vector(9 downto 1)
        -------------------------------------------------------
    );
    end component; 
    -- 22
    component elink_wrapper
    Generic(DataRate        : integer;  -- 80 / 160 / 320 MHz
            elinkEncoding   : std_logic_vector (1 downto 0)); -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding
    Port(
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
        elink_tx        : out std_logic;  -- elink tx bus
        elink_rx        : in  std_logic;  -- elink rx bus
        ---------------------------------
        --------- PF Interface ----------
        din_daq         : in  std_logic_vector(63 downto 0); -- data packets from packet formation
        din_last        : in  std_logic;                     -- last packet
        elink_busy      : out std_logic;                     -- elink is sending DAQ data
        wr_en_daq       : in  std_logic                      -- write enable from packet formation
        );
    end component;
    -- 23
    component mmcm_ttc
    port
    (   -- Clock in ports
        clk_in1_p       : in    std_logic;
        clk_in1_n       : in    std_logic;
        -- Clock out ports
        clk_out_320     : out   std_logic;
        clk_out_160     : out   std_logic;
        clk_out_80      : out   std_logic;
        clk_out_50      : out   std_logic;
        clk_out_40      : out   std_logic;
        clk_out_10_45   : out   std_logic;
        -- Status and control signals
        reset           : in    std_logic;
        locked          : out   std_logic
     );
    end component;
    -- 24
    component clk_wiz_board
    port
     (  -- Clock in ports
        clk_in1_p   : in  std_logic;
        clk_in1_n   : in  std_logic;
        -- Clock out ports
        clk_out_200 : out std_logic;
        -- Status and control signals
        reset       : in  std_logic;
        locked      : out std_logic
     );
    end component;
    -- 25
    COMPONENT vio_del
      PORT (
        clk         : IN  STD_LOGIC;
        probe_in0   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in1   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in2   : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        probe_out0  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out1  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out2  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out3  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out4  : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
      );
    END COMPONENT;

begin

    glbl_rstn        <= not glbl_rst_i;
    phy_int          <= '1';
    
gen_vector_reset: process (userclk2)
    begin
     if userclk2'event and userclk2 = '1' then
       if vector_reset_int = '1' then
         vector_pre_resetn  <= '0';
         vector_resetn      <= '0';
       else
         vector_pre_resetn  <= '1';
         vector_resetn      <= vector_pre_resetn;
       end if;
     end if;
    end process gen_vector_reset;

    mmcm_reset <= glbl_rst_i; -- reset;

   -----------------------------------------------------------------------------
   -- Transceiver PMA reset circuitry
   -----------------------------------------------------------------------------
   
   -- Create a reset pulse of a decent length
--   process(glbl_rst_i, clk_200)
--   begin
--     if (glbl_rst_i = '1') then
--       pma_reset_pipe <= "1111";
--     elsif clk_200'event and clk_200 = '1' then
--       pma_reset_pipe <= pma_reset_pipe(2 downto 0) & glbl_rst_i;
--     end if;
--   end process;

--   pma_reset <= pma_reset_pipe(3);

core_wrapper: gig_ethernet_pcs_pma_0
    port map (
      gtrefclk_p           => gtrefclk_p,
      gtrefclk_n           => gtrefclk_n,
      txp                  => txp,
      txn                  => txn,
      rxp                  => rxp,
      rxn                  => rxn,
      gtrefclk_out         => open,
      gtrefclk_bufg_out    => txoutclk,
      rxuserclk_out        => open,
      rxuserclk2_out       => open,
      resetdone            => resetdone,
      mmcm_locked_out      => mmcm_locked,
      userclk_out          => userclk,
      userclk2_out         => userclk2,
      independent_clock_bufg => clk_160_daq,
      pma_reset_out        => pma_reset,
      sgmii_clk_r          => sgmii_clk_r,
      sgmii_clk_f          => sgmii_clk_f,
      sgmii_clk_en         => clk_enable_int,
      gmii_txd             => gmii_txd_int,
      gmii_tx_en           => gmii_tx_en_int,
      gmii_tx_er           => gmii_tx_er_int,
      gmii_rxd             => gmii_rxd_int,
      gmii_rx_dv           => gmii_rx_dv_int,
      gmii_rx_er           => gmii_rx_er_int,
      gmii_isolate         => gmii_isolate,
      configuration_vector => "10000", -- configuration_vector,
      status_vector        => status_vector_int, -- status_vector_int,
      reset                => glbl_rst_i,
      signal_detect        => '1', -- signal_detect
      speed_is_10_100      => speed_is_10_100,
      speed_is_100         => speed_is_100,
      an_interrupt         => open,                    -- Interrupt to processor to signal that Auto-Negotiation has completed
      an_adv_config_vector =>  "1111111000000001",-- Alternate interface to program REG4 (AN ADV)
      an_restart_config    => an_restart_config_int,                     -- Alternate signal to modify AN restart bit in REG0

      gt0_pll0outclk_out     => open,
      gt0_pll0outrefclk_out  => open,
      gt0_pll1outclk_out     => open,
      gt0_pll1outrefclk_out  => open,
      gt0_pll0refclklost_out => open,
      gt0_pll0lock_out       => open);

    process(userclk2)
        begin
            if (local_gtx_reset = '1') then 
                an_restart_config_int <= '1';
            else
                an_restart_config_int <= '0';
            end if;
    end process;

tri_fifo: temac_10_100_1000_fifo_block
    port map(
      gtx_clk                    => userclk2, --sgmii_clk_int, --userclk2,
      -- asynchronous reset
      glbl_rstn                  => glbl_rstn,
      rx_axi_rstn                => '1',
      tx_axi_rstn                => '1',
      -- Receiver Statistics Interface
      -----------------------------------------
      rx_reset                   => rx_reset,
      rx_statistics_vector       => open,
      rx_statistics_valid        => open,
      -- Receiver (AXI-S) Interface
      ------------------------------------------
      rx_fifo_clock              => userclk2,
      rx_fifo_resetn             => gtx_resetn,
      rx_axis_fifo_tdata         => rx_axis_mac_tdata_int,
      rx_axis_fifo_tvalid        => rx_axis_mac_tvalid_int,
      rx_axis_fifo_tready        => rx_axis_mac_tready_int,
      rx_axis_fifo_tlast         => rx_axis_mac_tlast_int,
      -- Transmitter Statistics Interface
      --------------------------------------------
      tx_reset                   => tx_reset,
      tx_ifg_delay               => x"00",
      tx_statistics_vector       => open,
      tx_statistics_valid        => open,
      -- Transmitter (AXI-S) Interface
      ---------------------------------------------
      tx_fifo_clock              => userclk2,
      tx_fifo_resetn             => gtx_resetn,
      tx_axis_fifo_tdata         => tx_axis_mac_tdata_int,
      tx_axis_fifo_tvalid        => tx_axis_mac_tvalid_int,
      tx_axis_fifo_tready        => tx_axis_mac_tready_int,
      tx_axis_fifo_tlast         => tx_axis_mac_tlast_int,
      -- MAC Control Interface
      --------------------------
      pause_req                  => '0',
      pause_val                  => x"0000",
      -- GMII Interface
      -------------------
      gmii_txd                  => gmii_txd_emac,
      gmii_tx_en                => gmii_tx_en_emac,
      gmii_tx_er                => gmii_tx_er_emac,
      gmii_rxd                  => gmii_rxd_emac,
      gmii_rx_dv                => gmii_rx_dv_emac,
      gmii_rx_er                => gmii_rx_er_emac,
      clk_enable                => clk_enable_int,
      speedis100                => speed_is_100,
      speedis10100              => speed_is_10_100,
      -- Configuration Vector
      -------------------------
      rx_configuration_vector   => rx_configuration_vector_int, -- x"0605_0403_02da_0000_2022",
      tx_configuration_vector   => tx_configuration_vector_int);  -- x"0605_0403_02da_0000_2022"
    
    -- Control vector reset
axi_lite_reset_gen: temac_10_100_1000_reset_sync
   port map (
       clk                      => userclk2,
       enable                   => '1',
       reset_in                 => glbl_rst_i,
       reset_out                => vector_reset_int);   
        
config_vector: temac_10_100_1000_config_vector_sm
    port map(
      gtx_clk                   => userclk2, --sgmii_clk_int, --userclk2,
      gtx_resetn                => vector_resetn,    
      mac_speed                 => status_vector_int(11 downto 10), -- "10",
      update_speed              => '1',    
      rx_configuration_vector   => rx_configuration_vector_int,
      tx_configuration_vector   => tx_configuration_vector_int);

   -----------------------------------------------------------------------------
   -- GMII transmitter data logic
   -----------------------------------------------------------------------------

   -- Drive input GMII signals through IOB input flip-flops (inferred).
    process (userclk2)
    begin
      if userclk2'event and userclk2 = '1' then
         gmii_txd_int    <= gmii_txd_emac;
         gmii_tx_en_int  <= gmii_tx_en_emac;
         gmii_tx_er_int  <= gmii_tx_er_emac;
      end if;
    end process;
        
    local_gtx_reset <= glbl_rst_i or rx_reset or tx_reset;
    
gtx_reset_gen: temac_10_100_1000_reset_sync
    port map (
       clk              => userclk2,
       enable           => '1',
       reset_in         => local_gtx_reset,
       reset_out        => gtx_clk_reset_int);

gen_gtx_reset: process (userclk2)
   begin
     if userclk2'event and userclk2 = '1' then
       if gtx_clk_reset_int = '1' then
         gtx_pre_resetn   <= '0';
         gtx_resetn       <= '0';
       else
         gtx_pre_resetn   <= '1';
         gtx_resetn       <= gtx_pre_resetn;
       end if;
     end if;
   end process gen_gtx_reset;

   -- Drive input GMII signals through IOB output flip-flops (inferred).
   process (userclk2)
   begin
      if userclk2'event and userclk2 = '1' then
         gmii_rxd_emac          <= gmii_rxd_int;
         gmii_rx_dv_emac        <= gmii_rx_dv_int;
         gmii_rx_er_emac        <= gmii_rx_er_int;
      end if;
   end process;

UDP_ICMP_block: UDP_ICMP_Complete_nomac
    Port map(
            udp_tx_start                => udp_tx_start_int,
            udp_txi                     => udp_txi_int, 
            udp_tx_result               => open,
            udp_tx_data_out_ready       => udp_tx_data_out_ready_int, 
            udp_rx_start                => open,
            udp_rxo                     => udp_rx_int,
            icmp_rx_start               => icmp_rx_start,
            icmp_rxo                    => icmp_rxo,
            ip_rx_hdr                   => ip_rx_hdr_int,   
            rx_clk                      => userclk2,
            tx_clk                      => userclk2,
            reset                       => glbl_rst_i,
            our_ip_address              => myIP,
            our_mac_address             => myMAC,
            control                     => control,
            arp_pkt_count               => open,
            ip_pkt_count                => open,
            mac_tx_tdata                => tx_axis_mac_tdata_int,
            mac_tx_tvalid               => tx_axis_mac_tvalid_int,
            mac_tx_tready               => tx_axis_mac_tready_int,
            mac_tx_tfirst               => open,
            mac_tx_tlast                => tx_axis_mac_tlast_int,
            mac_rx_tdata                => rx_axis_mac_tdata_int,
            mac_rx_tvalid               => rx_axis_mac_tvalid_int,
            mac_rx_tready               => rx_axis_mac_tready_int,
            mac_rx_tlast                => rx_axis_mac_tlast_int);

i2c_module: i2c_top
       port map(  clk_in                => clk_160_daq,
                  phy_rstn_out          => phy_rstn_out);

udp_din_conf_block: udp_data_in_handler
    port map(
        ------------------------------------
        ------- General Interface ----------
        clk_125             => userclk2,
        clk_40              => clk_40_daq,
        inhibit_conf        => inhibit_conf,
        rst                 => glbl_rst_i,
        ------------------------------------
        -------- FPGA Config Interface -----
        latency             => latency_conf,
        serial_number       => open,
        daq_on              => daq_on,
        ext_trigger         => trig_mode_int,
        ------------------------------------
        -------- UDP Interface -------------
        udp_rx              => udp_rx_int,
        ------------------------------------
        ---------- AXI4SPI Interface -------
        flash_busy          => flash_busy,
        newIP_rdy           => newIP_rdy,
        myIP_set            => myIP_set,
        myMAC_set           => myMAC_set,
        destIP_set          => destIP_set,
        ------------------------------------
        ------ VMM Config Interface --------
        vmm_bitmask         => vmm_bitmask,
        vmmConf_rdy         => vmm_id_rdy,
        vmmConf_done        => vmmConf_done,
        vmm_cktk            => vmm_cktk_conf,
        vmm_cfg_bit         => vmm_di_all,
        top_rdy             => start_conf_proc_int,
        ------------------------------------
        ---------- XADC Interface ----------
        xadc_busy           => xadc_busy,
        xadc_rdy            => xadc_conf_rdy,
        vmm_id_xadc         => vmm_id_xadc,
        xadc_sample_size    => xadc_sample_size,
        xadc_delay          => xadc_delay
    );

-- can be either used as DAQ path MMCM or as boardClk MMCM    
mmcm_master: master_clk
       port map ( 
      -- Clock out ports  
       clk_out_40       => clk_40_daq,
       clk_out_80       => clk_80_daq,
       clk_out_160      => clk_160_daq,
       clk_out_320      => clk_320_daq,
       clk_out_50       => clk_50_daq,
       clk_out_10_45    => clk_10_phase45_daq,
      -- Status and control signals                
       reset            => rst_elink_mmcm, -- used to be gnd
       locked           => clk_daq_locked,
       -- Clock in ports
       clk_in1_p        => ELINK_DAQ_CLK_P,
       clk_in1_n        => ELINK_DAQ_CLK_N
       );

event_timing_reset_instance: event_timing_reset
    port map(
        hp_clk          => '0',
        clk             => userclk2,
        clk_10_phase45  => clk_10_phase45_daq,
        bc_clk          => CKBC_glbl,

        daqEnable       => daq_enable_i,
        pfBusy          => pfBusy_i,
        reset           => rst_vmm,

        glBCID          => glBCID_i,
        prec_cnt        => open,

        state_rst_out   => state_rst_etr_i,
        rst_o           => rst_etr_i,
        rst_done_o      => rst_done_etr_i,

        vmm_ena_vec     => etr_vmm_ena_vec,
        vmm_wen_vec     => etr_vmm_wen_vec,
        reset_latched   => etr_reset_latched
    );

readout_vmm: vmm_readout
    port map(
        clkTkProc               => clk_10_phase45_daq,
        clkDtProc               => clk_50_daq,
        clk                     => userclk2,
        
        vmm_data0_vec           => data0_in_vec,
        vmm_data1_vec           => data1_in_vec,
        vmm_ckdt_vec            => ckdt_out_vec,
        vmm_cktk_vec            => vmm_cktk_vec_ro,
        cktk_max                => cktk_max_num,

        daq_enable              => daq_enable_i,
        trigger_pulse           => pf_trigVmmRo,
        vmmId                   => pf_vmmIdRo,
        ethernet_fifo_wr_en     => open,
        vmm_data_buf            => open,
        
        dt_state_o              => dt_state,
        dt_cntr_st_o            => dt_cntr_state,
        
        vmmWordReady            => vmmWordReady_i,
        vmmWord                 => vmmWord_i,
        vmmEventDone            => vmmEventDone_i
    );

trigger_instance: trigger
    port map(
        clk             => userclk2,

        tren            => tren,                -- Trigger module enabled
        tr_hold         => tr_hold,             -- Prevents trigger while high
        trmode          => trig_mode_int,       -- Mode 0: internal / Mode 1: external
        trext           => ext_trigger_i,       -- External trigger is to be driven to this port
        trint           => trint,               -- Internal trigger is to be driven to this port (CKTP)

        reset           => tr_reset,

        event_counter   => event_counter_i,
        tr_out          => tr_out_i
    );

FIFO2UDP_instance: FIFO2UDP
    Port map( 
        clk_125                     => userclk2,
        destinationIP               => destIP,
        daq_data_in                 => daqFIFO_din_i,
        fifo_data_out               => open,
        udp_txi                     => udp_txi_int,    
        udp_tx_start                => udp_tx_start_int,
        control                     => control.ip_controls.arp_controls.clear_cache,
        UDPDone                     => UDPDone,   
        re_out                      => open,    
        udp_tx_data_out_ready       => udp_tx_data_out_ready_int,
        wr_en                       => daqFIFO_wr_en_i,
        end_packet                  => end_packet_i,
        global_reset                => glbl_rst_i,
        packet_length_in            => packet_length_int,
        reset_DAQ_FIFO              => daqFIFO_reset,

        vmmID                       => pf_vmmIdRo,
        
        trigger_out                 => trigger_i
    );       

packet_formation_instance: packet_formation
    port map(
        clk             => userclk2,
        
        newCycle        => pf_newCycle,
        
        trigVmmRo       => pf_trigVmmRo,
        vmmId           => pf_vmmIdRo,
        vmmWord         => vmmWord_i,
        vmmWordReady    => vmmWordReady_i,
        vmmEventDone    => vmmEventDone_i,
        
        UDPDone         => UDPDone,
        pfBusy          => pfBusy_i,
        glBCID          => glBCID_i,
        
        packLen         => pf_packLen,
        dataout         => daq_data_out_pf_i,
        wrenable        => daq_wr_en_pf_i,
        end_packet      => end_packet_daq_int,
        
        flush_elink     => flush_pf,
        elink_busy      => elink_busy,
        elink_daq       => daq_enable,
        
        tr_hold         => tr_hold,
        reset           => pf_reset,
        rst_vmm         => rst_vmm,
        resetting       => etr_reset_latched,
        rst_FIFO        => pf_rst_FIFO,
        dbg_state_o     => pf_state,

        latency         => latency_conf
        
        --trigger         => trigger_i
    );   
        
data_selection:  select_data
    port map(
        configuring                 => start_conf_proc_int,
        xadc                        => xadc_busy,
        data_acq                    => daq_enable_i,
        we_data                     => daq_wr_en_i,
        we_conf                     => we_conf_int,
        we_xadc                     => xadc_fifo_enable,
        daq_data_in                 => daq_data_out_i,
        conf_data_in                => user_data_out_i,
        xadc_data_in                => xadc_fifo_bus,
        data_packet_length          => pf_packLen,
        xadc_packet_length          => xadc_packet_len,
        end_packet_conf             => end_packet_conf_int,
        end_packet_daq              => end_packet_daq_int,
        end_packet_xadc             => xadc_end_of_data,
        fifo_rst_daq                => pf_rst_FIFO,
        fifo_rst_xadc               => '0',
        rstFIFO_top                 => rstFIFO_top,

        data_out                    => daqFIFO_din_i,
        packet_length               => packet_length_int,
        we                          => daqFIFO_wr_en_i,
        end_packet                  => end_packet_i,
        fifo_rst                    => daqFIFO_reset
    );

xadc_instance: xadcModule
    port map(
        clk125                      => userclk2,
        rst                         => '0', -- change this plz
        
        VP_0                        => VP_0,
        VN_0                        => VN_0,
        Vaux0_v_n                   => Vaux0_v_n,
        Vaux0_v_p                   => Vaux0_v_p,
        Vaux1_v_n                   => Vaux1_v_n,
        Vaux1_v_p                   => Vaux1_v_p,
        Vaux2_v_n                   => Vaux2_v_n,
        Vaux2_v_p                   => Vaux2_v_p,
        Vaux3_v_n                   => Vaux3_v_n,
        Vaux3_v_p                   => Vaux3_v_p,
        Vaux8_v_n                   => Vaux8_v_n,
        Vaux8_v_p                   => Vaux8_v_p,
        Vaux9_v_n                   => Vaux9_v_n,
        Vaux9_v_p                   => Vaux9_v_p,
        Vaux10_v_n                  => Vaux10_v_n,
        Vaux10_v_p                  => Vaux10_v_p,
        Vaux11_v_n                  => Vaux11_v_n,
        Vaux11_v_p                  => Vaux11_v_p,
        data_in_rdy                 => xadc_start,
        vmm_id                      => vmm_id_xadc,
        sample_size                 => xadc_sample_size,
        delay_in                    => xadc_delay,
        UDPDone                     => UDPDone,
    
        MuxAddr0                    => MuxAddr0_i,
        MuxAddr1                    => MuxAddr1_i,
        MuxAddr2                    => MuxAddr2_i,
        MuxAddr3_p                  => MuxAddr3_p_i,
        MuxAddr3_n                  => MuxAddr3_n_i,
        end_of_data                 => xadc_end_of_data,
        fifo_bus                    => xadc_fifo_bus,
        data_fifo_enable            => xadc_fifo_enable,
        packet_len                  => xadc_packet_len,
        xadc_busy                   => xadc_busy          -- synced to 125 Mhz
    );

axi4_spi_instance: AXI4_SPI  
    port map(
        clk_200                => '0',
        clk_125                => userclk2,
        clk_50                 => clk_50_daq,
        
        myIP                   => myIP,             -- synced to 125 Mhz
        myMAC                  => myMAC,            -- synced to 125 Mhz
        destIP                 => destIP,           -- synced to 125 Mhz

        default_IP             => default_IP,
        default_MAC            => default_MAC,
        default_destIP         => default_destIP,
        
        myIP_set               => myIP_set,         -- synced internally to 50 Mhz
        myMAC_set              => myMAC_set,        -- synced internally to 50 Mhz
        destIP_set             => destIP_set,       -- synced internally to 50 Mhz

        newip_start            => newIP_start,      -- synced internally to 50 Mhz
        flash_busy             => flash_busy,       -- synced to 125 Mhz

        io0_i                  => io0_i,
        io0_o                  => io0_o,
        io0_t                  => io0_t,
        io1_i                  => io1_i,
        io1_o                  => io1_o,
        io1_t                  => io1_t,
        ss_i                   => ss_i,
        ss_o                   => ss_o,
        ss_t                   => ss_t
        --SPI_CLK                => 
    );

ckbc_cktp_generator: clk_gen_wrapper
    port map(
        ------------------------------------
        ------- General Interface ----------
        clk_500             => clk_320_daq,
        clk_160             => clk_160_daq,
        clk_125             => userclk2,    
        rst                 => rst_gen,
        mmcm_locked         => clk_daq_locked,
        rst_enable          => rst_enable,
        pf_busy             => pfBusy_i,
        trint               => trint,
        ------------------------------------
        ----- Configuration Interface ------
        ckbc_enable         => ckbc_enable,
        cktp_enable         => cktp_enable,
        cktp_primary        => '0',
        cktp_pulse_width    => cktp_pulse_width(4 downto 0),
        cktp_max_num        => cktp_max_num,
        cktp_period         => cktp_period,
        rst_period          => rst_period,
        rst_before_cktp     => rst_before_cktp,
        cktp_skew           => cktp_skew(4 downto 0),
        ckbc_freq           => ckbc_freq(5 downto 0),
        ------------------------------------
        ---------- VMM Interface -----------
        CKTP                => CKTP_glbl,
        CKBC                => CKBC_glbl,
        RST_VMM             => open
    );

QSPI_IO0_0: IOBUF    
   port map (
      O  => io0_i,
      IO => IO0_IO,
      I  => io0_o,
      T  => io0_t
   );
           
QSPI_IO1_0: IOBUF    
   port map (
      O  => io1_i,
      IO => IO1_IO,
      I  => io1_o,
      T  => io1_t
   );
    
QSPI_SS_0: IOBUF     
   port map (
      O  => ss_i(0),
      IO => SS_IO,
      I  => ss_o(0),
      T  => ss_t
   );
   
vmm_oddr_inst: vmm_oddr_wrapper
   port map(
       -------------------------------------------------------
       ckdt_bufg       => '0', -- unused
       ckdt_enable_vec => (others => '0'),
       ckdt_toBuf_vec  => open,
       -------------------------------------------------------
       ckbc_bufg       => CKBC_glbl,
       ckbc_enable     => ckbc_enable,
       ckbc_toBuf_vec  => vmm_ckbc_vec,
       -------------------------------------------------------
       cktp_bufg       => CKTP_glbl,
       cktp_toBuf_vec  => vmm_cktp_vec,
       -------------------------------------------------------
       ckart_bufg      => clk_160_daq,
       ckart_toBuf_vec => ckart_vec
       -------------------------------------------------------
   );

-- DAQ path E-link
DAQ_ELINK: elink_wrapper
    generic map(DataRate      => 80,
                elinkEncoding => "01") --8b/10b encoding
    port map(
        ---------------------------------
        ----- General/VIO Interface -----
        user_clock      => userclk2,
        pattern_ena     => pattern_enable,  -- pattern data enabled by default, from VIO
        daq_ena         => daq_enable,      -- from VIO
        loopback_ena    => loopback_enable, -- from VIO
        glbl_rst        => rst_elink_glbl,  -- from VIO
        rst_tx          => rst_tx_final,    -- from VIO and PF
        rst_rx          => rst_elink_rx,    -- from VIO
        swap_tx         => swap_tx,         -- from VIO
        swap_rx         => swap_rx,         -- from VIO
        ttc_detected    => open,
        ---------------------------------
        -------- E-link clocking --------
        clk_40          => clk_40_daq,
        clk_80          => clk_80_daq,
        clk_160         => clk_160_daq,
        clk_320         => clk_320_daq,
        elink_locked    => clk_daq_locked,
        ---------------------------------
        ---- E-link Serial Interface ----
        elink_tx        => elink_DAQ_tx,
        elink_rx        => elink_DAQ_rx,
        ---------------------------------
        --------- PF Interface ----------
        din_daq         => daq_data_elink_i,    -- from DAQelinkMUX
        wr_en_daq       => daq_wr_en_elink_i,   -- from DAQelinkMUX
        din_last        => end_packet_daq_int,
        elink_busy      => elink_busy

    );

-- TTC path e-link
--TTC_ELINK: elink_wrapper
--    generic map(DataRate      => 80,
--                elinkEncoding => "00")
--    port map(
--        ---------------------------------
--        ----- General/VIO Interface -----
--        user_clock      => userclk2,
--        pattern_ena     => '0',
--        daq_ena         => '0',
--        loopback_ena    => '0',
--        glbl_rst        => rst_elink_glbl,
--        rst_tx          => '0',
--        rst_rx          => rst_elink_rx,
--        swap_tx         => '0',
--        swap_rx         => swap_rx,
--        ttc_detected    => ttc_detected,
--        ---------------------------------
--        -------- E-link clocking --------
--        clk_40          => clk_40_ttc,
--        clk_80          => clk_80_ttc,
--        clk_160         => clk_160_ttc,
--        clk_320         => clk_320_ttc,
--        elink_locked    => clk_ttc_locked,
--        ---------------------------------
--        ---- E-link Serial Interface ----
--        elink_tx        => '0',
--        elink_rx        => elink_TTC_rx,
--        ---------------------------------
--        --------- PF Interface ----------
--        din_daq         => (others => '0'),
--        wr_en_daq       => '0'
--        );

--mmcm_ttc_inst: mmcm_ttc
--   port map ( 
--  -- Clock out ports  
--   clk_out_320      => clk_320_ttc,
--   clk_out_160      => clk_160_ttc,
--   clk_out_80       => clk_80_ttc,
--   clk_out_50       => clk_50_ttc,
--   clk_out_40       => clk_40_ttc,
--   clk_out_10_45    => clk_10_phase45_ttc,
--  -- Status and control signals                
--   reset => rst_elink_mmcm,
--   locked => clk_ttc_locked,
--   -- Clock in ports
--   clk_in1_p => ELINK_TTC_CLK_P,
--   clk_in1_n => ELINK_TTC_CLK_N
--   );

mmcm_board: clk_wiz_board
   port map ( 
  -- Clock out ports  
   clk_out_200 => clk_200_i,
  -- Status and control signals                
   reset => '0',
   locked => mmcm_delay_locked,
   -- Clock in ports
   clk_in1_p => X_2V5_DIFF_CLK_P,
   clk_in1_n => X_2V5_DIFF_CLK_N
 );

vio_elink_instance: vio_elink
    PORT MAP(
        clk             => userclk2,
        probe_in0(0)    => clk_daq_locked,
        probe_in1(0)    => clk_ttc_locked,
        probe_out0(0)   => pattern_enable,
        probe_out0(1)   => daq_enable,
        probe_out0(2)   => loopback_enable,
        probe_out0(3)   => rst_elink_glbl,
        probe_out0(4)   => rst_elink_mmcm,
        probe_out0(5)   => rst_elink_tx,
        probe_out0(6)   => rst_elink_rx,
        probe_out0(7)   => swap_rx,
        probe_out0(8)   => swap_tx,
        probe_out0(9)   => selDAQelinkUDP(0),
        probe_out0(10)  => selDAQelinkUDP(1)
        );
        
--vio_idelay : vio_del
--    PORT MAP (
--        clk             => clk_200_i,
--        probe_in0(0)    => rdy_all,
--        probe_in1(0)    => mmcm_delay_locked,
--        probe_in2       => cnt_delay,
--        probe_out0(0)   => tap_increase,
--        probe_out1(0)   => tap_decrease,
--        probe_out2(0)   => tap_rst,
--        probe_out3(0)   => ctrl_rst,
--        probe_out4(0)   => sel_tx
--    );

DAQelinkUDPdemux_proc: process(selDAQelinkUDP, daq_data_out_pf_i, daq_wr_en_pf_i)
begin
    case selDAQelinkUDP is
    when "00" => -- disable data
        daq_data_out_i      <= (others => '0');
        daq_wr_en_i         <= '0';
        daq_data_elink_i    <= (others => '0');
        daq_wr_en_elink_i   <= '0';
    when "01" => -- DAQ data only through UDP (default)
        daq_data_out_i      <= daq_data_out_pf_i;
        daq_wr_en_i         <= daq_wr_en_pf_i;
        daq_data_elink_i    <= (others => '0');
        daq_wr_en_elink_i   <= '0';
    when "10" => -- DAQ data only through E-LINK
        daq_data_out_i      <= (others => '0');
        daq_wr_en_i         <= '0';
        daq_data_elink_i    <= daq_data_out_pf_i;
        daq_wr_en_elink_i   <= daq_wr_en_pf_i;
    when "11" => -- DAQ data through both UDP+E-ELINK
        daq_data_out_i      <= daq_data_out_pf_i;
        daq_wr_en_i         <= daq_wr_en_pf_i;
        daq_data_elink_i    <= daq_data_out_pf_i;
        daq_wr_en_elink_i   <= daq_wr_en_pf_i;
    when others => 
        daq_data_out_i      <= (others => '0');
        daq_wr_en_i         <= '0';
        daq_data_elink_i    <= (others => '0');
        daq_wr_en_elink_i   <= '0';
    end case;
end process;

---------------------------- E-LINK BUFFERS -----------------------------------------------------------------------
elink_tx_daq_buf: OBUFDS generic map  (IOSTANDARD => "DEFAULT" , SLEW => "FAST")
                         port map     (O =>  ELINK_DAQ_TX_P, OB => ELINK_DAQ_TX_N, I =>  elink_DAQ_tx);
elink_rx_daq_buf: IBUFDS generic map  (IOSTANDARD => "DEFAULT", IBUF_LOW_PWR => FALSE, DIFF_TERM => TRUE)
                         port map     (O =>  elink_DAQ_rx, I =>  ELINK_DAQ_RX_P, IB => ELINK_DAQ_RX_N);    
--elink_rx_ttc_buf: IBUFDS generic map  (IOSTANDARD => "DEFAULT" , DIFF_TERM => TRUE)
--                         port map     (O =>  elink_TTC_rx, I =>  ELINK_TTC_RX_P, IB => ELINK_TTC_RX_N);
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

----------------------------------------------------DI-------------------------------------------------------------
sdi_obufds_1:  OBUFDS  port map  (O =>  DI_1_P, OB => DI_1_N, I => vmm_di_vec_obuf(1));
sdi_obufds_2:  OBUFDS  port map  (O =>  DI_2_P, OB => DI_2_N, I => vmm_di_vec_obuf(2));
sdi_obufds_3:  OBUFDS  port map  (O =>  DI_3_P, OB => DI_3_N, I => vmm_di_vec_obuf(3));
sdi_obufds_4:  OBUFDS  port map  (O =>  DI_4_P, OB => DI_4_N, I => vmm_di_vec_obuf(4));
sdi_obufds_5:  OBUFDS  port map  (O =>  DI_5_P, OB => DI_5_N, I => vmm_di_vec_obuf(5));
sdi_obufds_6:  OBUFDS  port map  (O =>  DI_6_P, OB => DI_6_N, I => vmm_di_vec_obuf(6));
sdi_obufds_7:  OBUFDS  port map  (O =>  DI_7_P, OB => DI_7_N, I => vmm_di_vec_obuf(7));
sdi_obufds_8:  OBUFDS  port map  (O =>  DI_8_P, OB => DI_8_N, I => vmm_di_vec_obuf(8));

----------------------------------------------------DO-------------------------------------------------------------
sdo_diff_1: IBUFDS port map (O => vmm_do_vec_ibuf(1), I => DO_1_P, IB => DO_1_N);
sdo_diff_2: IBUFDS port map (O => vmm_do_vec_ibuf(2), I => DO_2_P, IB => DO_2_N);
sdo_diff_3: IBUFDS port map (O => vmm_do_vec_ibuf(3), I => DO_3_P, IB => DO_3_N);
sdo_diff_4: IBUFDS port map (O => vmm_do_vec_ibuf(4), I => DO_4_P, IB => DO_4_N);
sdo_diff_5: IBUFDS port map (O => vmm_do_vec_ibuf(5), I => DO_5_P, IB => DO_5_N);
sdo_diff_6: IBUFDS port map (O => vmm_do_vec_ibuf(6), I => DO_6_P, IB => DO_6_N);
sdo_diff_7: IBUFDS port map (O => vmm_do_vec_ibuf(7), I => DO_7_P, IB => DO_7_N);
sdo_diff_8: IBUFDS port map (O => vmm_do_vec_ibuf(8), I => DO_8_P, IB => DO_8_N);

---------------------------------------------------SETT/SETB/TKI/TKO---------------------------------------------------
sett_obuf:   OBUFDS port map (O => SETT_P,   OB => SETT_N,   I => tied_to_gnd_i);    
setb_obuf:   OBUFDS port map (O => SETB_P,   OB => SETB_N,   I => tied_to_gnd_i);
TKI_diff_1:  OBUFDS port map (O =>  TKI_P,   OB => TKI_N,    I => tied_to_gnd_i);
TKO_diff_1:  IBUFDS port map (O =>  tko_i,   I => TKO_P, IB => TKO_N);

----------------------------------------------------ENA------------------------------------------------------------
ena_diff_1: OBUFDS port map ( O =>  ENA_1_P, OB => ENA_1_N, I => vmm_ena_vec(1));    
ena_diff_2: OBUFDS port map ( O =>  ENA_2_P, OB => ENA_2_N, I => vmm_ena_vec(2));
ena_diff_3: OBUFDS port map ( O =>  ENA_3_P, OB => ENA_3_N, I => vmm_ena_vec(3));
ena_diff_4: OBUFDS port map ( O =>  ENA_4_P, OB => ENA_4_N, I => vmm_ena_vec(4));
ena_diff_5: OBUFDS port map ( O =>  ENA_5_P, OB => ENA_5_N, I => vmm_ena_vec(5));
ena_diff_6: OBUFDS port map ( O =>  ENA_6_P, OB => ENA_6_N, I => vmm_ena_vec(6));
ena_diff_7: OBUFDS port map ( O =>  ENA_7_P, OB => ENA_7_N, I => vmm_ena_vec(7));
ena_diff_8: OBUFDS port map ( O =>  ENA_8_P, OB => ENA_8_N, I => vmm_ena_vec(8));

----------------------------------------------------WEN------------------------------------------------------------
wen_diff_1: OBUFDS port map ( O =>  WEN_1_P, OB => WEN_1_N, I => vmm_wen_vec(1));    
wen_diff_2: OBUFDS port map ( O =>  WEN_2_P, OB => WEN_2_N, I => vmm_wen_vec(2));
wen_diff_3: OBUFDS port map ( O =>  WEN_3_P, OB => WEN_3_N, I => vmm_wen_vec(3));
wen_diff_4: OBUFDS port map ( O =>  WEN_4_P, OB => WEN_4_N, I => vmm_wen_vec(4));
wen_diff_5: OBUFDS port map ( O =>  WEN_5_P, OB => WEN_5_N, I => vmm_wen_vec(5));
wen_diff_6: OBUFDS port map ( O =>  WEN_6_P, OB => WEN_6_N, I => vmm_wen_vec(6));
wen_diff_7: OBUFDS port map ( O =>  WEN_7_P, OB => WEN_7_N, I => vmm_wen_vec(7));
wen_diff_8: OBUFDS port map ( O =>  WEN_8_P, OB => WEN_8_N, I => vmm_wen_vec(8));

----------------------------------------------------CKBC------------------------------------------------------------
ckbc_diff_1: OBUFDS port map ( O =>  CKBC_1_P, OB => CKBC_1_N, I => vmm_ckbc_vec(1));
ckbc_diff_2: OBUFDS port map ( O =>  CKBC_2_P, OB => CKBC_2_N, I => vmm_ckbc_vec(2));
ckbc_diff_3: OBUFDS port map ( O =>  CKBC_3_P, OB => CKBC_3_N, I => vmm_ckbc_vec(3));
ckbc_diff_4: OBUFDS port map ( O =>  CKBC_4_P, OB => CKBC_4_N, I => vmm_ckbc_vec(4));
ckbc_diff_5: OBUFDS port map ( O =>  CKBC_5_P, OB => CKBC_5_N, I => vmm_ckbc_vec(5));
ckbc_diff_6: OBUFDS port map ( O =>  CKBC_6_P, OB => CKBC_6_N, I => vmm_ckbc_vec(6));
ckbc_diff_7: OBUFDS port map ( O =>  CKBC_7_P, OB => CKBC_7_N, I => vmm_ckbc_vec(7));
ckbc_diff_8: OBUFDS port map ( O =>  CKBC_8_P, OB => CKBC_8_N, I => vmm_ckbc_vec(8));

----------------------------------------------------CKTP------------------------------------------------------------
cktp_diff_1: OBUFDS port map ( O =>  CKTP_1_P, OB => CKTP_1_N, I => vmm_cktp_vec(1));
cktp_diff_2: OBUFDS port map ( O =>  CKTP_2_P, OB => CKTP_2_N, I => vmm_cktp_vec(2));
cktp_diff_3: OBUFDS port map ( O =>  CKTP_3_P, OB => CKTP_3_N, I => vmm_cktp_vec(3));
cktp_diff_4: OBUFDS port map ( O =>  CKTP_4_P, OB => CKTP_4_N, I => vmm_cktp_vec(4));
cktp_diff_5: OBUFDS port map ( O =>  CKTP_5_P, OB => CKTP_5_N, I => vmm_cktp_vec(5));
cktp_diff_6: OBUFDS port map ( O =>  CKTP_6_P, OB => CKTP_6_N, I => vmm_cktp_vec(6));
cktp_diff_7: OBUFDS port map ( O =>  CKTP_7_P, OB => CKTP_7_N, I => vmm_cktp_vec(7));
cktp_diff_8: OBUFDS port map ( O =>  CKTP_8_P, OB => CKTP_8_N, I => vmm_cktp_vec(8));

----------------------------------------------------CKTK--------------------------------------------------------------
cktk_diff_1: OBUFDS port map ( O =>  CKTK_1_P, OB => CKTK_1_N, I => vmm_cktk_vec(1));
cktk_diff_2: OBUFDS port map ( O =>  CKTK_2_P, OB => CKTK_2_N, I => vmm_cktk_vec(2));
cktk_diff_3: OBUFDS port map ( O =>  CKTK_3_P, OB => CKTK_3_N, I => vmm_cktk_vec(3));
cktk_diff_4: OBUFDS port map ( O =>  CKTK_4_P, OB => CKTK_4_N, I => vmm_cktk_vec(4));
cktk_diff_5: OBUFDS port map ( O =>  CKTK_5_P, OB => CKTK_5_N, I => vmm_cktk_vec(5));
cktk_diff_6: OBUFDS port map ( O =>  CKTK_6_P, OB => CKTK_6_N, I => vmm_cktk_vec(6));
cktk_diff_7: OBUFDS port map ( O =>  CKTK_7_P, OB => CKTK_7_N, I => vmm_cktk_vec(7));
cktk_diff_8: OBUFDS port map ( O =>  CKTK_8_P, OB => CKTK_8_N, I => vmm_cktk_vec(8));
    
----------------------------------------------------CKDT--------------------------------------------------------------
ckdt_diff_1: OBUFDS port map ( O => ckdt_1_P, OB => ckdt_1_N, I => ckdt_out_vec(1));
ckdt_diff_2: OBUFDS port map ( O => ckdt_2_P, OB => ckdt_2_N, I => ckdt_out_vec(2));
ckdt_diff_3: OBUFDS port map ( O => ckdt_3_P, OB => ckdt_3_N, I => ckdt_out_vec(3));
ckdt_diff_4: OBUFDS port map ( O => ckdt_4_P, OB => ckdt_4_N, I => ckdt_out_vec(4));
ckdt_diff_5: OBUFDS port map ( O => ckdt_5_P, OB => ckdt_5_N, I => ckdt_out_vec(5));
ckdt_diff_6: OBUFDS port map ( O => ckdt_6_P, OB => ckdt_6_N, I => ckdt_out_vec(6));
ckdt_diff_7: OBUFDS port map ( O => ckdt_7_P, OB => ckdt_7_N, I => ckdt_out_vec(7));
ckdt_diff_8: OBUFDS port map ( O => ckdt_8_P, OB => ckdt_8_N, I => ckdt_out_vec(8));                                               

----------------------------------------------------DATA 0--------------------------------------------------------------
data0_diff_1: IBUFDS port map ( O => data0_in_vec(1), I => DATA0_1_P, IB => DATA0_1_N);
data0_diff_2: IBUFDS port map ( O => data0_in_vec(2), I => DATA0_2_P, IB => DATA0_2_N);
data0_diff_3: IBUFDS port map ( O => data0_in_vec(3), I => DATA0_3_P, IB => DATA0_3_N);
data0_diff_4: IBUFDS port map ( O => data0_in_vec(4), I => DATA0_4_P, IB => DATA0_4_N);
data0_diff_5: IBUFDS port map ( O => data0_in_vec(5), I => DATA0_5_P, IB => DATA0_5_N);
data0_diff_6: IBUFDS port map ( O => data0_in_vec(6), I => DATA0_6_P, IB => DATA0_6_N);
data0_diff_7: IBUFDS port map ( O => data0_in_vec(7), I => DATA0_7_P, IB => DATA0_7_N);
data0_diff_8: IBUFDS port map ( O => data0_in_vec(8), I => DATA0_8_P, IB => DATA0_8_N);
    
----------------------------------------------------DATA 1--------------------------------------------------------------
data1_diff_1: IBUFDS port map ( O => data1_in_vec(1), I => DATA1_1_P, IB => DATA1_1_N);
data1_diff_2: IBUFDS port map ( O => data1_in_vec(2), I => DATA1_2_P, IB => DATA1_2_N);
data1_diff_3: IBUFDS port map ( O => data1_in_vec(3), I => DATA1_3_P, IB => DATA1_3_N);
data1_diff_4: IBUFDS port map ( O => data1_in_vec(4), I => DATA1_4_P, IB => DATA1_4_N);
data1_diff_5: IBUFDS port map ( O => data1_in_vec(5), I => DATA1_5_P, IB => DATA1_5_N);
data1_diff_6: IBUFDS port map ( O => data1_in_vec(6), I => DATA1_6_P, IB => DATA1_6_N);
data1_diff_7: IBUFDS port map ( O => data1_in_vec(7), I => DATA1_7_P, IB => DATA1_7_N);
data1_diff_8: IBUFDS port map ( O => data1_in_vec(8), I => DATA1_8_P, IB => DATA1_8_N);

---------------------------------------------------CKART-----------------------------------------------------------------
ckart_diff_1: OBUFDS port map ( O => CKART_1_P, OB => CKART_1_N, I => ckart_vec(1));
ckart_diff_2: OBUFDS port map ( O => CKART_2_P, OB => CKART_2_N, I => ckart_vec(2));
ckart_diff_3: OBUFDS port map ( O => CKART_3_P, OB => CKART_3_N, I => ckart_vec(3));
ckart_diff_4: OBUFDS port map ( O => CKART_4_P, OB => CKART_4_N, I => ckart_vec(4));
ckart_diff_5: OBUFDS port map ( O => CKART_5_P, OB => CKART_5_N, I => ckart_vec(5));
ckart_diff_6: OBUFDS port map ( O => CKART_6_P, OB => CKART_6_N, I => ckart_vec(6));
ckart_diff_7: OBUFDS port map ( O => CKART_7_P, OB => CKART_7_N, I => ckart_vec(7));
ckart_diff_8: OBUFDS port map ( O => CKART_8_P, OB => CKART_8_N, I => ckart_vec(8));

ckart_addc_buf: OBUFDS port map ( O => CKART_ADDC_P, OB => CKART_ADDC_N, I => ckart_vec(9));

----------------------------------------------------XADC-----------------------------------------------------------------
xadc_mux0_obuf:   OBUF   port map  (O => MuxAddr0, I => MuxAddr0_i);
xadc_mux1_obuf:   OBUF   port map  (O => MuxAddr1, I => MuxAddr1_i);
xadc_mux2_obuf:   OBUF   port map  (O => MuxAddr2, I => MuxAddr2_i);
xadc_mux3_obufds: OBUFDS port map  (O => MuxAddr3_p, OB => MuxAddr3_n, I => MuxAddr3_p_i);

----------------------------------------------------TRIGGER--------------------------------------------------------------
ext_trg_diff_1:  IBUFDS port map (O =>  ext_trigger_i,   I => EXT_TRIGGER_P, IB => EXT_TRIGGER_N);

led_obuf:        OBUF   port map (O => LED_LOCKED, I => clk_daq_locked);
 
-------------------------------------------------------------------
--                        Processes                              --
-------------------------------------------------------------------
    -- 1. cktpSync_proc
    -- 2. internalTrigger_proc
    -- 3. synced_to_flowFSM
    -- 4. sel_cs
    -- 5. flow_fsm
-------------------------------------------------------------------

--###################### OLD CKTP ##################################
--syncingProc: process(clk_10_phase45)
--begin
--    if(rising_edge(clk_10_phase45))then
--        trig_mode_int_i <= trig_mode_int;
--        trig_mode_int_s <= trig_mode_int_i;
--        daq_is_on_i     <= daq_is_on;
--        daq_is_on_s     <= daq_is_on_i;
--    end if;    
--end process;

--internalTrigger_proc: process(clk_10_phase45) -- 10MHz/#states.
--    begin
--        if rising_edge(clk_10_phase45) then            
--            if daq_is_on_s = '1' and trig_mode_int_s = '0' then
--                case internalTrigger_state is
--                    when 0 to 9979 =>
--                        internalTrigger_state <= internalTrigger_state + 1;
--                        trint           <= '0';
--                    when 9980 to 10000 =>
--                        internalTrigger_state <= internalTrigger_state + 1;
--                        trint           <= '1';        
--                    when others =>
--                        internalTrigger_state <= 0;
--                end case;
--            else
--                trint           <= '0';
--                internalTrigger_state   <= 0;
--            end if;
--        end if;
--end process;

--testPulse_proc: process(clk_10_phase45) -- 10MHz/#states.
--    begin
--        if rising_edge(clk_10_phase45) then            
--            if daq_is_on_s = '1' and trig_mode_int_s = '0' then
--                case cktp_state is
--                    when 0 to 9979 =>
--                        cktp_state <= cktp_state + 1;
--                        vmm_cktp      <= '0';
--                    when 9980 to 10000 =>
--                        cktp_state <= cktp_state + 1;
--                        vmm_cktp   <= '1';
--                    when others =>
--                        cktp_state <= 0;
--                end case;
--            else
--                vmm_cktp      <= '0';
--                cktp_state    <= 0;
--            end if;
--        end if;
--end process;

--###############################################

-- sync CKTP to userclk2
--cktpSync_proc: process(userclk2)
--begin
--    if(rising_edge(userclk2))then
--        CKTP_i          <= CKTP_glbl;
--        CKTP_glbl_s125  <= CKTP_i;
--    end if;
--end process;

---- internal trigger process, uses a multiplication factor of 62 and creates an internal
---- trigger pulse of 400 ns width (b'110010' = 50)
--internalTrigger_proc: process(userclk2)
--begin
--    if(rising_edge(userclk2))then
--        if(CKTP_glbl_s125 = '1')then
--            trig_cnt <= trig_cnt + 1;
        
--            if(trig_cnt < unsigned(cktp_pulse_width)*"111110" - "110010")then
--                trint <= '0';
--            elsif(trig_cnt >= unsigned(cktp_pulse_width)*"111110" - "110010")then
--                trint <= '1';
--            else
--                trint <= '0';
--            end if;
--        else
--            trint       <= '0';
--            trig_cnt    <= (others => '0');
--        end if;
--    end if;
--end process;

-- master FSM
flow_fsm: process(userclk2)
    begin
    if rising_edge(userclk2) then
        if glbl_rst_i = '1' then
            state                <=    IDLE;
        elsif is_state = "0000" then
            state   <= IDLE;
        else
        
            case state is
                when IDLE =>
                    is_state                <= "1111";
                    
                    conf_wen_i              <= '0';
                    conf_ena_i              <= '0';
                    daq_sigs_enable         <= x"00";
                    we_conf_int             <= '0';
                    end_packet_conf_int     <= '0';
                    start_conf_proc_int     <= '0';
                    cnt_reply               <= 0;
                    
                    daq_enable_i            <= '0';
                    pf_reset                <= '0';
                    rstFIFO_top             <= '0';
                    tren                    <= '0';

                    if(vmm_id_rdy = '1')then
                        if(wait_cnt = "00000111")then -- wait for safe assertion of multi-bit signal
                            wait_cnt    <= (others => '0');
                            state       <= CONFIGURE;
                        else
                            wait_cnt    <= wait_cnt + 1;
                            state       <= IDLE;
                        end if;

                    elsif(newIP_rdy = '1')then -- start new IP setup
                        if(wait_cnt = "00001111")then -- wait for safe assertion of multi-bit signal
                            wait_cnt    <= (others => '0');
                            newIP_start <= '1';
                            state       <= FLASH_init;
                        else
                            wait_cnt    <= wait_cnt + 1;
                            newIP_start <= '0';
                            state       <= IDLE;
                        end if;

                    elsif(xadc_conf_rdy = '1')then -- start XADC
                        if(wait_cnt = "00000111")then -- wait for safe assertion of multi-bit signal
                            wait_cnt    <= (others => '0');
                            xadc_start  <= '1';
                            state       <= XADC_init;
                        else
                            wait_cnt    <= wait_cnt + 1;
                            xadc_start  <= '0';
                            state       <= IDLE;
                        end if;

                    elsif(daq_on = '1')then
                        state   <= DAQ_INIT;

                    else
                        state       <= IDLE;
                        wait_cnt    <= (others => '0');
                    end if;

               when CONFIGURE =>        
                    is_state        <= "0001";
                    if(vmmConf_done = '1')then 
                        state   <= CONF_DONE;
                    else
                        state   <= CONFIGURE;
                    end if;

                    start_conf_proc_int <= '1';
                    conf_wen_i          <= '1';

                when CONF_DONE =>
                    is_state        <= "0010";             
                    if(wait_cnt = "00000111")then -- wait before replying
                        wait_cnt    <= (others => '0');
                        state       <= SEND_CONF_REPLY;
                        we_conf_int <= '1';
                    else
                        wait_cnt    <= wait_cnt + 1;
                        state       <= CONF_DONE;
                    end if;
                    
                    conf_wen_i      <= '0';

                when SEND_CONF_REPLY =>
                    is_state            <= "1010";                    
                    if cnt_reply = 0 then
                        user_data_out_i     <= conf_data_out_i;
                        cnt_reply           <= cnt_reply + 1;
                    elsif cnt_reply = 1 then
                        user_data_out_i     <= (others => '0');
                        cnt_reply           <= cnt_reply + 1;
                        end_packet_conf_int <= '1';
                        we_conf_int         <= '0';
                    elsif cnt_reply > 1 and cnt_reply < 100 then
                        cnt_reply           <= cnt_reply + 1;
                        end_packet_conf_int <= '0';
                    else
                        cnt_reply           <= 0;
                        state               <= IDLE;
                    end if;

                when DAQ_INIT =>
                    is_state                <= "0011";
                    tren                    <= '0';
                    daq_sigs_enable         <= x"ff";
                    daq_enable_i            <= '1';
                    rstFIFO_top             <= '1';
                    pf_reset                <= '1';
                    state                   <= TRIG;
                    
                when TRIG =>
                    is_state            <= "0100";
                    rstFIFO_top         <= '0';
                    pf_reset            <= '0';
                    tren                <= '1';
                    state               <= DAQ;
      
                when DAQ =>
                    is_state    <= "0101";
                    if(daq_on = '0')then  -- Reset came
                        daq_enable_i            <= '0';
                        daq_sigs_enable         <= x"00";
                        state                   <= IDLE;
                    else
                        state                   <= DAQ;
                    end if;
                    
                when XADC_init =>
                    is_state            <= "0110";
                    if(xadc_busy = '1')then -- XADC got the message, wait for busy to go low
                        xadc_start  <= '0';
                        state       <= XADC_wait;
                    else                    -- XADC didn't get the message, wait and keep high
                        xadc_start  <= '1';
                        state       <= XADC_init; 
                    end if;

                when XADC_wait =>   -- wait for XADC to finish and go to IDLE
                    if(xadc_busy = '0')then
                        state <= IDLE;
                    else
                        state <= XADC_wait;
                    end if;

                when FLASH_init =>
                    if(flash_busy = '1')then -- AXI4SPI got the message, wait for busy to go low
                        newIP_start <= '0';
                        state       <= FLASH_wait;
                    else                     -- AXI4SPI didn't get the message, wait and keep high
                        newIP_start <= '1';
                        state       <= FLASH_init;
                    end if;

                when FLASH_wait =>  -- wait for AXI4SPI to finish and go to IDLE
                    if(flash_busy = '0')then
                        state   <= IDLE;
                    else
                        state   <= FLASH_wait;
                    end if;

                when others =>
                    state       <= IDLE;
                    is_state    <= "0110";
            end case;
        end if;
    end if;
end process;

    cktp_enable             <= '1' when ((state = DAQ and trig_mode_int = '0') or (state = XADC_wait and trig_mode_int = '0')) else '0';
    rst_enable              <= '1' when (state = DAQ and rst_enable_conf = '1') else '0';
    daq_is_on               <= '1' when state = DAQ else '0';
    inhibit_conf            <= '0' when (state = IDLE) else '1';
    ckbc_enable             <= '1';
    rst_tx_final            <= rst_elink_rx or flush_pf;
    
    pf_newCycle             <= tr_out_i;
    
    vmm_cktk_vec    <= conf_cktk_vec    or (vmm_cktk_vec_ro and daq_sigs_enable);
    vmm_ena_vec     <= conf_vmm_ena_vec or (etr_vmm_ena_vec and daq_sigs_enable);
    vmm_wen_vec     <= conf_vmm_wen_vec or (etr_vmm_wen_vec and daq_sigs_enable);

    -- configuration assertion   
    vmm_di_vec_obuf(1) <= vmm_di_all and vmm_bitmask(0);
    vmm_di_vec_obuf(2) <= vmm_di_all and vmm_bitmask(1);
    vmm_di_vec_obuf(3) <= vmm_di_all and vmm_bitmask(2);
    vmm_di_vec_obuf(4) <= vmm_di_all and vmm_bitmask(3);
    vmm_di_vec_obuf(5) <= vmm_di_all and vmm_bitmask(4);
    vmm_di_vec_obuf(6) <= vmm_di_all and vmm_bitmask(5);
    vmm_di_vec_obuf(7) <= vmm_di_all and vmm_bitmask(6);
    vmm_di_vec_obuf(8) <= vmm_di_all and vmm_bitmask(7);
    
    conf_vmm_ena_vec(1) <= conf_ena_i and vmm_bitmask(0);
    conf_vmm_ena_vec(2) <= conf_ena_i and vmm_bitmask(1);
    conf_vmm_ena_vec(3) <= conf_ena_i and vmm_bitmask(2);
    conf_vmm_ena_vec(4) <= conf_ena_i and vmm_bitmask(3);
    conf_vmm_ena_vec(5) <= conf_ena_i and vmm_bitmask(4);
    conf_vmm_ena_vec(6) <= conf_ena_i and vmm_bitmask(5);
    conf_vmm_ena_vec(7) <= conf_ena_i and vmm_bitmask(6);
    conf_vmm_ena_vec(8) <= conf_ena_i and vmm_bitmask(7);
    
    conf_vmm_wen_vec(1) <= conf_wen_i and vmm_bitmask(0);
    conf_vmm_wen_vec(2) <= conf_wen_i and vmm_bitmask(1);
    conf_vmm_wen_vec(3) <= conf_wen_i and vmm_bitmask(2);
    conf_vmm_wen_vec(4) <= conf_wen_i and vmm_bitmask(3);
    conf_vmm_wen_vec(5) <= conf_wen_i and vmm_bitmask(4);
    conf_vmm_wen_vec(6) <= conf_wen_i and vmm_bitmask(5);
    conf_vmm_wen_vec(7) <= conf_wen_i and vmm_bitmask(6);
    conf_vmm_wen_vec(8) <= conf_wen_i and vmm_bitmask(7);
    
    conf_cktk_vec(1) <= vmm_cktk_conf and vmm_bitmask(0);
    conf_cktk_vec(2) <= vmm_cktk_conf and vmm_bitmask(1);
    conf_cktk_vec(3) <= vmm_cktk_conf and vmm_bitmask(2);
    conf_cktk_vec(4) <= vmm_cktk_conf and vmm_bitmask(3);
    conf_cktk_vec(5) <= vmm_cktk_conf and vmm_bitmask(4);
    conf_cktk_vec(6) <= vmm_cktk_conf and vmm_bitmask(5);
    conf_cktk_vec(7) <= vmm_cktk_conf and vmm_bitmask(6);
    conf_cktk_vec(8) <= vmm_cktk_conf and vmm_bitmask(7);

    tied_to_gnd_i    <= '0'; -- ground CK6B/SETT/SETB (unused)      
      
--ila_top: ila_overview
--      PORT MAP (
--          clk                   => userclk2,
--          probe0(7 downto 0)    => conf_counter,
--          probe0(10 downto 8)   => conf_state,
--          probe0(14 downto 11)  => dt_state,
--          probe0(18 downto 15)  => dt_cntr_state,
--          probe0(23 downto 19)  => pf_state,
--          probe0(27 downto 24)  => is_state,
--          probe0(28)            => vmm_sdi_all,
--          probe0(29)            => conf_ena_i,
--          probe0(30)            => conf_wen_i,
--          probe0(31)            => vmm_cktk_conf,
--          probe0(32)            => vmm_cktk_vec_ro(1),
--          probe0(33)            => data0_in_vec(1),
--          probe0(34)            => data1_in_vec(1),
--          probe0(35)            => ckdt_out_vec(1),
--          probe0(36)            => vmm_cktk_vec_ro(2),
--          probe0(37)            => data0_in_vec(2),
--          probe0(38)            => data1_in_vec(2),
--          probe0(39)            => ckdt_out_vec(2),
--          probe0(40)            => CKTP_glbl_dbg,
--          probe0(41)            => CKBC_glbl_dbg,
--          probe0(42)            => conf_fifo_empty,
--          probe0(43)            => rd_conf_fifo,
--          probe0(44)            => sel_vmm_data,
--          probe0(63 downto 45)  => (others => '0')
                  
--      );
      
--ila_top: ila_top_level
--    port map (
--        clk     => userclk2,
--        probe0  => vmmSignalsProbe,
--        probe1  => triggerETRProbe,
--        probe2  => configurationProbe,
--        probe3  => readoutProbe,
--        probe4  => dataOutProbe,
--        probe5  => flowProbe
--    );

    vmmSignalsProbe(7 downto 0)        <= vmm_ena_vec;
    vmmSignalsProbe(15 downto 8)       <= cktk_out_vec;
    vmmSignalsProbe(23 downto 16)      <= ckdt_out_vec;
    vmmSignalsProbe(31 downto 24)      <= data0_in_vec;
    vmmSignalsProbe(32)                <= '0';
    vmmSignalsProbe(33)                <= ckdt_out_vec(1);
    vmmSignalsProbe(34)                <= data0_in_vec(1);
    vmmSignalsProbe(35)                <= data1_in_vec(1);
    vmmSignalsProbe(36)                <= '0';
    vmmSignalsProbe(37)                <= '0';
    vmmSignalsProbe(38)                <= '0';
    vmmSignalsProbe(39)                <= '0';
    vmmSignalsProbe(40)                <= tko_i;
    vmmSignalsProbe(41)                <= '0';
    vmmSignalsProbe(42)                <= '0';
    vmmSignalsProbe(43)                <= '0';
    vmmSignalsProbe(44)                <= '0';
    vmmSignalsProbe(63 downto 45)      <= (others => '0'); 

    triggerETRProbe(0)                <= trint;
    triggerETRProbe(1)                <= tren;
    triggerETRProbe(2)                <= tr_hold;
    triggerETRProbe(3)                <= ext_trigger_in;
    triggerETRProbe(4)                <= trig_mode_int;
    triggerETRProbe(7 downto 5)       <= state_rst_etr_i;
    triggerETRProbe(15 downto 8)      <= etr_vmm_ena_vec;
    triggerETRProbe(23 downto 16)     <= (others => '0');
    triggerETRProbe(24)               <= rst_etr_i;
    triggerETRProbe(25)               <= etr_reset_latched;
    triggerETRProbe(26)               <= trigger_i;
    triggerETRProbe(38 downto 27)     <= glBCID_i;
    triggerETRProbe(39)               <= '0';
    triggerETRProbe(40)               <= '0';
    triggerETRProbe(63 downto 41)     <= (others => '0'); 

    configurationProbe(0)                <= start_conf_proc_int;
    configurationProbe(1)                <= '0';
    configurationProbe(2)                <= '0';
    configurationProbe(18 downto 3)      <= (others => '0');
    configurationProbe(50 downto 19)     <= myIP;
    configurationProbe(63 downto 51)     <= (others => '0');

    readoutProbe(0)                <= pf_newCycle;
    readoutProbe(1)                <= pf_rst_FIFO;
    readoutProbe(4 downto 2)       <= pf_vmmIdRo;
    readoutProbe(5)                <= pfBusy_i;
    readoutProbe(6)                <= rst_vmm;
    readoutProbe(7)                <= daqFIFO_wr_en_i;
    readoutProbe(8)                <= daq_wr_en_i;
    readoutProbe(63 downto 9)      <= (others => '0');

    dataOutProbe(63 downto 0)      <= daq_data_out_i;

    flowProbe(3 downto 0)       <= is_state;
    flowProbe(7 downto 4)       <= (others => '0');
    flowProbe(11 downto 8)      <= (others => '0');
    flowProbe(12)               <= daq_enable_i;
    flowProbe(13)               <= xadc_busy;
    flowProbe(21 downto 14)     <= (others => '0');
    flowProbe(22)               <= daqFIFO_reset;
    flowProbe(23)               <= rstFIFO_top;
    flowProbe(24)               <= ckbc_enable;
    flowProbe(63 downto 25)     <= (others => '0');     

end Behavioral;
