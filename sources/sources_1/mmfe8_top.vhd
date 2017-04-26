-------------------------------------------------------------------------------------
-- Company: NTU ATHENS - BNL
-- Engineer: Paris Moschovakos, Panagiotis Gkountoumis & Christos Bakalis
-- 
-- Create Date: 16.3.2016
-- Design Name: VMM3 firmware
-- Module Name: mmfe8_top
-- Project Name: VMM3 firmware 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.4
--
-- Changelog:
-- 04.08.2016 Added the XADC Component and multiplexer to share fifo UDP Signals (Reid Pinkham)
-- 11.08.2016 Corrected the fifo resets to go through select_data (Reid Pinkham)
-- 16.09.2016 Added Dynamic IP configuration. (Lev Kurilenko)
-- 16.02.2017 Added new configuration component (udp_data_in_handler) (Christos Bakalis)
-- 27.02.2017 Changed main logic clock to 125MHz (Paris)
-- 10.03.2017 Added configurable CKTP/CKBC module. For the moment controlled by
-- a VIO. Added new internal_trigger process (Christos Bakalis)
-- 12.03.2017 Changed flow_fsm's primary cktp assertion to comply with cktp_gen
-- module. (Christos Bakalis)
-- 14.03.2017 Added register address/value configuration scheme. (Christos Bakalis)
-- 28.03.2017 Changes to accomodate to MMFE8 VMM3. (Christos Bakalis)
-- 31.03.2017 Adding 2 CKBC readout mode (Paris)
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
--        EXT_TRIGGER_P       : in std_logic;
--        EXT_TRIGGER_N       : in std_logic;
--        EXT_TRIG_IN         : in std_logic;

--        TRIGGER_LOOP_P      : out std_logic;
--        TRIGGER_LOOP_N      : out std_logic;

        -- 200.0359MHz from bank 14
        -------------------------------------
        X_2V5_DIFF_CLK_P      : IN STD_LOGIC;
        X_2V5_DIFF_CLK_N      : IN STD_LOGIC;

        -- Tranceiver Interface
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

        SDO_1                 : IN STD_LOGIC;
        SDO_2                 : IN STD_LOGIC;
        SDO_3                 : IN STD_LOGIC;
        SDO_4                 : IN STD_LOGIC;
        SDO_5                 : IN STD_LOGIC;
        SDO_6                 : IN STD_LOGIC;
        SDO_7                 : IN STD_LOGIC;
        SDO_8                 : IN STD_LOGIC;

        SDI_1                 : OUT STD_LOGIC;
        SDI_2                 : OUT STD_LOGIC;
        SDI_3                 : OUT STD_LOGIC;
        SDI_4                 : OUT STD_LOGIC;
        SDI_5                 : OUT STD_LOGIC;
        SDI_6                 : OUT STD_LOGIC;
        SDI_7                 : OUT STD_LOGIC;
        SDI_8                 : OUT STD_LOGIC;

        SCK_1                 : OUT STD_LOGIC;
        SCK_2                 : OUT STD_LOGIC;
        SCK_3                 : OUT STD_LOGIC;
        SCK_4                 : OUT STD_LOGIC;
        SCK_5                 : OUT STD_LOGIC;
        SCK_6                 : OUT STD_LOGIC;
        SCK_7                 : OUT STD_LOGIC;
        SCK_8                 : OUT STD_LOGIC;

        CS_1                  : OUT STD_LOGIC;
        CS_2                  : OUT STD_LOGIC;
        CS_3                  : OUT STD_LOGIC;
        CS_4                  : OUT STD_LOGIC;
        CS_5                  : OUT STD_LOGIC;
        CS_6                  : OUT STD_LOGIC;
        CS_7                  : OUT STD_LOGIC;
        CS_8                  : OUT STD_LOGIC;

        ENA_1_P, ENA_1_N      : OUT STD_LOGIC;
        ENA_2_P, ENA_2_N      : OUT STD_LOGIC;
        ENA_3_P, ENA_3_N      : OUT STD_LOGIC;
        ENA_4_P, ENA_4_N      : OUT STD_LOGIC;
        ENA_5_P, ENA_5_N      : OUT STD_LOGIC;
        ENA_6_P, ENA_6_N      : OUT STD_LOGIC;
        ENA_7_P, ENA_7_N      : OUT STD_LOGIC;
        ENA_8_P, ENA_8_N      : OUT STD_LOGIC;

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

        TKI_P,     TKI_N      : OUT STD_LOGIC;
        TKO_P,     TKO_N      : IN  STD_LOGIC;

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
        CK6B_1_P,  CK6B_1_N   : OUT STD_LOGIC;
        CK6B_2_P,  CK6B_2_N   : OUT STD_LOGIC;
        CK6B_3_P,  CK6B_3_N   : OUT STD_LOGIC;
        CK6B_4_P,  CK6B_4_N   : OUT STD_LOGIC;
        CK6B_5_P,  CK6B_5_N   : OUT STD_LOGIC;
        CK6B_6_P,  CK6B_6_N   : OUT STD_LOGIC;
        CK6B_7_P,  CK6B_7_N   : OUT STD_LOGIC;
        CK6B_8_P,  CK6B_8_N   : OUT STD_LOGIC;

        -- ADDC ART CLK
        -------------------------------------
        CKART_ADDC_P          : OUT STD_LOGIC;
        CKART_ADDC_N          : OUT STD_LOGIC;
        
        -- MDT_446/MDT_MU2E Specific Pins
        TRIGGER_OUT_P         : OUT STD_LOGIC;
        TRIGGER_OUT_N         : OUT STD_LOGIC;
        CH_TRIGGER            : IN  STD_LOGIC;
        MO                    : OUT STD_LOGIC;
        ART_OUT_P,  ART_OUT_N : OUT STD_LOGIC;
        ART_P, ART_N          : IN  STD_LOGIC;

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

        -- AXI4SPI Flash Configuration
        ---------------------------------------
        IO0_IO                : INOUT STD_LOGIC;
        IO1_IO                : INOUT STD_LOGIC;
        SS_IO                 : INOUT STD_LOGIC
      );
end mmfe8_top;

architecture Behavioral of mmfe8_top is

    -------------------------------------------------------------------
    -- Global Settings
    ------------------------------------------------------------------- 
    -- Default IP and MAC address of the board
    signal default_IP     : std_logic_vector(31 downto 0) := x"c0a80003";
    signal default_MAC    : std_logic_vector(47 downto 0) := x"002320123223";
    signal default_destIP : std_logic_vector(31 downto 0) := x"c0a80010";
    -- Set to '1' if MMFE8 VMM3, or if level-0 mode is used
    constant is_mmfe8       : std_logic := '0';
    constant l0_enabled     : std_logic := '0';

    -------------------------------------------------------------------
    -- Signals Declaration
    ------------------------------------------------------------------- 

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
  
--TODO: Review signals and distribute to appropriate "set" i.e Ethernet/UDP/Config etc (Christos)
  signal gmii_txd_emac               : std_logic_vector(7 downto 0);
  signal gmii_tx_en_emac             : std_logic; 
  signal gmii_tx_er_emac             : std_logic; 
  signal gmii_rxd_emac               : std_logic_vector(7 downto 0);
  signal gmii_rx_dv_emac             : std_logic; 
  signal gmii_rx_er_emac             : std_logic; 
  signal sgmii_clk_int               : std_logic;
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
  signal independent_clock_int       : std_logic;
  signal rst_gtclk_int               : std_logic;
  signal clk_enable_int              : std_logic;
  signal sgmii_clk_int_oddr          : std_logic;
  signal udp_txi_int                 : udp_tx_type;
  signal control                     : udp_control_type;
  signal udp_rx_int                  : udp_rx_type;
  signal ip_rx_hdr_int               : ipv4_rx_header_type;
  signal udp_tx_data_out_ready_int   : std_logic;
  signal udp_tx_start_int            : std_logic;
  signal rxp_int                     : std_logic;
  signal rxn_int                     : std_logic;
  signal clkfbout2, clkfbout1        : std_logic;
  signal tx_axis_mac_tuser_int       : std_logic := '1';
  signal test_data                   : std_logic_vector(7 downto 0); 
  signal test_valid, test_last       : std_logic;
  signal icmp_rx_start               : std_logic;
  signal icmp_rxo                    : icmp_rx_type;
  signal test_data_out               : std_logic_vector(7 downto 0); 
  signal test_valid_out, test_last_out  : std_logic;  
  signal user_data_out_i             : std_logic_vector(15 downto 0);
  signal sig_out200                  : std_logic_vector(127 downto 0);
  signal user_conf_i                 : std_logic := '0'; 
  signal send_error_int              : std_logic := '0';
  signal resp_data_int               : resp_data;
  signal user_wr_en_int              : std_logic := '0';
  signal reset                       : std_logic := '0';
  signal end_packet_i                : std_logic := '0';    
  signal we_conf_int                 : std_logic := '0';    
  signal packet_length_int           : std_logic_vector(11 downto 0);
  signal daq_data_out_i              : std_logic_vector(15 downto 0);
  signal conf_data_out_i             : std_logic_vector(63 downto 0);
  signal daq_wr_en_i                 : std_logic := '0';    
  signal end_packet_daq              : std_logic := '0'; 
  signal start_conf_proc_int         : std_logic := '0';
  
--TODO: Review signals with updated configuration (Christos)
--  signal  VMM_SCK                       :  std_logic;
  signal  vmm_cs_all                 :  std_logic := '0'; 
  signal  vmm_sck_all                :  std_logic := '0';
  signal  vmm_sdi_all                :  std_logic := '0';
  signal  vmm_bitmask                :  std_logic_vector(7 downto 0) := "11111111";
  signal  sel_cs                     :  std_logic_vector(1 downto 0) := (others => '0');
  signal  VMM_CS_i                   :  std_logic;
  signal  VMM_CS_reset               :  std_logic;    
  ------------------------------VMM configuration------------------------------
  signal vmm_do_vec_i                 : std_logic_vector(8 downto 1);
  signal conf_cktk_out_i              : std_logic := '0';

  ------------------------------ Select VMM ------------------------------
  signal conf_cktk_out_vec_i          : std_logic_vector(8 downto 1);
  signal conf_vmm_wen_vec             : std_logic_vector(8 downto 1);
  signal conf_vmm_ena_vec             : std_logic_vector(8 downto 1);

    -------------------------------------------------
    -- Configuration Signals
    -------------------------------------------------
    --TODO: Review signals with updated configuration (Christos)
    signal reset_done         : std_logic := '0';
    signal w                  : integer := 0;
    signal data_fifo_wr_en    : std_logic;
    signal data_fifo_wr_en_i  : std_logic;
    signal data_fifo_din_i    : std_logic_vector(7 DOWNTO 0);
    signal data_fifo_rd_en    : std_logic;
    signal data_fifo_rd_en_i  : std_logic;
    signal data_fifo_empty    : std_logic;
    signal data_fifo_rd_count : std_logic_vector(14 DOWNTO 0);
    signal data_fifo_wr_count : std_logic_vector(14 DOWNTO 0);
    signal vmm_cfg_sel_i      : std_logic_vector(31 downto 0);
    signal serial_number      : std_logic_vector(31 downto 0) := (others => '0');  
    signal turn_counter_i     : std_logic_vector(15 downto 0);
    signal conf_data_in_i     : std_logic_vector (7 downto 0);
    signal vmm_sdo_vec_i      : std_logic_vector(8 downto 1) := (others => '0'); 
    signal vmm_cs_vec_obuf    : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_sck_vec_obuf   : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_ena_vec_obuf   : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_sdi_vec_obuf   : std_logic_vector(8 downto 1) := (others => '0');
    signal udp_response_int   : udp_response; 
    signal gbl_rst          : std_logic;    --coming from UDP
    signal acq_rst          : std_logic;    --coming from UDP
    signal vmm_ena_gbl_rst  : std_logic := '0';
    signal vmm_wen_gbl_rst  : std_logic := '0';
    signal vmm_ena_acq_rst  : std_logic := '0';
    signal vmm_wen_acq_rst  : std_logic := '0';
    -- misc signals
    signal conf_di_i        : std_logic;
    signal conf_do_i        : std_logic;
    signal conf_ena_i       : std_logic := '0';
    signal conf_wen_i       : std_logic;
    signal dt_cntr_intg0_i    : integer;
    signal ckdt_cntr, timeout : integer := 0;
    signal dt_cntr_intg1_i    : integer;
    signal conf_cnt           : integer := 0;
    signal cnt_vmm            : integer := 0;
    signal vmm_2cfg_i         : std_logic_vector( 2 DOWNTO 0);
    signal mmfeID_i           : std_logic_vector( 3 DOWNTO 0);
    signal clk_dt_out           : std_logic;
    signal vmm_ckart          : std_logic;
    signal reply_enable       : std_logic := '0';
    signal reply_done         : std_logic := '0';
    signal packet_len_conf    : std_logic_vector(11 downto 0) := (others => '0');
    signal clk_tp_out         : std_logic ;
    signal write_done_i       : std_logic;
    signal fifo_writing_i     : std_logic;
    signal global_reset       : std_logic := '0';
    signal conf_done_i        : std_logic;
    signal cktp_send          : std_logic := '0';
    signal conf_wait          : std_logic := '0';  
    signal udp_tx_start_reply : std_logic := '0';
    signal udp_tx_start_daq   : std_logic := '0';
    signal re_out_int         : std_logic := '0';
    signal fifo_data_out_int  : std_logic_vector(7 downto 0) := x"00";
    signal fifo_data          : std_logic_vector(7 downto 0) := x"00";
    signal re_out             : std_logic := '0';
    signal cnt_reset          : integer := 0;
    signal set_reset          : std_logic := '0';
    signal art_in_i           : std_logic := '0';
    signal clk_160            : std_logic;
    signal TKI_i              : std_logic := '0';
    signal first_cktp         : integer := 0;
    signal first_cktp_ok      : std_logic := '0';
    signal vmm_ena_conf       : std_logic := '1';
    signal tko_i              : std_logic;
    signal probe_out0         : std_logic_vector(0 downto 0);
    signal MO_i               : std_logic := 'Z';
    signal cs_int             : std_logic := '1';
    signal udp_header_int     : std_logic := '0';
    signal cnt_reply          : integer := 0;
    signal end_packet_conf_int: std_logic := '0';
    signal end_packet_daq_int : std_logic := '0';
    signal is_state           : std_logic_vector(3 downto 0)  := "1010";
    signal latency_conf       : std_logic_vector(15 downto 0) := x"0000";
    signal test               : std_logic := '0';
    signal count_test         : integer := 0;
    signal art_out            : std_logic := '0';
    signal art_cnt            : integer := 0;
    signal art_cnt2           : integer := 0;
    signal art2               : std_logic := '0';
    signal artall             : std_logic := '0';
    signal reset_FF           : std_logic := '0';
    signal wait_cnt           : unsigned(7 downto 0) := (others => '0');
    signal vmm_id_rdy         : std_logic := '0';
    signal newIP_rdy          : std_logic := '0';
    signal xadc_conf_rdy      : std_logic := '0';
    signal daq_on             : std_logic := '0';
    signal vmmConf_done       : std_logic := '0';
    signal fpga_reset_conf    : std_logic := '0';
    signal flash_busy         : std_logic := '0';
    signal inhibit_conf       : std_logic := '0';
    signal conf_state         : std_logic_vector(2 downto 0) := (others => '0');
    signal din_valid          : std_logic := '0';

    -------------------------------------------------
    -- MMCM Signals                   
    -------------------------------------------------
    signal clk_400_noclean  : std_logic;
    signal clk_400_clean    : std_logic;
    signal clk_200          : std_logic;
    signal clk_800          : std_logic;
    signal clk_10_phase45   : std_logic;
    signal clk_50           : std_logic;
    signal clk_40           : std_logic;
    signal clk_10           : std_logic;
    
    -------------------------------------------------
    -- VMM Signals                   
    -------------------------------------------------
    signal vmm_wen_vec      : std_logic_vector(8 downto 1);
    signal vmm_ena_vec      : std_logic_vector(8 downto 1);
    signal vmm_ena          : std_logic;
    signal cktk_out_vec     : std_logic_vector(8 downto 1);
    signal ckdt_out_vec     : std_logic_vector(8 downto 1);
    signal data0_in_vec     : std_logic_vector(8 downto 1);
    signal data1_in_vec     : std_logic_vector(8 downto 1);
    signal vmm_do_vec       : std_logic_vector(8 downto 1);
    signal vmm_di_vec_i     : std_logic_vector(8 downto 1);
    signal cktk_out_i       : std_logic;
    signal vmm_id           : std_logic_vector(15 downto 0) := x"0000";
    signal vmm_id_int       : std_logic_vector(15 downto 0) := x"0000";
    signal vmm_do_1         : std_logic;  
    signal VMM_SDI_i        : std_logic;
    signal vmm_tki          : std_logic := '0';
    signal vmm_cktp         : std_logic := '0';
    signal vmm_cktp_primary : std_logic := '0';
    signal CKTP_glbl        : std_logic := '0';       
    signal vmm_cktp_all     : std_logic := '0';
    signal vmm_ena_all      : std_logic := '1';
    signal vmm_ckbc         : std_logic;

    -------------------------------------------------
    -- Readout Signals
    -------------------------------------------------
    signal daq_enable_i             : std_logic;
    signal daq_done                 : std_logic;
    signal cktp_state               : integer := 0;
    signal ro_cktk_out_vec          : std_logic_vector(8 downto 1) := ( others => '0' );
    signal daqFIFO_wr_en_i          : std_logic := '0';
    signal daqFIFO_din_i            : std_logic_vector(15 downto 0);
    signal daqFIFO_dout_i           : std_logic_vector(7 downto 0); 
    signal vmmWordReady_i           : std_logic := '0';
    signal vmmWord_i                : std_logic_vector(15 downto 0);
    signal vmmEventDone_i           : std_logic := '0';
    signal daqFIFO_reset            : std_logic := '0';
    signal daq_vmm_ena_wen_enable   : std_logic_vector(8 downto 1) := (others => '0');
    signal daq_cktk_out_enable      : std_logic_vector(8 downto 1) := (others => '0');
    signal UDPDone                  : std_logic;
    signal ckbc_enable              : std_logic := '0';
    signal cktp_enable              : std_logic := '0';
    signal art_out_ff               : std_logic := '0';
    signal dt_state                 : std_logic_vector(3 downto 0) := b"0000";
    signal dt_cntr_st               : std_logic_vector(3 downto 0) := b"0000";
   
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
    signal event_counter_ila  : std_logic_vector(31 downto 0);
    signal tr_out_i           : std_logic;
    signal trigger_loop       : std_logic;
    signal trig_mode_int      : std_logic := '0';   
    signal trigger_loop_i     : std_logic;
    signal ext_trigger_i      : std_logic;  
    signal internalTrigger_state : integer := 0;
    signal CH_TRIGGER_i       : std_logic := '0';
    signal request2ckbc       : std_logic := '0';
    signal trraw_synced125_i  : std_logic := '0';
  
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
    signal pf_datain_i  : std_logic_vector(63 downto 0);
    signal pf_newCycle  : std_logic;
    signal pf_dataout   : std_logic_vector(63 downto 0);
    signal pf_wren      : std_logic;
    signal pf_packLen   : std_logic_vector(11 downto 0);
    signal pf_trigVmmRo : std_logic := '0';
    signal pf_vmmIdRo   : std_logic_vector(2 downto 0) := b"000";
    signal sel_data_vmm : std_logic_vector(1 downto 0) := b"00";
    signal driver_busy  : std_logic := '0';
    signal pf_reset     : std_logic := '0';
    signal rst_vmm      : std_logic := '0';
    signal pf_rst_FIFO  : std_logic := '0';
    signal pfBusy_i     : std_logic := '0';
    signal pf_dbg_st    : std_logic_vector(4 downto 0) := b"00000";
    
    -------------------------------------------------
    -- FIFO2UDP Signals
    -------------------------------------------------    
    signal FIFO2UDP_state   : std_logic_vector(3 downto 0) := b"0000";
    signal faifouki         : std_logic := '0';
    
    ------------------------------------------------------------------
    -- xADC signals
    ------------------------------------------------------------------
    signal xadc_start           : std_logic;
    signal vmm_id_xadc          : std_logic_vector (15 downto 0) := (others => '0');
    signal xadc_sample_size     : std_logic_vector (10 downto 0) := "01111111111"; -- 1023 packets
    signal xadc_delay           : std_logic_vector (17 downto 0) := "011111111111111111"; -- 1023 samples over ~0.7 seconds
    signal xadc_end_of_data     : std_logic;
    signal xadc_fifo_bus        : std_logic_vector (15 downto 0);
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
    signal clk_160_gen      : std_logic := '0';
    signal clk_500_gen      : std_logic := '0';
    signal clk_320_gen      : std_logic := '0';
    signal clk_gen_locked   : std_logic := '0';
    signal rst_gen          : std_logic := '0';  
    signal ckbc_ready_vio   : std_logic := '0';
    signal cktp_enable_vio  : std_logic := '0';
    signal CKBC_glbl        : std_logic := '0';
    signal cktp_pulse_width : std_logic_vector(7 downto 0)     := x"04"; -- 2 us
    signal cktp_period      : std_logic_vector(15 downto 0)    := x"1388"; -- 1 ms
    signal cktp_skew        : std_logic_vector(7 downto 0)     := (others => '0'); 
    signal ckbc_freq        : std_logic_vector(7 downto 0)     := x"28"; --40 Mhz
    signal cktp_max_num     : std_logic_vector(15 downto 0)    := x"ffff";
    signal cktk_max_num     : std_logic_vector(7 downto 0)     := x"07";
    signal ckbcMode         : std_logic := '0';
    
    -------------------------------------------------
    -- Flow FSM signals
    -------------------------------------------------
    type state_t is (IDLE, CONFIGURE, CONF_DONE, CONFIGURE_DELAY, SEND_CONF_REPLY, DAQ_INIT, FIRST_RESET, TRIG, DAQ, XADC_init, XADC_wait, FLASH_init, FLASH_wait);
    signal state        : state_t := IDLE;
    signal rstFIFO_top  : std_logic := '0';

    -------------------------------------------------
    -- Debugging Signals
    -------------------------------------------------
    signal overviewProbe        : std_logic_vector(63 downto 0);
    signal vmmSignalsProbe      : std_logic_vector(63 downto 0);
    signal triggerETRProbe      : std_logic_vector(63 downto 0);
    signal configurationProbe   : std_logic_vector(63 downto 0);
    signal readoutProbe         : std_logic_vector(63 downto 0);
    signal dataOutProbe         : std_logic_vector(63 downto 0);
    signal flowProbe            : std_logic_vector(63 downto 0);
    signal trigger_i            : std_logic;
    signal ckbc_en_vio          : std_logic_vector(0 downto 0) := "0";
    signal cktp_vio             : std_logic_vector(0 downto 0) := "0";
    signal tki_vio              : std_logic_vector(0 downto 0) := "0";
    signal cktk_vio             : std_logic_vector(0 downto 0) := "0";
    signal ckdt_vio             : std_logic_vector(0 downto 0) := "0";
    signal cs_vio               : std_logic_vector(0 downto 0) := "0";
    signal ena_vio              : std_logic_vector(0 downto 0) := "0";

    -------------------------------------------------------------------
    -- These attribute will stop timing errors being reported in back
    -- annotated SDF simulation.
    -------------------------------------------------------------------
    attribute ASYNC_REG                         : string;
    attribute ASYNC_REG of pma_reset_pipe       : signal is "TRUE";
  
    -------------------------------------------------------------------
    -- Keep signals for ILA
    -------------------------------------------------------------------
    attribute keep          : string;
    attribute dont_touch    : string;
    attribute mark_debug    : string;
  
    -------------------------------------------------------------------
    -- Readout Monitoring
    -------------------------------------------------------------------
--    attribute keep of vmm_ena               : signal is "true";
--    attribute dont_touch of vmm_ena         : signal is "true";
--    attribute keep of vmm_wen_vec           : signal is "true";
--    attribute dont_touch of vmm_wen_vec     : signal is "true";
--    attribute keep of cktk_out_vec          : signal is "true";
--    attribute dont_touch of cktk_out_vec    : signal is "true";
--    attribute keep of cktk_out_i            : signal is "true";
--    attribute keep of ckdt_out_vec          : signal is "true";
--    attribute keep of vmm_do_vec_i          : signal is "true";
--    attribute keep of daq_vmm_ena_wen_enable: signal is "true";
--    attribute keep of vmm_id_int            : signal is "true";   
--    attribute keep of data0_in_vec          : signal is "true";
--    attribute dont_touch of data0_in_vec    : signal is "true";
--    attribute keep of ro_cktk_out_vec       : signal is "true";
--    attribute dont_touch of ro_cktk_out_vec : signal is "true";

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
    -- Overview
    -------------------------------------------------------------------
    attribute mark_debug of is_state                  : signal is "TRUE";
    attribute mark_debug of pf_dbg_st                 : signal is "TRUE";
    attribute mark_debug of dt_state                  : signal is "TRUE";
    attribute mark_debug of dt_cntr_st                : signal is "TRUE";
    attribute mark_debug of FIFO2UDP_state            : signal is "TRUE";
    attribute mark_debug of faifouki                  : signal is "TRUE";
    attribute mark_debug of UDPDone                   : signal is "TRUE";
    attribute mark_debug of CKBC_glbl                 : signal is "TRUE";
    attribute mark_debug of tr_out_i                  : signal is "TRUE";
    attribute mark_debug of conf_state                : signal is "TRUE";
    attribute mark_debug of din_valid                 : signal is "TRUE";
    attribute mark_debug of sel_data_vmm              : signal is "TRUE";
    attribute mark_debug of driver_busy               : signal is "TRUE";
    attribute mark_debug of vmmWord_i                 : signal is "TRUE";
    attribute mark_debug of CKTP_glbl                 : signal is "TRUE";
    
    -------------------------------------------------------------------
    -- Other
    -------------------------------------------------------------------   
    
    -------------------------------------------------------------------
    --                       COMPONENTS                              --
    -------------------------------------------------------------------
    -- 1.  clk_wiz_200_to_400
    -- 2.  clk_wiz_low_jitter
    -- 3.  clk_wiz_0
    -- 4.  clk_wiz_gen
    -- 5.  event_timing_reset
    -- 6.  vmm_readout
    -- 7.  FIFO2UDP
    -- 8.  trigger
    -- 9.  packet_formation
    -- 10. gig_ethernet_pcs_pma_0
    -- 11. UDP_Complete_nomac
    -- 12. temac_10_100_1000_fifo_block
    -- 13. temac_10_100_1000_reset_sync
    -- 14. temac_10_100_1000_config_vector_sm
    -- 15. i2c_top
    -- 16. udp_data_in_handler
    -- 17. udp_reply_handler
    -- 18. select_data
    -- 19. ila_top_level
    -- 20. xadc
    -- 21. AXI4_SPI
    -- 22. vio
    -- 23. CDCC
    -- 24. VIO_IP
    -- 25. clk_gen_wrapper
    -- 26. ila_overview
    -------------------------------------------------------------------
    -- 1
    component clk_wiz_200_to_400
      port(
          clk_in1_p       : in     std_logic;
          clk_in1_n       : in     std_logic;
          clk_out_400     : out    std_logic
      );
    end component;
    -- 2
    component clk_wiz_low_jitter
      port(
          clk_in1         : in     std_logic;
          clk_out1        : out    std_logic
      );
    end component;
    -- 3
    component clk_wiz_0
      port(
          clk_in1         : in     std_logic;
          reset           : in     std_logic;
          clk_200_o       : out    std_logic;
          clk_800_o       : out    std_logic;
          clk_10_phase45_o: out    std_logic;
          clk_50_o        : out    std_logic;
          clk_40_o        : out    std_logic;
          clk_10_o        : out    std_logic;
          clk_160_o       : out    std_logic
      );
    end component;
    -- 4
    component clk_wiz_gen
    port(
        clk_in_400  : in     std_logic;
        clk_out_160 : out    std_logic;
        clk_out_500 : out    std_logic;
        clk_out_320 : out    std_logic;
        reset       : in     std_logic;
        gen_locked  : out    std_logic
    );
    end component;
    --5
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
    -- 6
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
            
            vmmWordReady            : out std_logic;
            vmmWord                 : out std_logic_vector(15 downto 0);
            vmmEventDone            : out std_logic;
            
            sel_data                : in  std_logic_vector(1 downto 0);
            driverBusy              : in  std_logic;
            
            dt_state_o              : out std_logic_vector(3 downto 0);
            dt_cntr_st_o            : out std_logic_vector(3 downto 0)
        );
    end component;
    -- 7
    component FIFO2UDP
        port ( 
            clk_125                     : in std_logic;
            destinationIP               : in std_logic_vector(31 downto 0);
            daq_data_in                 : in  std_logic_vector(15 downto 0);
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
            
            trigger_out                 : out std_logic;
            count_o                     : out std_logic_vector(3 downto 0);
            faifouki                    : out std_logic
        );
    end component;
    -- 8
    component trigger is
      port (
          clk             : in std_logic;
          ckbc            : in std_logic;
          clk_art         : in std_logic;
          
          ckbcMode        : in std_logic;
          request2ckbc    : out std_logic;
          
          tren            : in std_logic;
          tr_hold         : in std_logic;
          trmode          : in std_logic;
          trext           : in std_logic;
          trint           : in std_logic;
          reset           : in std_logic;
          
          event_counter   : out std_logic_vector(31 DOWNTO 0);
          tr_out          : out std_logic;
          trraw_synced125 : out std_logic;
          latency         : in std_logic_vector(15 DOWNTO 0)
      );
    end component;
    -- 9
    component packet_formation is
    generic(is_mmfe8    : std_logic;
            l0_enabled  : std_logic);
    port (
            clk             : in std_logic;
    
            newCycle        : in std_logic;
            
            trigVmmRo       : out std_logic;
            vmmId           : out std_logic_vector(2 downto 0);
            vmmWord         : in std_logic_vector(15 downto 0);
            vmmWordReady    : in std_logic;
            vmmEventDone    : in std_logic;
        
            UDPDone         : in std_logic;
            pfBusy          : out std_logic;
            glBCID          : in std_logic_vector(11 downto 0);

            packLen         : out std_logic_vector(11 downto 0);
            dataout         : out std_logic_vector(15 downto 0);
            wrenable        : out std_logic;
            end_packet      : out std_logic;
            
            rd_ena_l0_buff  : out std_logic;
            l0_buff_empty   : in  std_logic;
            sel_data_vmm    : out std_logic_vector(1 downto 0);
            driver_busy     : out std_logic;
            
            tr_hold         : out std_logic;
            reset           : in std_logic;
            rst_vmm         : out std_logic;
            --resetting   : in std_logic;
            rst_FIFO        : out std_logic;
            
            latency         : in std_logic_vector(15 downto 0);
            dbg_st_o        : out std_logic_vector(4 downto 0);
            
            trraw_synced125 : in std_logic
    );
    end component;
    -- 10
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
    -- 11
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
    -- 12
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
    -- 13
    component temac_10_100_1000_reset_sync
        port ( 
            reset_in           : in  std_logic;    -- Active high asynchronous reset
            enable             : in  std_logic;
            clk                : in  std_logic;    -- clock to be sync'ed to
            reset_out          : out std_logic);     -- "Synchronised" reset signal
    end component;
    -- 14
    component temac_10_100_1000_config_vector_sm is
    port(
      gtx_clk                 : in  std_logic;
      gtx_resetn              : in  std_logic;
      mac_speed               : in  std_logic_vector(1 downto 0);
      update_speed            : in  std_logic;
      rx_configuration_vector : out std_logic_vector(79 downto 0);
      tx_configuration_vector : out std_logic_vector(79 downto 0));
    end component;
    -- 15
    component i2c_top is
    port(  
        clk_in                : in    std_logic;        
        phy_rstn_out          : out   std_logic
    );  
    end component;
    -- 16
    component udp_data_in_handler
    port(
        ------------------------------------
        ------- General Interface ----------
        clk_125             : in  std_logic;
        clk_40              : in  std_logic;
        inhibit_conf        : in  std_logic;
        rst                 : in  std_logic;
        state_o             : out std_logic_vector(2 downto 0);
        valid_o             : out std_logic;
        ------------------------------------
        -------- FPGA Config Interface -----
        latency             : out std_logic_vector(15 downto 0);
        serial_number       : out std_logic_vector(31 downto 0);
        daq_on              : out std_logic;
        ext_trigger         : out std_logic;
        ckbcMode            : out std_logic;
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
        -------- CKTP/CKBC Interface -------
        ckbc_freq           : out std_logic_vector(7 downto 0);
        cktk_max_num        : out std_logic_vector(7 downto 0);
        cktp_max_num        : out std_logic_vector(15 downto 0);
        cktp_skew           : out std_logic_vector(7 downto 0);
        cktp_period         : out std_logic_vector(15 downto 0);
        cktp_width          : out std_logic_vector(7 downto 0);
        ------------------------------------
        ------ VMM Config Interface --------
        vmm_bitmask         : out std_logic_vector(7 downto 0);
        vmmConf_rdy         : out std_logic;
        vmmConf_done        : out std_logic;
        vmm_sck             : out std_logic;
        vmm_cs              : out std_logic;
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
    -- 17
    component udp_reply_handler
    port(
        ------------------------------------
        ------- General Interface ----------
        clk             : in  std_logic;
        enable          : in  std_logic;
        serial_number   : in  std_logic_vector(31 downto 0);
        reply_done      : out std_logic;
        ------------------------------------
        ---- FIFO Data Select Interface ----
        wr_en_conf      : out std_logic;
        dout_conf       : out std_logic_vector(15 downto 0);
        packet_len_conf : out std_logic_vector(11 downto 0);
        end_conf        : out std_logic       
    );
    end component;
    -- 18
    component select_data
    port(
        configuring                 : in  std_logic;
        data_acq                    : in  std_logic;
        xadc                        : in  std_logic;
        we_data                     : in  std_logic;
        we_conf                     : in  std_logic;
        we_xadc                     : in  std_logic;
        daq_data_in                 : in  std_logic_vector(15 downto 0);
        conf_data_in                : in  std_logic_vector(15 downto 0);
        xadc_data_in                : in  std_logic_vector(15 downto 0);
        data_packet_length          : in  std_logic_vector(11 downto 0);
        xadc_packet_length          : in  std_logic_vector(11 downto 0);
        conf_packet_length          : in  std_logic_vector(11 downto 0);
        end_packet_conf             : in  std_logic;
        end_packet_daq              : in  std_logic;
        end_packet_xadc             : in  std_logic;
        fifo_rst_daq                : in  std_logic;
        fifo_rst_xadc               : in  std_logic;
        rstFIFO_top                 : in std_logic;
    
        data_out                    : out std_logic_vector(15 downto 0);
        packet_length               : out std_logic_vector(11 downto 0);
        we                          : out std_logic;
        end_packet                  : out std_logic;
        fifo_rst                    : out std_logic
    );
    end component;
    -- 19
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
    -- 20
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
        fifo_bus            : out std_logic_vector(15 downto 0);
        data_fifo_enable    : out std_logic;
        packet_len          : out std_logic_vector(11 downto 0);
        xadc_busy           : out std_logic
    );
    end component;
    -- 21
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
    -- 22
    component vio_1
    port (
        clk         : in  std_logic;
        probe_out0  : out std_logic_vector(0 downto 0);
        probe_out1  : out std_logic_vector(0 downto 0);
        probe_out2  : out std_logic_vector(0 downto 0);
        probe_out3  : out std_logic_vector(0 downto 0);
        probe_out4  : out std_logic_vector(0 downto 0);
        probe_out5  : out std_logic_vector(0 downto 0)
        );
    end component;
    -- 23
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
    -- 24
    COMPONENT vio_ip
      PORT (
        clk        : IN STD_LOGIC;
        probe_out0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        probe_out1 : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
      );
    END COMPONENT;
    -- 25
    component clk_gen_wrapper
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_500             : in  std_logic;
        clk_160             : in  std_logic;
        clk_125             : in  std_logic;
        rst                 : in  std_logic;
        mmcm_locked         : in  std_logic;
        trint               : out std_logic;
        ------------------------------------
        ----- Configuration Interface ------
        ckbc_enable         : in  std_logic;
        cktp_enable         : in  std_logic;
        cktp_primary        : in  std_logic;
        readout_mode        : in  std_logic;
        enable_ro_ckbc      : in  std_logic;
        cktp_pulse_width    : in  std_logic_vector(4 downto 0);
        cktp_max_num        : in  std_logic_vector(15 downto 0);
        cktp_period         : in  std_logic_vector(15 downto 0);
        cktp_skew           : in  std_logic_vector(4 downto 0);        
        ckbc_freq           : in  std_logic_vector(5 downto 0);
        ------------------------------------
        ---------- VMM Interface -----------
        CKTP                : out std_logic;
        CKBC                : out std_logic
    );
    end component;
    -- 26
    component ila_overview
    Port(
        clk     : in std_logic;
        probe0  : in std_logic_vector(63 downto 0)
    );
    end component;
    
    --27
    component L0_wrapper
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt    : in  std_logic; -- will be forwarded to the VMM
        clk_des     : in  std_logic; -- must be twice the frequency of CKDT
        level_0     : in  std_logic; -- level-0 signal
        rst         : in  std_logic;
        ------------------------------------
        ---------- VMM Interface -----------
        VMM_CKDT    : out std_logic;
        VMM_CKTK    : out std_logic;
        VMM_DATA0   : in  std_logic;
        VMM_DATA1   : in  std_logic
    );
    end component;

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

   pma_reset <= pma_reset_pipe(3);

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
      independent_clock_bufg => clk_200,
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
            udp_rx_start                => udp_header_int,                                  -- indicates receipt of udp header
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
       port map(  clk_in                => clk_200,
                  phy_rstn_out          => phy_rstn_out);

udp_din_conf_block: udp_data_in_handler
    port map(
        ------------------------------------
        ------- General Interface ----------
        clk_125             => userclk2,
        clk_40              => clk_40,
        inhibit_conf        => inhibit_conf,
        rst                 => glbl_rst_i,
        state_o             => conf_state,
        valid_o             => din_valid,
        ------------------------------------
        -------- FPGA Config Interface -----
        latency             => latency_conf,
        serial_number       => serial_number,
        daq_on              => daq_on,
        ext_trigger         => trig_mode_int,
        ckbcMode            => ckbcMode,
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
        -------- CKTP/CKBC Interface -------
        ckbc_freq           => ckbc_freq,
        cktk_max_num        => cktk_max_num,
        cktp_max_num        => cktp_max_num,
        cktp_skew           => cktp_skew,
        cktp_period         => cktp_period,
        cktp_width          => cktp_pulse_width,
        ------------------------------------
        ------ VMM Config Interface --------
        vmm_bitmask         => open,
        vmmConf_rdy         => vmm_id_rdy,
        vmmConf_done        => vmmConf_done,
        vmm_sck             => vmm_sck_all,
        vmm_cs              => VMM_CS_i,
        vmm_cfg_bit         => vmm_sdi_all,
        top_rdy             => conf_wen_i,
        ------------------------------------
        ---------- XADC Interface ----------
        xadc_busy           => xadc_busy,
        xadc_rdy            => xadc_conf_rdy,
        vmm_id_xadc         => vmm_id_xadc,
        xadc_sample_size    => xadc_sample_size,
        xadc_delay          => xadc_delay
    );

udp_reply_instance: udp_reply_handler
    port map(
        ------------------------------------
        ------- General Interface ----------
        clk             => userclk2,
        enable          => reply_enable,
        serial_number   => serial_number,
        reply_done      => reply_done,
        ------------------------------------
        ---- FIFO Data Select Interface ----
        wr_en_conf      => we_conf_int,
        dout_conf       => user_data_out_i,
        packet_len_conf => packet_len_conf,
        end_conf        => end_packet_conf_int
    );

clk_200_to_400_inst: clk_wiz_200_to_400
    port map(
        clk_in1_p   => X_2V5_DIFF_CLK_P,
        clk_in1_n   => X_2V5_DIFF_CLK_N,
        clk_out_400 => clk_400_noclean
    );

clk_400_low_jitter_inst: clk_wiz_low_jitter
    port map(
        clk_in1     => clk_400_noclean,
        clk_out1    => clk_400_clean
    );

clk_user_inst: clk_wiz_0
    port map(
        clk_in1             => clk_400_clean,
        reset               => '0',
        clk_200_o           => clk_200,
        clk_800_o           => clk_800,
        clk_10_phase45_o    => clk_10_phase45,
        clk_50_o            => clk_50,
        clk_40_o            => clk_40,
        clk_10_o            => clk_10,
        clk_160_o           => clk_160
   );

mmcm_ckbc_cktp: clk_wiz_gen
    port map ( 
        clk_in_400  => clk_400_clean,
        clk_out_160 => clk_160_gen,
        clk_out_500 => clk_500_gen,
        clk_out_320 => clk_320_gen,
        reset       => '0',
        gen_locked  => clk_gen_locked            
    );

event_timing_reset_instance: event_timing_reset
    port map(
        hp_clk          => clk_800,
        clk             => userclk2,
        clk_10_phase45  => clk_10_phase45,
        bc_clk          => clk_10,

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
        clkTkProc               => clk_40,
        clkDtProc               => clk_50,
        clk                     => userclk2,
        
        vmm_data0_vec           => data0_in_vec,
        vmm_data1_vec           => data1_in_vec,
        vmm_ckdt_vec            => ckdt_out_vec, --ckdt_out_vec
        vmm_cktk_vec            => cktk_out_vec, --cktk_out_vec

        daq_enable              => daq_enable_i,
        trigger_pulse           => pf_trigVmmRo,
        cktk_max                => cktk_max_num,
        vmmId                   => pf_vmmIdRo,
        ethernet_fifo_wr_en     => open,
        vmm_data_buf            => open,
        
        sel_data                => sel_data_vmm,
        driverBusy              => driver_busy,
        
        vmmWordReady            => vmmWordReady_i,
        vmmWord                 => vmmWord_i,
        vmmEventDone            => vmmEventDone_i,
        
        dt_state_o              => dt_state,
        dt_cntr_st_o            => dt_cntr_st
    );

trigger_instance: trigger
    port map(
        clk             => userclk2,
        ckbc            => clk_40,
        clk_art         => clk_160_gen,
        
        ckbcMode        => ckbcMode,
        request2ckbc    => request2ckbc,
        
        tren            => tren,                -- Trigger module enabled
        tr_hold         => tr_hold,             -- Prevents trigger while high
        trmode          => trig_mode_int,       -- Mode 0: internal / Mode 1: external
        trext           => CH_TRIGGER_i,        -- External trigger is to be driven to this port
        trint           => trint,               -- Internal trigger is to be driven to this port (CKTP)

        reset           => tr_reset,

        event_counter   => event_counter_i,
        tr_out          => tr_out_i,
        trraw_synced125 => trraw_synced125_i,
        latency         => latency_conf
    );

FIFO2UDP_instance: FIFO2UDP
    Port map( 
        clk_125                     => userclk2,
        destinationIP               => destIP,
        daq_data_in                 => daqFIFO_din_i,
        fifo_data_out               => fifo_data_out_int,
        udp_txi                     => udp_txi_int,    
        udp_tx_start                => udp_tx_start_int,
        control                     => control.ip_controls.arp_controls.clear_cache,
        UDPDone                     => UDPDone,   
        re_out                      => re_out_int,    
        udp_tx_data_out_ready       => udp_tx_data_out_ready_int,
        wr_en                       => daqFIFO_wr_en_i,
        end_packet                  => end_packet_i,
        global_reset                => glbl_rst_i,
        packet_length_in            => packet_length_int,
        reset_DAQ_FIFO              => daqFIFO_reset,

        vmmID                       => pf_vmmIdRo,
        
        trigger_out                 => trigger_i,
        count_o                     => FIFO2UDP_state,
        faifouki                    => faifouki
    );       

packet_formation_instance: packet_formation
    generic map(is_mmfe8    => is_mmfe8,
                l0_enabled  => l0_enabled)
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
        dataout         => daq_data_out_i,
        wrenable        => daq_wr_en_i,
        end_packet      => end_packet_daq_int,
        
        rd_ena_l0_buff  => open,
        l0_buff_empty   => '1',
        sel_data_vmm    => sel_data_vmm,
        driver_busy     => driver_busy,
        
        tr_hold         => tr_hold,
        reset           => pf_reset,
        rst_vmm         => rst_vmm,
        --resetting       => etr_reset_latched,
        rst_FIFO        => pf_rst_FIFO,

        latency         => latency_conf,
        dbg_st_o        => pf_dbg_st,
        trraw_synced125 => trraw_synced125_i
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
        conf_packet_length          => packet_len_conf,
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
        clk_200                => clk_200,
        clk_125                => userclk2,
        clk_50                 => clk_50,
        
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
        clk_500             => clk_500_gen,
        clk_160             => clk_160_gen,
        clk_125             => userclk2,
        rst                 => rst_gen,
        mmcm_locked         => clk_gen_locked,
        trint               => trint,
        ------------------------------------
        ----- Configuration Interface ------
        ckbc_enable         => ckbc_enable,
        cktp_enable         => cktp_enable,
        cktp_primary        => vmm_cktp_primary, -- from flow_fsm
        readout_mode        => ckbcMode,
        enable_ro_ckbc      => request2ckbc,
        cktp_pulse_width    => cktp_pulse_width(4 downto 0),
        cktp_max_num        => cktp_max_num,
        cktp_period         => cktp_period,
        cktp_skew           => cktp_skew(4 downto 0),
        ckbc_freq           => ckbc_freq(5 downto 0),
        ------------------------------------
        ---------- VMM Interface -----------
        CKTP                => CKTP_glbl,
        CKBC                => CKBC_glbl
    );
l0_readout_case: if l0_enabled = '1' generate
-- TO DO: Add level_0 signal assertion from trigger module    
level0_readout: L0_wrapper
   port map(
        ------------------------------------
        ------- General Interface ----------
        clk_ckdt    => clk_160_gen,
        clk_des     => clk_320_gen,
        level_0     => '0',           -- TO BE ADDED
        rst         => '0',
        ------------------------------------
        ---------- VMM Interface -----------
        VMM_CKDT    => open,
        VMM_CKTK    => open,
        VMM_DATA0   => '0',
        VMM_DATA1   => '0'
    );
end generate l0_readout_case;

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

----------------------------------------------------CS-------------------------------------------------------------
cs_obuf_1:  OBUF  port map  (O => CS_1, I => vmm_cs_vec_obuf(1));
cs_obuf_2:  OBUF  port map  (O => CS_2, I => vmm_cs_vec_obuf(2));
cs_obuf_3:  OBUF  port map  (O => CS_3, I => vmm_cs_vec_obuf(3));
cs_obuf_4:  OBUF  port map  (O => CS_4, I => vmm_cs_vec_obuf(4));
cs_obuf_5:  OBUF  port map  (O => CS_5, I => vmm_cs_vec_obuf(5));
cs_obuf_6:  OBUF  port map  (O => CS_6, I => vmm_cs_vec_obuf(6));
cs_obuf_7:  OBUF  port map  (O => CS_7, I => vmm_cs_vec_obuf(7));
cs_obuf_8:  OBUF  port map  (O => CS_8, I => vmm_cs_vec_obuf(8));

----------------------------------------------------SCK-------------------------------------------------------------
sck_obuf_1:  OBUF  port map  (O => SCK_1, I => vmm_sck_vec_obuf(1));
sck_obuf_2:  OBUF  port map  (O => SCK_2, I => vmm_sck_vec_obuf(2));
sck_obuf_3:  OBUF  port map  (O => SCK_3, I => vmm_sck_vec_obuf(3));
sck_obuf_4:  OBUF  port map  (O => SCK_4, I => vmm_sck_vec_obuf(4));
sck_obuf_5:  OBUF  port map  (O => SCK_5, I => vmm_sck_vec_obuf(5));
sck_obuf_6:  OBUF  port map  (O => SCK_6, I => vmm_sck_vec_obuf(6));
sck_obuf_7:  OBUF  port map  (O => SCK_7, I => vmm_sck_vec_obuf(7));
sck_obuf_8:  OBUF  port map  (O => SCK_8, I => vmm_sck_vec_obuf(8));

----------------------------------------------------SDI-------------------------------------------------------------
sdi_obuf_1:  OBUF  port map  (O => SDI_1, I => vmm_sdi_vec_obuf(1));
sdi_obuf_2:  OBUF  port map  (O => SDI_2, I => vmm_sdi_vec_obuf(2));
sdi_obuf_3:  OBUF  port map  (O => SDI_3, I => vmm_sdi_vec_obuf(3));
sdi_obuf_4:  OBUF  port map  (O => SDI_4, I => vmm_sdi_vec_obuf(4));
sdi_obuf_5:  OBUF  port map  (O => SDI_5, I => vmm_sdi_vec_obuf(5));
sdi_obuf_6:  OBUF  port map  (O => SDI_6, I => vmm_sdi_vec_obuf(6));
sdi_obuf_7:  OBUF  port map  (O => SDI_7, I => vmm_sdi_vec_obuf(7));
sdi_obuf_8:  OBUF  port map  (O => SDI_8, I => vmm_sdi_vec_obuf(8));

---------------------------------------------------SETT/SETB/CK6B---------------------------------------------------
sett_obuf:   OBUFDS port map (O => SETT_P,   OB => SETT_N,   I => '0');    
setb_obuf:   OBUFDS port map (O => SETB_P,   OB => SETB_N,   I => '0');
ck6b_obuf_1: OBUFDS port map (O => CK6B_1_P, OB => CK6B_1_N, I => '0');
ck6b_obuf_2: OBUFDS port map (O => CK6B_2_P, OB => CK6B_2_N, I => '0');
ck6b_obuf_3: OBUFDS port map (O => CK6B_3_P, OB => CK6B_3_N, I => '0');
ck6b_obuf_4: OBUFDS port map (O => CK6B_4_P, OB => CK6B_4_N, I => '0');
ck6b_obuf_5: OBUFDS port map (O => CK6B_5_P, OB => CK6B_5_N, I => '0');
ck6b_obuf_6: OBUFDS port map (O => CK6B_6_P, OB => CK6B_6_N, I => '0');
ck6b_obuf_7: OBUFDS port map (O => CK6B_7_P, OB => CK6B_7_N, I => '0');
ck6b_obuf_8: OBUFDS port map (O => CK6B_8_P, OB => CK6B_8_N, I => '0');

----------------------------------------------------SDO-------------------------------------------------------------
sdo_ibuf_1: IBUF port map ( O =>  vmm_sdo_vec_i(1), I =>  SDO_1);
sdo_ibuf_2: IBUF port map ( O =>  vmm_sdo_vec_i(2), I =>  SDO_2);
sdo_ibuf_3: IBUF port map ( O =>  vmm_sdo_vec_i(3), I =>  SDO_3);
sdo_ibuf_4: IBUF port map ( O =>  vmm_sdo_vec_i(4), I =>  SDO_4);
sdo_ibuf_5: IBUF port map ( O =>  vmm_sdo_vec_i(5), I =>  SDO_5);
sdo_ibuf_6: IBUF port map ( O =>  vmm_sdo_vec_i(6), I =>  SDO_6);
sdo_ibuf_7: IBUF port map ( O =>  vmm_sdo_vec_i(7), I =>  SDO_7);
sdo_ibuf_8: IBUF port map ( O =>  vmm_sdo_vec_i(8), I =>  SDO_8);

----------------------------------------------------ENA------------------------------------------------------------
ena_diff_1: OBUFDS port map ( O =>  ENA_1_P, OB => ENA_1_N, I => vmm_ena_vec_obuf(1));    
ena_diff_2: OBUFDS port map ( O =>  ENA_2_P, OB => ENA_2_N, I => vmm_ena_vec_obuf(2));
ena_diff_3: OBUFDS port map ( O =>  ENA_3_P, OB => ENA_3_N, I => vmm_ena_vec_obuf(3));
ena_diff_4: OBUFDS port map ( O =>  ENA_4_P, OB => ENA_4_N, I => vmm_ena_vec_obuf(4));
ena_diff_5: OBUFDS port map ( O =>  ENA_5_P, OB => ENA_5_N, I => vmm_ena_vec_obuf(5));
ena_diff_6: OBUFDS port map ( O =>  ENA_6_P, OB => ENA_6_N, I => vmm_ena_vec_obuf(6));
ena_diff_7: OBUFDS port map ( O =>  ENA_7_P, OB => ENA_7_N, I => vmm_ena_vec_obuf(7));
ena_diff_8: OBUFDS port map ( O =>  ENA_8_P, OB => ENA_8_N, I => vmm_ena_vec_obuf(8));

----------------------------------------------------CKBC--------------------------------------------------------------
ckbc_diff_1: OBUFDS port map ( O =>  CKBC_1_P, OB => CKBC_1_N, I =>  CKBC_glbl);
ckbc_diff_2: OBUFDS port map ( O =>  CKBC_2_P, OB => CKBC_2_N, I =>  CKBC_glbl);
ckbc_diff_3: OBUFDS port map ( O =>  CKBC_3_P, OB => CKBC_3_N, I =>  CKBC_glbl);
ckbc_diff_4: OBUFDS port map ( O =>  CKBC_4_P, OB => CKBC_4_N, I =>  CKBC_glbl);
ckbc_diff_5: OBUFDS port map ( O =>  CKBC_5_P, OB => CKBC_5_N, I =>  CKBC_glbl);
ckbc_diff_6: OBUFDS port map ( O =>  CKBC_6_P, OB => CKBC_6_N, I =>  CKBC_glbl);
ckbc_diff_7: OBUFDS port map ( O =>  CKBC_7_P, OB => CKBC_7_N, I =>  CKBC_glbl);
ckbc_diff_8: OBUFDS port map ( O =>  CKBC_8_P, OB => CKBC_8_N, I =>  CKBC_glbl);

----------------------------------------------------CKTP--------------------------------------------------------------  
cktp_diff_1: OBUFDS port map ( O =>  CKTP_1_P, OB => CKTP_1_N, I => CKTP_glbl);  
cktp_diff_2: OBUFDS port map ( O =>  CKTP_2_P, OB => CKTP_2_N, I => CKTP_glbl);
cktp_diff_3: OBUFDS port map ( O =>  CKTP_3_P, OB => CKTP_3_N, I => CKTP_glbl);
cktp_diff_4: OBUFDS port map ( O =>  CKTP_4_P, OB => CKTP_4_N, I => CKTP_glbl);
cktp_diff_5: OBUFDS port map ( O =>  CKTP_5_P, OB => CKTP_5_N, I => CKTP_glbl);
cktp_diff_6: OBUFDS port map ( O =>  CKTP_6_P, OB => CKTP_6_N, I => CKTP_glbl);
cktp_diff_7: OBUFDS port map ( O =>  CKTP_7_P, OB => CKTP_7_N, I => CKTP_glbl);
cktp_diff_8: OBUFDS port map ( O =>  CKTP_8_P, OB => CKTP_8_N, I => CKTP_glbl);

----------------------------------------------------CKTK--------------------------------------------------------------
cktk_diff_1: OBUFDS port map ( O =>  CKTK_1_P, OB => CKTK_1_N, I => cktk_out_vec(1));
cktk_diff_2: OBUFDS port map ( O =>  CKTK_2_P, OB => CKTK_2_N, I => cktk_out_vec(2));
cktk_diff_3: OBUFDS port map ( O =>  CKTK_3_P, OB => CKTK_3_N, I => cktk_out_vec(3));
cktk_diff_4: OBUFDS port map ( O =>  CKTK_4_P, OB => CKTK_4_N, I => cktk_out_vec(4));
cktk_diff_5: OBUFDS port map ( O =>  CKTK_5_P, OB => CKTK_5_N, I => cktk_out_vec(5));
cktk_diff_6: OBUFDS port map ( O =>  CKTK_6_P, OB => CKTK_6_N, I => cktk_out_vec(6));
cktk_diff_7: OBUFDS port map ( O =>  CKTK_7_P, OB => CKTK_7_N, I => cktk_out_vec(7));
cktk_diff_8: OBUFDS port map ( O =>  CKTK_8_P, OB => CKTK_8_N, I => cktk_out_vec(8));
    
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

----------------------------------------------------TKI/TKO--------------------------------------------------------------      
TKI_diff_1: OBUFDS port map ( O =>  TKI_P, OB => TKI_N, I => vmm_tki);
TKO_diff_1: IBUFDS port map ( O =>  tko_i, I => TKO_P, IB => TKO_N);

---------------------------------------------------CKART-----------------------------------------------------------------
ckart_diff_1: OBUFDS port map ( O => CKART_1_P, OB => CKART_1_N, I => clk_160);
ckart_diff_2: OBUFDS port map ( O => CKART_2_P, OB => CKART_2_N, I => clk_160);
ckart_diff_3: OBUFDS port map ( O => CKART_3_P, OB => CKART_3_N, I => clk_160);
ckart_diff_4: OBUFDS port map ( O => CKART_4_P, OB => CKART_4_N, I => clk_160);
ckart_diff_5: OBUFDS port map ( O => CKART_5_P, OB => CKART_5_N, I => clk_160);
ckart_diff_6: OBUFDS port map ( O => CKART_6_P, OB => CKART_6_N, I => clk_160);
ckart_diff_7: OBUFDS port map ( O => CKART_7_P, OB => CKART_7_N, I => clk_160);
ckart_diff_8: OBUFDS port map ( O => CKART_8_P, OB => CKART_8_N, I => clk_160);

ckart_addc_buf: OBUFDS port map ( O => CKART_ADDC_P, OB => CKART_ADDC_N, I => clk_160);

----------------------------------------------------XADC-----------------------------------------------------------------
xadc_mux0_obuf:   OBUF   port map  (O => MuxAddr0, I => MuxAddr0_i);
xadc_mux1_obuf:   OBUF   port map  (O => MuxAddr1, I => MuxAddr1_i);
xadc_mux2_obuf:   OBUF   port map  (O => MuxAddr2, I => MuxAddr2_i);
xadc_mux3_obufds: OBUFDS port map  (O => MuxAddr3_p, OB => MuxAddr3_n, I => MuxAddr3_p_i);

art_in_diff_1:    IBUFDS port map (O =>  art_in_i, I => ART_P, IB => ART_N);
art_out_diff_1:   OBUFDS port map (O =>  ART_OUT_P, OB => ART_OUT_N, I => art2);
 
-------------------------------------------------------------------
--                        Processes                              --
-------------------------------------------------------------------
    -- 1. synced_to_flowFSM
    -- 2. sel_cs
    -- 3. flow_fsm
-------------------------------------------------------------------
art_process: process(userclk2, art2)
begin
    if rising_edge(userclk2) then  
        if art_cnt2 < 125 and art2 = '1' then 
            art_out_ff  <= '1';
            art_cnt2    <= art_cnt2 + 1;
        elsif art_cnt2 = 125 then
            reset_FF    <= '1';
            art_cnt2    <= art_cnt2 + 1;
        else
            art_cnt2    <= 0;
            reset_FF    <= '0';
        end if;
    end if;
end process;    

FDCE_inst: FDCE
generic map (INIT => '0') -- Initial value of register ('0' or '1')
port map (
    Q   => art2, -- Data output
    C   => art_in_i, -- Clock input
    CE  => '1', -- Clock enable input
    CLR => reset_FF, -- Asynchronous clear input
    D   => '1' -- Data input
);

sel_cs_proc: process(sel_cs, vmm_cs_i)
begin
    case sel_cs is
        when "00"   => vmm_cs_all <= '0';
        when "01"   => vmm_cs_all <= vmm_cs_i;
        when "10"   => vmm_cs_all <= vmm_cs_i;
        when "11"   => vmm_cs_all <= '1'; 
        when others => vmm_cs_all <= '0';
    end case;   
end process;

flow_fsm: process(userclk2, state, vmm_id, write_done_i, conf_done_i)
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
                    start_conf_proc_int     <= '0';
                    reply_enable            <= '0';
                    cnt_vmm                 <= 1;
                    
                    daq_enable_i            <= '0';
                    pf_reset                <= '0';
                    rstFIFO_top             <= '0';
                    tren                    <= '0';
                    vmm_ena_all             <= '0';
                    vmm_tki                 <= '0';
                    ckbc_enable             <= '0';
                    vmm_cktp_primary        <= '0';
                    daq_vmm_ena_wen_enable  <= x"00";
                    daq_cktk_out_enable     <= x"00";
                    sel_cs                  <= "11";    -- drive CS high

                    if(vmm_id_rdy = '1')then
                        if(wait_cnt = "00000111")then -- wait for safe assertion of multi-bit signal
                            wait_cnt    <= (others => '0');
                            state       <= CONFIGURE;
                        else
                            wait_cnt    <= wait_cnt + 1;
                            state       <= IDLE;
                        end if;

                    elsif(newIP_rdy = '1')then -- start new IP setup
                        if(wait_cnt = "00000111")then -- wait for safe assertion of multi-bit signal
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

               when    CONFIGURE    =>        
                    is_state        <= "0001";
                    sel_cs          <= "01"; -- select CS from config
                    if(vmmConf_done = '1')then 
                        state   <= CONF_DONE;
                    else
                        state   <= CONFIGURE;
                    end if;

                    conf_wen_i          <= '1'; 
                    start_conf_proc_int <= '1';

                when    CONF_DONE    =>
                 --   sel_cs          <= "10"; -- select CS from config
                    vmm_ena_all     <= '1';
                    is_state        <= "0010";
                    if w = 40 then
                        cnt_vmm     <= cnt_vmm - 1;
                        if cnt_vmm = 1 then --VMM conf done
                            state           <= SEND_CONF_REPLY;
                        else
                            state       <= CONFIGURE_DELAY;
                        end if;
                        w   <= 0;
                    else
                        w <= w + 1;
                    end if;
                    
                    conf_wen_i      <= '0';

                when CONFIGURE_DELAY => -- Waits 100 ns to move to next configuration
                    is_state        <= "1011";
                    if (w >= 19) then
                        w           <= 0;
                        vmm_ena_all     <= '0';
                        sel_cs          <= "00"; -- drive CS to gnd
                        state           <= CONFIGURE;
                    else
                        w <= w + 1;
                    end if;

                when    SEND_CONF_REPLY    =>
                    reply_enable    <= '1';
                    sel_cs          <= "00"; -- drive CS to gnd
                    vmm_ena_all     <= '0'; 
                    if(reply_done = '0')then
                        state        <= SEND_CONF_REPLY;
                    else
                        state        <= IDLE;
                    end if;

                when DAQ_INIT =>
                    is_state                <= "0011";
                    --for I in 1 to 100 loop
                        vmm_cktp_primary    <= '1';
                    --end loop;
                    sel_cs                  <= "11"; -- drive CS high
                    vmm_ena_all             <= '1';
                    tren                    <= '0';
                    daq_vmm_ena_wen_enable  <= x"ff";
                    daq_cktk_out_enable     <= x"ff";
                    daq_enable_i            <= '1';
                    rstFIFO_top             <= '1';
                    pf_reset                <= '1';
                    
                    if(daq_on = '0')then    -- Reset came
                        daq_vmm_ena_wen_enable  <= x"00";
                        daq_cktk_out_enable     <= x"00";
                        daq_enable_i            <= '0';
                        pf_reset                <= '0';
                        state                   <= IDLE;
                    elsif(wait_cnt < "01100100")then
                        wait_cnt    <= wait_cnt + 1;
                        state       <= DAQ_INIT;
                    elsif(wait_cnt = "01100100")then
                        wait_cnt    <= (others => '0');
                        state       <= TRIG;   
                    end if;
                    
                when TRIG =>
                    is_state            <= "0100";
                    vmm_tki             <= '1';
                    vmm_cktp_primary    <= '0';
                    rstFIFO_top         <= '0';
                    pf_reset            <= '0';
                    tren                <= '1';
                    state               <= DAQ;
      
                when DAQ =>
                    is_state            <= "0101";
                    ckbc_enable         <= '1';
                    if(daq_on = '0')then  -- Reset came
                        daq_enable_i    <= '0';
                        state           <= DAQ_INIT;
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
    inhibit_conf            <= '0' when (state = IDLE) else '1';
    vmm_bitmask             <= "11111111";
    
    pf_newCycle             <= tr_out_i;
    CH_TRIGGER_i            <= not CH_TRIGGER;
    TRIGGER_OUT_P           <= art2;
    TRIGGER_OUT_N           <= not art2;
    MO                      <= MO_i;  

    test_data               <= udp_rx_int.data.data_in;
    test_valid              <= udp_rx_int.data.data_in_valid;
    test_last               <= udp_rx_int.data.data_in_last;
    test_data_out           <= udp_txi_int.data.data_out;
    test_valid_out          <= udp_txi_int.data.data_out_valid;
    test_last_out           <= udp_txi_int.data.data_out_last;
    
    fifo_data               <= fifo_data_out_int;
    re_out                  <= re_out_int;

    -- configuration assertion
    vmm_cs_vec_obuf(1)  <= vmm_cs_all and vmm_bitmask(0);
    vmm_cs_vec_obuf(2)  <= vmm_cs_all and vmm_bitmask(1);
    vmm_cs_vec_obuf(3)  <= vmm_cs_all and vmm_bitmask(2);
    vmm_cs_vec_obuf(4)  <= vmm_cs_all and vmm_bitmask(3);
    vmm_cs_vec_obuf(5)  <= vmm_cs_all and vmm_bitmask(4);
    vmm_cs_vec_obuf(6)  <= vmm_cs_all and vmm_bitmask(5);
    vmm_cs_vec_obuf(7)  <= vmm_cs_all and vmm_bitmask(6);
    vmm_cs_vec_obuf(8)  <= vmm_cs_all and vmm_bitmask(7);
    
    vmm_sck_vec_obuf(1) <= vmm_sck_all and vmm_bitmask(0);
    vmm_sck_vec_obuf(2) <= vmm_sck_all and vmm_bitmask(1);
    vmm_sck_vec_obuf(3) <= vmm_sck_all and vmm_bitmask(2);
    vmm_sck_vec_obuf(4) <= vmm_sck_all and vmm_bitmask(3);
    vmm_sck_vec_obuf(5) <= vmm_sck_all and vmm_bitmask(4);
    vmm_sck_vec_obuf(6) <= vmm_sck_all and vmm_bitmask(5);
    vmm_sck_vec_obuf(7) <= vmm_sck_all and vmm_bitmask(6);
    vmm_sck_vec_obuf(8) <= vmm_sck_all and vmm_bitmask(7);
    
    vmm_sdi_vec_obuf(1) <= vmm_sdi_all and vmm_bitmask(0);
    vmm_sdi_vec_obuf(2) <= vmm_sdi_all and vmm_bitmask(1);
    vmm_sdi_vec_obuf(3) <= vmm_sdi_all and vmm_bitmask(2);
    vmm_sdi_vec_obuf(4) <= vmm_sdi_all and vmm_bitmask(3);
    vmm_sdi_vec_obuf(5) <= vmm_sdi_all and vmm_bitmask(4);
    vmm_sdi_vec_obuf(6) <= vmm_sdi_all and vmm_bitmask(5);
    vmm_sdi_vec_obuf(7) <= vmm_sdi_all and vmm_bitmask(6);
    vmm_sdi_vec_obuf(8) <= vmm_sdi_all and vmm_bitmask(7);
    
    vmm_ena_vec_obuf(1) <= vmm_ena_all and vmm_bitmask(0);
    vmm_ena_vec_obuf(2) <= vmm_ena_all and vmm_bitmask(1);
    vmm_ena_vec_obuf(3) <= vmm_ena_all and vmm_bitmask(2);
    vmm_ena_vec_obuf(4) <= vmm_ena_all and vmm_bitmask(3);
    vmm_ena_vec_obuf(5) <= vmm_ena_all and vmm_bitmask(4);
    vmm_ena_vec_obuf(6) <= vmm_ena_all and vmm_bitmask(5);
    vmm_ena_vec_obuf(7) <= vmm_ena_all and vmm_bitmask(6);
    vmm_ena_vec_obuf(8) <= vmm_ena_all and vmm_bitmask(7);

--VIO_inst: vio_1
--    port map(
--        clk         => userclk2,
--        probe_out0  => ckbc_en_vio,
--        probe_out1  => cktp_vio,
--        probe_out2  => tki_vio,
--        probe_out3  => cktk_vio,
--        probe_out4  => ckdt_vio,
--        probe_out5  => cs_vio
--    );
      
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

ila_top: ila_overview
    port map (
        clk     => userclk2,
        probe0  => overviewProbe
    );
    
--VIO_DEFAULT_IP: vio_ip
--      PORT MAP (
--        clk         => clk_50,
--        probe_out0  => default_IP,
--        probe_out1  => default_MAC
--      );

    overviewProbe(3 downto 0)          <= is_state;
    overviewProbe(8 downto 4)          <= pf_dbg_st;
    overviewProbe(12 downto 9)         <= dt_state;
    overviewProbe(16 downto 13)        <= dt_cntr_st;
    overviewProbe(20 downto 17)        <= FIFO2UDP_state;
    overviewProbe(21)                  <= faifouki;
    overviewProbe(22)                  <= UDPDone;
    overviewProbe(23)                  <= CKBC_glbl;
    overviewProbe(24)                  <= tr_out_i;
    overviewProbe(25)                  <= din_valid;
    overviewProbe(28 downto 26)        <= conf_state;
    overviewProbe(30 downto 29)        <= sel_data_vmm;
    overviewProbe(31)                  <= driver_busy;
    overviewProbe(47 downto 32)        <= vmmWord_i;
    overviewProbe(48)                  <= CKTP_glbl;
    overviewProbe(63 downto 49)        <= (others => '0');


    vmmSignalsProbe(7 downto 0)        <= vmm_ena_vec;
    vmmSignalsProbe(15 downto 8)       <= cktk_out_vec;
    vmmSignalsProbe(23 downto 16)      <= ckdt_out_vec;
    vmmSignalsProbe(31 downto 24)      <= data0_in_vec;
    vmmSignalsProbe(32)                <= vmm_cktp;
    vmmSignalsProbe(33)                <= ckdt_out_vec(1);
    vmmSignalsProbe(34)                <= data0_in_vec(1);
    vmmSignalsProbe(35)                <= data1_in_vec(1);
    vmmSignalsProbe(36)                <= vmm_cs_all;
    vmmSignalsProbe(37)                <= vmm_cktp_all;
    vmmSignalsProbe(38)                <= vmm_ena_all;
    vmmSignalsProbe(39)                <= vmm_ena;
    vmmSignalsProbe(40)                <= tko_i;
    vmmSignalsProbe(41)                <= vmm_ena_all;
    vmmSignalsProbe(42)                <= art2;
    vmmSignalsProbe(43)                <= cktk_out_i;
    vmmSignalsProbe(44)                <= art_in_i;
    vmmSignalsProbe(63 downto 45)      <= (others => '0'); 

    triggerETRProbe(0)                <= trint;
    triggerETRProbe(1)                <= tren;
    triggerETRProbe(2)                <= tr_hold;
    triggerETRProbe(3)                <= ext_trigger_in;
    triggerETRProbe(4)                <= trig_mode_int;
    triggerETRProbe(7 downto 5)       <= state_rst_etr_i;
    triggerETRProbe(15 downto 8)      <= etr_vmm_ena_vec;
    triggerETRProbe(23 downto 16)     <= std_logic_vector(to_unsigned(internalTrigger_state, triggerETRProbe(23 downto 16)'length));
    triggerETRProbe(24)               <= rst_etr_i;
    triggerETRProbe(25)               <= etr_reset_latched;
    triggerETRProbe(26)               <= trigger_i;
    triggerETRProbe(38 downto 27)     <= glBCID_i;
    triggerETRProbe(39)               <= CH_TRIGGER_i;
    triggerETRProbe(40)               <= reset_FF;
    triggerETRProbe(63 downto 41)     <= (others => '0'); 

    configurationProbe(0)                <= start_conf_proc_int;
    configurationProbe(1)                <= conf_wen_i;
    configurationProbe(2)                <= conf_di_i;
    configurationProbe(18 downto 3)      <= vmm_id_int;
    configurationProbe(50 downto 19)     <= myIP;
    configurationProbe(63 downto 51)     <= (others => '0');

    readoutProbe(0)                <= pf_newCycle;
    readoutProbe(1)                <= pf_rst_FIFO;
    readoutProbe(4 downto 2)       <= pf_vmmIdRo;
    readoutProbe(5)                <= pfBusy_i;
    readoutProbe(6)                <= rst_vmm;
    readoutProbe(7)                <= daqFIFO_wr_en_i;
    readoutProbe(8)                <= daq_wr_en_i;
    readoutProbe(24 downto 9)      <= vmmWord_i;
    readoutProbe(40 downto 25)     <= daqFIFO_din_i; 
    readoutProbe(63 downto 41)     <= (others => '0');

    dataOutProbe(15 downto 0)      <= daq_data_out_i;
    dataOutProbe(63 downto 16)     <= (others => '0');

    flowProbe(3 downto 0)       <= is_state;
    flowProbe(7 downto 4)       <= (others => '0');
    flowProbe(11 downto 8)      <= (others => '0');
    flowProbe(12)               <= daq_enable_i;
    flowProbe(13)               <= xadc_busy;
    flowProbe(21 downto 14)     <= daq_vmm_ena_wen_enable;
    flowProbe(22)               <= daqFIFO_reset;
    flowProbe(23)               <= rstFIFO_top;
    flowProbe(24)               <= ckbc_enable;
    flowProbe(63 downto 25)     <= (others => '0');     

end Behavioral;
