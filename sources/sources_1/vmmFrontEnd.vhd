-------------------------------------------------------------------------------------
-- Company: NTUA - BNL
-- Engineers: Christos Bakalis, Panagiotis Gkountoumis, Paris Moschovakos
--
-- Copyright Notice/Copying Permission:
--    Copyright 2017 Christos Bakalis, Panagiotis Gkountoumis, Paris Moschovakos
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
-- Create Date: 16.03.2016
-- Design Name: VMM boards firmware
-- Module Name: vmmFrontEnd.vhd
-- Project Name: Depends on the board
-- Target Devices: Artix7 xc7a200t-2fbg484 & xc7a200t-3fbg484 
-- Tool Versions: Vivado 2017.2
--
-- Changelog:
-- 04.08.2016 Added the XADC Component and multiplexer to share fifo UDP Signals (Reid Pinkham)
-- 11.08.2016 Corrected the fifo resets to go through select_data (Reid Pinkham)
-- 16.09.2016 Added Dynamic IP configuration. (Lev Kurilenko)
-- 16.02.2017 Added new configuration component (udp_data_in_handler) (Christos Bakalis)
-- 27.02.2017 Changed main logic clock to 125MHz (Paris)
-- 10.03.2017 Added configurable CKTP/CKBC module. (Christos Bakalis)
-- 12.03.2017 Changed flow_fsm's primary cktp assertion to comply with cktp_gen
-- module. (Christos Bakalis)
-- 14.03.2017 Added register address/value configuration scheme. (Christos Bakalis)
-- 28.03.2017 Changes to accomodate to MMFE8 VMM3. (Christos Bakalis)
-- 31.03.2017 Added 2 CKBC readout mode (Paris)
-- 30.04.2017 Added vmm_readout_wrapper that contains level-0 readout mode besides
-- the pre-existing continuous mode. (Christos Bakalis)
-- 06.06.2017 Added ART readout handling (Paris)
-- 12.06.2017 Added support for MMFE1 board (Paris)
-- 21.06.2017 Added support for GPVMM board (Paris)
-- 22.06.2017 Added ODDRs for VMM clock forwarding optimization. (Christos Bakalis)
-- 22.08.2017 Added e-link wrapper. (Christos Bakalis)
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

entity vmmFrontEnd is
    port(

        -- VMM signals
        --------------------------------------
        DATA0_1_P, DATA0_1_N  : IN std_logic;
        DATA0_2_P, DATA0_2_N  : IN std_logic;
        DATA0_3_P, DATA0_3_N  : IN std_logic;
        DATA0_4_P, DATA0_4_N  : IN std_logic;
        DATA0_5_P, DATA0_5_N  : IN std_logic;
        DATA0_6_P, DATA0_6_N  : IN std_logic;
        DATA0_7_P, DATA0_7_N  : IN std_logic;
        DATA0_8_P, DATA0_8_N  : IN std_logic;

        DATA1_1_P, DATA1_1_N  : IN std_logic;
        DATA1_2_P, DATA1_2_N  : IN std_logic;
        DATA1_3_P, DATA1_3_N  : IN std_logic;
        DATA1_4_P, DATA1_4_N  : IN std_logic;
        DATA1_5_P, DATA1_5_N  : IN std_logic;
        DATA1_6_P, DATA1_6_N  : IN std_logic;
        DATA1_7_P, DATA1_7_N  : IN std_logic;
        DATA1_8_P, DATA1_8_N  : IN std_logic;
        
        ART_1_P, ART_1_N      : IN std_logic;
--        ART_2_P, ART_2_N      : IN std_logic;
--        ART_3_P, ART_3_N      : IN std_logic;
--        ART_4_P, ART_4_N      : IN std_logic;
--        ART_5_P, ART_5_N      : IN std_logic;
--        ART_6_P, ART_6_N      : IN std_logic;
--        ART_7_P, ART_7_N      : IN std_logic;
--        ART_8_P, ART_8_N      : IN std_logic;

        SDO_1                 : IN std_logic;
        SDO_2                 : IN std_logic;
        SDO_3                 : IN std_logic;
        SDO_4                 : IN std_logic;
        SDO_5                 : IN std_logic;
        SDO_6                 : IN std_logic;
        SDO_7                 : IN std_logic;
        SDO_8                 : IN std_logic;

        SDI_1                 : OUT std_logic;
        SDI_2                 : OUT std_logic;
        SDI_3                 : OUT std_logic;
        SDI_4                 : OUT std_logic;
        SDI_5                 : OUT std_logic;
        SDI_6                 : OUT std_logic;
        SDI_7                 : OUT std_logic;
        SDI_8                 : OUT std_logic;

        SCK_1                 : OUT std_logic;
        SCK_2                 : OUT std_logic;
        SCK_3                 : OUT std_logic;
        SCK_4                 : OUT std_logic;
        SCK_5                 : OUT std_logic;
        SCK_6                 : OUT std_logic;
        SCK_7                 : OUT std_logic;
        SCK_8                 : OUT std_logic;

        CS_1                  : OUT std_logic;
        CS_2                  : OUT std_logic;
        CS_3                  : OUT std_logic;
        CS_4                  : OUT std_logic;
        CS_5                  : OUT std_logic;
        CS_6                  : OUT std_logic;
        CS_7                  : OUT std_logic;
        CS_8                  : OUT std_logic;

        ENA_1_P, ENA_1_N      : OUT std_logic;
        ENA_2_P, ENA_2_N      : OUT std_logic;
        ENA_3_P, ENA_3_N      : OUT std_logic;
        ENA_4_P, ENA_4_N      : OUT std_logic;
        ENA_5_P, ENA_5_N      : OUT std_logic;
        ENA_6_P, ENA_6_N      : OUT std_logic;
        ENA_7_P, ENA_7_N      : OUT std_logic;
        ENA_8_P, ENA_8_N      : OUT std_logic;

        CKTK_1_P, CKTK_1_N    : OUT std_logic;
        CKTK_2_P, CKTK_2_N    : OUT std_logic;
        CKTK_3_P, CKTK_3_N    : OUT std_logic;
        CKTK_4_P, CKTK_4_N    : OUT std_logic;
        CKTK_5_P, CKTK_5_N    : OUT std_logic;
        CKTK_6_P, CKTK_6_N    : OUT std_logic;
        CKTK_7_P, CKTK_7_N    : OUT std_logic;
        CKTK_8_P, CKTK_8_N    : OUT std_logic;

        CKTP_1_P, CKTP_1_N    : OUT std_logic;
        CKTP_2_P, CKTP_2_N    : OUT std_logic;
        CKTP_3_P, CKTP_3_N    : OUT std_logic;
        CKTP_4_P, CKTP_4_N    : OUT std_logic;
        CKTP_5_P, CKTP_5_N    : OUT std_logic;
        CKTP_6_P, CKTP_6_N    : OUT std_logic;
        CKTP_7_P, CKTP_7_N    : OUT std_logic;
        CKTP_8_P, CKTP_8_N    : OUT std_logic;
    
        CKBC_1_P, CKBC_1_N    : OUT std_logic;
        CKBC_2_P, CKBC_2_N    : OUT std_logic;
        CKBC_3_P, CKBC_3_N    : OUT std_logic;
        CKBC_4_P, CKBC_4_N    : OUT std_logic;
        CKBC_5_P, CKBC_5_N    : OUT std_logic;
        CKBC_6_P, CKBC_6_N    : OUT std_logic;
        CKBC_7_P, CKBC_7_N    : OUT std_logic;
        CKBC_8_P, CKBC_8_N    : OUT std_logic;
    
        CKDT_1_P, CKDT_1_N    : OUT std_logic;
        CKDT_2_P, CKDT_2_N    : OUT std_logic;
        CKDT_3_P, CKDT_3_N    : OUT std_logic;
        CKDT_4_P, CKDT_4_N    : OUT std_logic;
        CKDT_5_P, CKDT_5_N    : OUT std_logic;
        CKDT_6_P, CKDT_6_N    : OUT std_logic;
        CKDT_7_P, CKDT_7_N    : OUT std_logic;
        CKDT_8_P, CKDT_8_N    : OUT std_logic;

        TKI_P,     TKI_N      : OUT std_logic;
        TKO_P,     TKO_N      : IN  std_logic;

        CKART_1_P, CKART_1_N  : OUT std_logic;
        CKART_2_P, CKART_2_N  : OUT std_logic;
        CKART_3_P, CKART_3_N  : OUT std_logic;
        CKART_4_P, CKART_4_N  : OUT std_logic;
        CKART_5_P, CKART_5_N  : OUT std_logic;
        CKART_6_P, CKART_6_N  : OUT std_logic;
        CKART_7_P, CKART_7_N  : OUT std_logic;
        CKART_8_P, CKART_8_N  : OUT std_logic;

        SETT_P,    SETT_N     : OUT std_logic; 
        SETB_P,    SETB_N     : OUT std_logic;
        CK6B_1_P,  CK6B_1_N   : OUT std_logic;
        CK6B_2_P,  CK6B_2_N   : OUT std_logic;
        CK6B_3_P,  CK6B_3_N   : OUT std_logic;
        CK6B_4_P,  CK6B_4_N   : OUT std_logic;
        CK6B_5_P,  CK6B_5_N   : OUT std_logic;
        CK6B_6_P,  CK6B_6_N   : OUT std_logic;
        CK6B_7_P,  CK6B_7_N   : OUT std_logic;
        CK6B_8_P,  CK6B_8_N   : OUT std_logic;

        -- ADDC ART CLK
        --------------------------------------
        CKART_ADDC_P          : OUT std_logic;
        CKART_ADDC_N          : OUT std_logic;
        
        -- MDT_446/MDT_MU2E Specific Pins
        --------------------------------------
        TRIGGER_OUT_P         : OUT std_logic;
        TRIGGER_OUT_N         : OUT std_logic;
        CH_TRIGGER            : IN  std_logic;
        MO                    : OUT std_logic;
        ART_OUT_P,  ART_OUT_N : OUT std_logic;

        -- xADC Interface
        --------------------------------------
        VP_0                  : IN std_logic;
        VN_0                  : IN std_logic;
        Vaux0_v_n             : IN std_logic;
        Vaux0_v_p             : IN std_logic;
        Vaux1_v_n             : IN std_logic;
        Vaux1_v_p             : IN std_logic;
        Vaux2_v_n             : IN std_logic;
        Vaux2_v_p             : IN std_logic;
        Vaux3_v_n             : IN std_logic;
        Vaux3_v_p             : IN std_logic;
        Vaux8_v_n             : IN std_logic;
        Vaux8_v_p             : IN std_logic;
        Vaux9_v_n             : IN std_logic;
        Vaux9_v_p             : IN std_logic;
        Vaux10_v_n            : IN std_logic;
        Vaux10_v_p            : IN std_logic;
        Vaux11_v_n            : IN std_logic;
        Vaux11_v_p            : IN std_logic;

        MuxAddr0              : OUT std_logic;
        MuxAddr1              : OUT std_logic;
        MuxAddr2              : OUT std_logic;
        MuxAddr3_p            : OUT std_logic;
        MuxAddr3_n            : OUT std_logic;
        
        -- 200.0359MHz from bank 14
        --------------------------------------
        X_2V5_DIFF_CLK_P      : IN std_logic;
        X_2V5_DIFF_CLK_N      : IN std_logic;

        -- Tranceiver interface
        --------------------------------------
        gtrefclk_p            : IN  std_logic;                     -- Differential +ve of reference clock for tranceiver: 125MHz, very high quality
        gtrefclk_n            : IN  std_logic;                     -- Differential -ve of reference clock for tranceiver: 125MHz, very high quality
        txp                   : OUT std_logic;                     -- Differential +ve of serial transmission from PMA to PMD.
        txn                   : OUT std_logic;                     -- Differential -ve of serial transmission from PMA to PMD.
        rxp                   : IN  std_logic;                     -- Differential +ve for serial reception from PMD to PMA.
        rxn                   : IN  std_logic;                     -- Differential -ve for serial reception from PMD to PMA.
        phy_int               : OUT std_logic;
        phy_rstn_out          : OUT std_logic;

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
        ELINK_DAQ_CLK_P       : OUT    STD_LOGIC;
        ELINK_DAQ_CLK_N       : OUT    STD_LOGIC;
        --ELINK_TTC_CLK_P       : IN    STD_LOGIC;
        --ELINK_TTC_CLK_N       : IN    STD_LOGIC;
        
        -- E-link MMCM locked LED
        LED_LOCKED            : OUT   STD_LOGIC;
        -- E-link overflow LED
        LED_ERROR_0           : OUT   STD_LOGIC;  
        LED_ERROR_1           : OUT   STD_LOGIC;
        LED_ERROR_2           : OUT   STD_LOGIC;
        LED_ERROR_3           : OUT   STD_LOGIC;
        
        -- AXI4SPI Flash Configuration
        ---------------------------------------
        IO0_IO                : INOUT std_logic;
        IO1_IO                : INOUT std_logic;
        SS_IO                 : INOUT std_logic
      );
end vmmFrontEnd;

architecture Behavioral of vmmFrontEnd is

    -------------------------------------------------------------------
    -- Global Settings
    ------------------------------------------------------------------- 
    -- Default IP and MAC address of the board
    signal default_IP       : std_logic_vector(31 downto 0) := x"c0a80003";
    signal default_MAC      : std_logic_vector(47 downto 0) := x"002320145223";
    signal default_destIP   : std_logic_vector(31 downto 0) := x"c0a80010";
    -- Set to '1' for MMFE8 or '0' for 1-VMM boards
    constant is_mmfe8       : std_logic := '1';
    -- Set to '0' for continuous readout mode or '1' for L0 readout mode
    constant vmmReadoutMode : std_logic := '1';
    -- Set to '1' to enable the ART header
    constant artEnabled     : std_logic := '1';

    -------------------------------------------------------------------
    -- Transceiver, TEMAC, UDP_ICMP block
    ------------------------------------------------------------------- 

    -- clock generation signals for transceiver
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
    signal phy_rstn              : std_logic := '0';
    
    -- Extra registers to ease IOB placement
    signal status_vector_int           : std_logic_vector(15 downto 0);
    
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
    signal glbl_rstn                   : std_logic := '1';
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
    signal sgmii_clk_int_oddr          : std_logic;
    signal udp_txi_int                 : udp_tx_type;
    signal control                     : udp_control_type;
    signal udp_rx_int                  : udp_rx_type;
    signal ip_rx_hdr_int               : ipv4_rx_header_type;
    signal udp_tx_data_out_ready_int   : std_logic;
    signal udp_tx_start_int            : std_logic;
    signal icmp_rx_start               : std_logic;
    signal icmp_rxo                    : icmp_rx_type;
    signal user_data_out_i             : std_logic_vector(15 downto 0);
    signal end_packet_i                : std_logic := '0';    
    signal we_conf_int                 : std_logic := '0';    
    signal packet_length_int           : std_logic_vector(11 downto 0);
    signal daq_data_out_i              : std_logic_vector(15 downto 0);
    signal daq_wr_en_i                 : std_logic := '0';    
    signal start_conf_proc_int         : std_logic := '0';

    -------------------------------------------------
    -- VMM/FPGA Configuration Signals
    -------------------------------------------------
    signal vmm_sdo_vec_i      : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_cs_all         : std_logic := '0'; 
    signal vmm_sck_all        : std_logic := '0';
    signal vmm_sdi_all        : std_logic := '0';
    signal vmm_bitmask        : std_logic_vector(7 downto 0) := "11111111";
    signal vmm_bitmask_1VMM   : std_logic_vector(7 downto 0) := "11111111";
    signal vmm_bitmask_8VMM   : std_logic_vector(7 downto 0) := "11111111";
    signal sel_cs             : std_logic_vector(1 downto 0) := (others => '0');
    signal VMM_CS_i           : std_logic := '0';
    signal vmm_cs_vec_obuf    : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_sck_vec_obuf   : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_ena_vec_obuf   : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_sdi_vec_obuf   : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_ckbc_vec       : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_cktp_vec       : std_logic_vector(8 downto 1) := (others => '0');
    signal ckart_vec          : std_logic_vector(9 downto 1) := (others => '0');  
    signal conf_di_i          : std_logic := '0';
    signal conf_ena_i         : std_logic := '0';
    signal conf_wen_i         : std_logic := '0';
    signal cnt_vmm            : integer range 0 to 7 := 0;
    signal tko_i              : std_logic; 
    signal MO_i               : std_logic := 'Z';
    signal end_packet_conf_int: std_logic := '0';
    signal end_packet_daq_int : std_logic := '0';
    signal is_state           : std_logic_vector(3 downto 0)  := "1010";
    signal latency_conf       : std_logic_vector(15 downto 0) := x"0000";
    signal art_cnt2           : integer range 0 to 127 := 0;
    signal art2               : std_logic := '0';
    signal reset_FF           : std_logic := '0';
    signal wait_cnt           : unsigned(7 downto 0) := (others => '0');
    signal vmm_id_rdy         : std_logic := '0';
    signal vmm_conf           : std_logic := '0';
    signal newIP_rdy          : std_logic := '0';
    signal xadc_conf_rdy      : std_logic := '0';
    signal daq_on             : std_logic := '0';
    signal vmmConf_done       : std_logic := '0';
    signal flash_busy         : std_logic := '0';
    signal inhibit_conf       : std_logic := '0';
    signal conf_state         : std_logic_vector(2 downto 0) := b"000";
    signal serial_number      : std_logic_vector(31 downto 0) := x"00000000";
    signal packet_len_conf    : std_logic_vector(11 downto 0) := x"000";
    signal fpga_rst_i         : std_logic := '0';
    signal reply_done         : std_logic := '0';
    signal reply_enable       : std_logic := '0';
    signal glbl_fifo_init     : std_logic := '1'; --synced@200Mhz
    signal glbl_fifo_init_s0  : std_logic := '1';
    signal glbl_fifo_init_s1  : std_logic := '1'; --synced@125Mhz

    -------------------------------------------------
    -- VMM Signals                   
    -------------------------------------------------
    signal cktk_out_vec     : std_logic_vector(8 downto 1);
    signal ckdt_out_vec     : std_logic_vector(8 downto 1);
    signal data0_in_vec     : std_logic_vector(8 downto 1);
    signal data1_in_vec     : std_logic_vector(8 downto 1);
    signal art_in_vec       : std_logic_vector(8 downto 1) := (others => '0');
    signal vmm_tki          : std_logic := '0';
    signal vmm_cktp_primary : std_logic := '0';
    signal CKTP_glbl        : std_logic := '0';       
    signal vmm_ena_all      : std_logic := '0';

    -------------------------------------------------
    -- Readout Signals
    -------------------------------------------------
    signal daq_enable_i             : std_logic := '0';
    signal daqFIFO_wr_en_i          : std_logic := '0';
    signal daqFIFO_din_i            : std_logic_vector(15 downto 0);
    signal vmmWordReady_i           : std_logic := '0';
    signal vmmWord_i                : std_logic_vector(15 downto 0);
    signal vmmEventDone_i           : std_logic := '0';
    signal daqFIFO_reset            : std_logic := '0';
    signal daq_vmm_ena_wen_enable   : std_logic_vector(8 downto 1) := (others => '0');
    signal daq_cktk_out_enable      : std_logic_vector(8 downto 1) := (others => '0');
    signal linkHealth_bmsk          : std_logic_vector(8 downto 1) := (others => '0');
    signal linkHealth_bmsk_i        : std_logic_vector(7 downto 0) := (others => '0');
    signal UDPDone                  : std_logic;
    signal ckbc_enable              : std_logic := '0';
    signal cktp_enable              : std_logic := '0';
    signal dt_state                 : std_logic_vector(3 downto 0) := b"0000";
    signal dt_cntr_st               : std_logic_vector(3 downto 0) := b"0000";
    signal rst_l0_buff              : std_logic := '0';
    signal rst_l0_buff_flow         : std_logic := '1';
    signal rst_l0_pf                : std_logic := '0';
    signal level_0                  : std_logic := '0';
    signal daq_on_inhib             : std_logic := '1';
    signal CKDT_glbl                : std_logic := '0';
    signal ro_rdy                   : std_logic := '0';
    signal vmm_ckdt_enable          : std_logic_vector(8 downto 1) := (others => '0');
    
    -------------------------------------------------
    -- Trigger Signals
    -------------------------------------------------
    signal tren               : std_logic := '0';
    signal tr_hold            : std_logic := '0';
    signal trmode             : std_logic := '0';
    signal ext_trigger_in     : std_logic := '0';
    signal tr_reset           : std_logic := '0';
    signal tr_out_i           : std_logic;
    signal trig_mode_int      : std_logic := '0';   
    signal CH_TRIGGER_i       : std_logic := '0';
    signal request2ckbc       : std_logic := '0';
    signal trraw_synced125_i  : std_logic := '0';
    signal accept_wr          : std_logic := '0';
    signal vmmArtData         : std_logic_vector(5 downto 0) := (others => '0');
    signal vmmArtReady        : std_logic := '0';
  
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
    signal pf_rst_flow  : std_logic := '0';
    signal rst_vmm      : std_logic := '0';
    signal pf_rst_FIFO  : std_logic := '0';
    signal pfBusy_i     : std_logic := '0';
    signal pf_dbg_st    : std_logic_vector(4 downto 0) := b"00000";
    signal rd_ena_buff  : std_logic := '0';
    signal pf_rst_final : std_logic := '0';
    signal pfInhibit_i  : std_logic := '0';
    signal pfReady_i    : std_logic := '0';
    
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
    -- MMCM + CKBC/CKTP Generator signals
    ------------------------------------------------------------------ 
    signal clk_160          : std_logic := '0';
    signal clk_500          : std_logic := '0';
    signal clk_200          : std_logic := '0';
    signal clk_40           : std_logic := '0';
    signal clk_50           : std_logic := '0';
    signal clk_320          : std_logic := '0';
    signal clk_80           : std_logic := '0';    
    signal master_locked    : std_logic := '0';
    signal CKBC_glbl        : std_logic := '0';
    signal cktp_pulse_width : std_logic_vector(7 downto 0)     := x"04"; -- 2 us
    signal cktp_period      : std_logic_vector(15 downto 0)    := x"1388"; -- 1 ms
    signal cktp_skew        : std_logic_vector(7 downto 0)     := (others => '0'); 
    signal ckbc_freq        : std_logic_vector(7 downto 0)     := x"28"; --40 Mhz
    signal cktp_max_num     : std_logic_vector(15 downto 0)    := x"ffff";
    signal cktk_max_num     : std_logic_vector(7 downto 0)     := x"07";
    signal ckbcMode         : std_logic := '0';
    signal CKTP_raw         : std_logic := '0';
    signal ckbc_max_num     : std_logic_vector(7 downto 0)     := x"20";
    
    ------------------------------------------------------------------
    -- E-LINK signals
    ------------------------------------------------------------------ 
    signal rst_elink_mmcm       : std_logic := '0';
    signal rst_elink_glbl       : std_logic := '0';
    signal rst_elink_rx         : std_logic := '0';
    signal swap_rx              : std_logic := '0';
    
    signal elink_DAQ_tx         : std_logic := '0';
    signal elink_DAQ_rx         : std_logic := '0';
    signal trigger_cnt          : std_logic_vector(15 downto 0) := (others => '0');
    signal bitmask_null         : std_logic_vector(7 downto 0)  := (others => '0');
    signal enable_led           : std_logic := '0';
    signal test_led             : std_logic := '0';
    signal enable_led_final     : std_logic := '0';
    signal led_out              : std_logic_vector(3 downto 0)  := (others => '0');
    
    -------------------------------------------------
    -- Flow FSM signals
    -------------------------------------------------
    type state_t is (IDLE, WAIT_FOR_CONF, CONFIGURE, CONF_DONE, CONFIGURE_DELAY, SEND_CONF_REPLY, DAQ_INIT, FIRST_RESET, TRIG, DAQ, XADC_init, XADC_wait, FLASH_init, FLASH_wait);
    signal state        : state_t := IDLE;
    signal rstFIFO_flow : std_logic := '0';
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

    -------------------------------------------------------------------
    -- These attribute will stop timing errors being reported in back
    -- annotated SDF simulation.
    -------------------------------------------------------------------
    attribute ASYNC_REG                         : string;
    attribute ASYNC_REG of pma_reset_pipe       : signal is "TRUE";
    attribute ASYNC_REG of glbl_fifo_init_s0    : signal is "TRUE";
    attribute ASYNC_REG of glbl_fifo_init_s1    : signal is "TRUE";
  
    -------------------------------------------------------------------
    -- Keep signals for ILA
    -------------------------------------------------------------------
    attribute keep          : string;
    attribute dont_touch    : string;
    attribute mark_debug    : string;

    -------------------------------------------------------------------
    -- IOB attribute for VMM pins
    -------------------------------------------------------------------
    attribute IOB               : string;

    -- data0
    attribute IOB of DATA0_1_P  : signal is "TRUE";
    attribute IOB of DATA0_1_N  : signal is "TRUE";
    attribute IOB of DATA0_2_P  : signal is "TRUE";
    attribute IOB of DATA0_2_N  : signal is "TRUE";
    attribute IOB of DATA0_3_P  : signal is "TRUE";
    attribute IOB of DATA0_3_N  : signal is "TRUE";
    attribute IOB of DATA0_4_P  : signal is "TRUE";
    attribute IOB of DATA0_4_N  : signal is "TRUE";

    attribute IOB of DATA0_5_P  : signal is "TRUE";
    attribute IOB of DATA0_5_N  : signal is "TRUE";
    attribute IOB of DATA0_6_P  : signal is "TRUE";
    attribute IOB of DATA0_6_N  : signal is "TRUE";
    attribute IOB of DATA0_7_P  : signal is "TRUE";
    attribute IOB of DATA0_7_N  : signal is "TRUE";
    attribute IOB of DATA0_8_P  : signal is "TRUE";
    attribute IOB of DATA0_8_N  : signal is "TRUE";

    -- data1
    attribute IOB of DATA1_1_P  : signal is "TRUE";
    attribute IOB of DATA1_1_N  : signal is "TRUE";
    attribute IOB of DATA1_2_P  : signal is "TRUE";
    attribute IOB of DATA1_2_N  : signal is "TRUE";
    attribute IOB of DATA1_3_P  : signal is "TRUE";
    attribute IOB of DATA1_3_N  : signal is "TRUE";
    attribute IOB of DATA1_4_P  : signal is "TRUE";
    attribute IOB of DATA1_4_N  : signal is "TRUE";

    attribute IOB of DATA1_5_P  : signal is "TRUE";
    attribute IOB of DATA1_5_N  : signal is "TRUE";
    attribute IOB of DATA1_6_P  : signal is "TRUE";
    attribute IOB of DATA1_6_N  : signal is "TRUE";
    attribute IOB of DATA1_7_P  : signal is "TRUE";
    attribute IOB of DATA1_7_N  : signal is "TRUE";
    attribute IOB of DATA1_8_P  : signal is "TRUE";
    attribute IOB of DATA1_8_N  : signal is "TRUE";

    -- cktk
    attribute IOB of CKTK_1_P   : signal is "TRUE";
    attribute IOB of CKTK_1_N   : signal is "TRUE";
    attribute IOB of CKTK_2_P   : signal is "TRUE";
    attribute IOB of CKTK_2_N   : signal is "TRUE";
    attribute IOB of CKTK_3_P   : signal is "TRUE";
    attribute IOB of CKTK_3_N   : signal is "TRUE";
    attribute IOB of CKTK_4_P   : signal is "TRUE";
    attribute IOB of CKTK_4_N   : signal is "TRUE";

    attribute IOB of CKTK_5_P   : signal is "TRUE";
    attribute IOB of CKTK_5_N   : signal is "TRUE";
    attribute IOB of CKTK_6_P   : signal is "TRUE";
    attribute IOB of CKTK_6_N   : signal is "TRUE";
    attribute IOB of CKTK_7_P   : signal is "TRUE";
    attribute IOB of CKTK_7_N   : signal is "TRUE";
    attribute IOB of CKTK_8_P   : signal is "TRUE";
    attribute IOB of CKTK_8_N   : signal is "TRUE";

    -- sdi
    attribute IOB of SDI_1      : signal is "TRUE";
    attribute IOB of SDI_2      : signal is "TRUE";
    attribute IOB of SDI_3      : signal is "TRUE";
    attribute IOB of SDI_4      : signal is "TRUE";
    attribute IOB of SDI_5      : signal is "TRUE";
    attribute IOB of SDI_6      : signal is "TRUE";
    attribute IOB of SDI_7      : signal is "TRUE";
    attribute IOB of SDI_8      : signal is "TRUE";
 
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
--    attribute mark_debug of is_state                  : signal is "TRUE";
--    attribute mark_debug of pf_dbg_st                 : signal is "TRUE";
--    attribute mark_debug of FIFO2UDP_state            : signal is "TRUE";
--    attribute mark_debug of UDPDone                   : signal is "TRUE";
--    attribute mark_debug of tr_out_i                  : signal is "TRUE";
--    attribute mark_debug of rd_ena_buff               : signal is "TRUE";
--    attribute mark_debug of level_0                   : signal is "TRUE";
--    attribute mark_debug of rst_l0_pf                 : signal is "TRUE";
--    attribute mark_debug of vmmWordReady_i            : signal is "TRUE";
--    attribute mark_debug of vmmEventDone_i            : signal is "TRUE";
--    attribute mark_debug of dt_state                  : signal is "TRUE";
--    attribute mark_debug of daq_data_out_i            : signal is "TRUE";
--    attribute mark_debug of daq_enable_i              : signal is "TRUE";
--    attribute mark_debug of pf_trigVmmRo              : signal is "TRUE";
--    attribute mark_debug of dt_cntr_st                : signal is "TRUE";
--    attribute mark_debug of linkHealth_bmsk           : signal is "TRUE";
    
    -------------------------------------------------------------------
    -- Other
    -------------------------------------------------------------------   
    
    -------------------------------------------------------------------
    --                       COMPONENTS                              --
    -------------------------------------------------------------------
    -- 1. clk_wiz_gen
    -- 2. event_timing_reset
    -- 3. vmm_readout_wrapper
    -- 4. FIFO2UDP
    -- 5. trigger
    -- 6. packet_formation
    -- 7. gig_ethernet_pcs_pma_0
    -- 8. UDP_Complete_nomac
    -- 9. temac_10_100_1000_fifo_block
    -- 10. temac_10_100_1000_reset_sync
    -- 11. temac_10_100_1000_config_vector_sm
    -- 12. i2c_top
    -- 13. udp_data_in_handler
    -- 14. udp_reply_handler
    -- 15. select_data
    -- 16. ila_top_level
    -- 17. xadc
    -- 18. AXI4_SPI
    -- 19. VIO_IP
    -- 20. clk_gen_wrapper
    -- 21. ila_overview
    -- 22. art
    -- 23. vmm_oddr_wrapper
    -- 24. elink_wrapper
    -- 25. vio_elink
    -- 26. led
    -------------------------------------------------------------------
    -- 1
    component clk_wiz_gen
    port
     (  -- Clock in ports
        clk_in1_p         : in  std_logic;
        clk_in1_n         : in  std_logic;
        -- Clock out ports
        clk_out_160       : out std_logic;
        clk_out_500       : out std_logic;
        clk_out_200       : out std_logic;
        clk_out_50        : out std_logic;
        clk_out_40        : out std_logic;
        clk_out_80        : out std_logic;
        clk_out_320       : out std_logic;
        -- Status and control signals
        reset             : in  std_logic;
        gen_locked        : out std_logic
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
    component vmm_readout_wrapper is
        generic(is_mmfe8        : std_logic;
                vmmReadoutMode  : std_logic);
        port ( 
            ------------------------------------
            --- Continuous Readout Interface ---
            clkTkProc       : in  std_logic;                    -- Used to clock checking for data process
            clkDtProc       : in  std_logic;                    -- Used to clock word readout process
            clk             : in  std_logic;                    -- Main clock
            --
            daq_enable      : in  std_logic;
            trigger_pulse   : in  std_logic;                     -- Trigger
            cktk_max        : in  std_logic_vector(7 downto 0);  -- Max number of CKTKs
            --
            dt_state_o      : out std_logic_vector(3 downto 0); -- for debugging
            dt_cntr_st_o    : out std_logic_vector(3 downto 0); -- for debugging
            ------------------------------------
            ---- Level-0 Readout Interface -----
            clk_ckdt        : in  std_logic;                    -- will be forwarded to the VMM
            rst_buff        : in  std_logic;                    -- reset the level-0 buffer
            rst_intf_proc   : in  std_logic;                    -- reset the pf interface
            --
            level_0         : in  std_logic;                    -- level-0 signal
            wr_accept       : in  std_logic;                    -- buffer acceptance window
            --
            vmm_conf        : in  std_logic;                    -- high during VMM configuration
            daq_on_inhib    : out std_logic;                    -- prevent daq_on state before checking link health
            --
            null_event      : out std_logic_vector(7 downto 0); -- bitmask for elink module
            all_ready       : out std_logic;                    -- for elink and packet formation
            ------------------------------------
            ---- Packet Formation Interface ----
            vmmWordReady    : out std_logic;
            vmmWord         : out std_logic_vector(15 downto 0);
            vmmEventDone    : out std_logic;
            rd_ena_buff     : in  std_logic;                     -- read the readout buffer (level0 or continuous)
            vmmId           : in  std_logic_vector(2 downto 0);  -- VMM to be readout
            linkHealth_bmsk : out std_logic_vector(8 downto 1);  -- status of comma alignment links
            ------------------------------------
            ---------- VMM3 Interface ----------
            vmm_data0_vec   : in  std_logic_vector(8 downto 1);  -- Single-ended data0 from VMM
            vmm_data1_vec   : in  std_logic_vector(8 downto 1);  -- Single-ended data1 from VMM
            vmm_ckdt_glbl   : out std_logic;                     -- Strobe to VMM CKDT
            vmm_ckdt_enable : out std_logic_vector(8 downto 1);  -- Enable signal for VMM CKDT
            vmm_cktk_vec    : out std_logic_vector(8 downto 1)   -- Strobe to VMM CKTK
        );
    end component;
    -- 4
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
            confReply_packet            : in  std_logic;
                                
            trigger_out                 : out std_logic;
            count_o                     : out std_logic_vector(3 downto 0);
            faifouki                    : out std_logic
        );
    end component;
    -- 5
    component trigger is
      generic (vmmReadoutMode : std_logic);
      port (
          clk             : in std_logic;
          ckbc            : in std_logic;
          clk_art         : in std_logic;
          rst_trig        : in std_logic;
          
          ckbcMode        : in std_logic;
          cktp_enable     : in std_logic;
          cktp_pulse_width: in std_logic_vector(4 downto 0);
          CKTP_raw        : in std_logic;
          request2ckbc    : out std_logic;
          accept_wr       : out std_logic;
          pfBusy          : in std_logic;
          
          tren            : in std_logic;
          tr_hold         : in std_logic;
          trmode          : in std_logic;
          trext           : in std_logic;
          reset           : in std_logic;
          level_0         : out std_logic;
          
          
          event_counter   : out std_logic_vector(31 DOWNTO 0);
          tr_out          : out std_logic;
          trraw_synced125 : out std_logic;
          latency         : in std_logic_vector(15 DOWNTO 0)
      );
    end component;
    -- 6
    component packet_formation is
    generic(is_mmfe8        : std_logic;
            vmmReadoutMode  : std_logic;
            artEnabled      : std_logic);
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
            
            rd_ena_buff     : out std_logic;
            rst_l0          : out std_logic;
            
            tr_hold         : out std_logic;
            reset           : in std_logic;
            rst_vmm         : out std_logic;
            linkHealth_bmsk : in std_logic_vector(8 downto 1);
            rst_FIFO        : out std_logic;
            
            elink_inhibit   : in  std_logic; -- elink inhibitor
            pf_rdy          : out std_logic; -- pf is ready to send vmm data
            ro_rdy          : in  std_logic; -- all readout modules ready
            trigger_cnt     : out std_logic_vector(15 downto 0);
            
            latency         : in std_logic_vector(15 downto 0);
            dbg_st_o        : out std_logic_vector(4 downto 0);
            
            trraw_synced125 : in std_logic;
            vmmArtData125   : in std_logic_vector(5 downto 0);
            vmmArtReady     : in std_logic
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
            rx_clk                  : in  std_logic;
            tx_clk                  : in  std_logic;
            reset                   : in  std_logic;
            fifo_init               : in  std_logic;
            our_ip_address          : in std_logic_VECTOR (31 downto 0);
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
        rst_fifo_init       : in  std_logic;
        state_o             : out std_logic_vector(2 downto 0);
        valid_o             : out std_logic;
        ------------------------------------
        -------- FPGA Config Interface -----
        latency             : out std_logic_vector(15 downto 0);
        serial_number       : out std_logic_vector(31 downto 0);
        daq_on              : out std_logic;
        ext_trigger         : out std_logic;
        ckbcMode            : out std_logic;
        fpga_rst            : out std_logic;
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
        ckbc_max_num        : out std_logic_vector(7 downto 0);
        ------------------------------------
        ------ VMM Config Interface --------
        vmm_bitmask         : out std_logic_vector(7 downto 0);
        vmmConf_came        : out std_logic;
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
    -- 14
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
    -- 15
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
    -- 16
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
    -- 17
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
    -- 18
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
        
        io0_i : IN std_logic;
        io0_o : OUT std_logic;
        io0_t : OUT std_logic;
        io1_i : IN std_logic;
        io1_o : OUT std_logic;
        io1_t : OUT std_logic;
        ss_i : IN std_logic_vector(0 DOWNTO 0);
        ss_o : OUT std_logic_vector(0 DOWNTO 0);
        ss_t : OUT std_logic
    );
    end component;
    -- 19
    COMPONENT vio_ip
      PORT (
        clk        : IN std_logic;
        probe_out0 : OUT std_logic_VECTOR(31 DOWNTO 0);
        probe_out1 : OUT std_logic_VECTOR(47 DOWNTO 0)
      );
    END COMPONENT;
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
    end component;
    -- 21
    component ila_overview
    Port(
        clk     : in std_logic;
        probe0  : in std_logic_vector(63 downto 0)
    );
    end component;
    -- 22
    component artReadout --art_instance
    generic( is_mmfe8   : std_logic;
            artEnabled  : std_logic);
    Port(
        clk             : in std_logic;
        clk_art         : in std_logic;
        trigger         : in std_logic;
        artData         : in std_logic_vector(8 downto 1);
        vmmArtData125   : out std_logic_vector(5 downto 0);
        vmmArtReady     : out std_logic
    );
    end component;
    -- 23
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
    -- 24
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
        error_led       : out std_logic;  -- rx data flow is too high  
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
        -------- UDP Interface ----------
        udp_tx_dout_rdy : in std_logic;
        udp_tx_start    : out std_logic;
        udp_txi         : out udp_tx_type;
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
    end component;
    --25
COMPONENT vio_elink
      PORT (
        clk : in std_logic;
        probe_in0 : in std_logic_vector(0 downto 0);
        probe_out0 : out std_logic_vector(0 downto 0);
        probe_out1 : out std_logic_vector(0 downto 0);
        probe_out2 : out std_logic_vector(0 downto 0);
        probe_out3 : out std_logic_vector(0 downto 0)
      );
    END COMPONENT;

COMPONENT led
 PORT ( clk,enable : in std_logic;
        led_out     : out  std_logic_vector (3 downto 0)
         );
END COMPONENT;

begin
    
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

   -----------------------------------------------------------------------------
   -- Transceiver PMA reset circuitry
   -----------------------------------------------------------------------------

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
      reset                => '0',
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
            fifo_init                   => glbl_fifo_init,
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
       port map(  
            clk_in                => clk_200,
            phy_rstn_out          => phy_rstn
        );

udp_din_conf_block: udp_data_in_handler
    port map(
        ------------------------------------
        ------- General Interface ----------
        clk_125             => userclk2,
        clk_40              => clk_40,
        inhibit_conf        => inhibit_conf,
        rst                 => glbl_rst_i,
        rst_fifo_init       => glbl_fifo_init_s1,
        state_o             => conf_state,
        valid_o             => open,
        ------------------------------------
        -------- FPGA Config Interface -----
        latency             => latency_conf,
        serial_number       => serial_number,
        daq_on              => daq_on,
        ext_trigger         => trig_mode_int,
        ckbcMode            => ckbcMode,
        fpga_rst            => glbl_rst_i,
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
        ckbc_max_num        => ckbc_max_num,
        ------------------------------------
        ------ VMM Config Interface --------
        vmm_bitmask         => vmm_bitmask_8VMM,
        vmmConf_came        => vmm_conf,
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

mmcm_master: clk_wiz_gen    
    port map (
        -- Clock in ports
        clk_in1_p   => X_2V5_DIFF_CLK_P, --X_2V5_DIFF_CLK_N
        clk_in1_n   => X_2V5_DIFF_CLK_N,
        -- Clock out ports  
        clk_out_160 => clk_160,
        clk_out_320 => clk_320,
        clk_out_500 => clk_500,
        clk_out_200 => clk_200,
        clk_out_50  => clk_50,
        clk_out_40  => clk_40,
        clk_out_80  => clk_80,
        -- Status and control signals                
        reset       => '0',
        gen_locked  => master_locked
    );

led_blink_inst: led
 PORT MAP( clk  => userclk2,
           enable => enable_led_final,
           led_out => led_out 
         );

--event_timing_reset_instance: event_timing_reset
--    port map(
--        hp_clk          => '0', --clk_800
--        clk             => userclk2,
--        clk_10_phase45  => '0', --clk_10_phase45
--        bc_clk          => '0', --clk_10

--        daqEnable       => daq_enable_i,
--        pfBusy          => pfBusy_i,
--        reset           => rst_vmm,

--        glBCID          => glBCID_i,
--        prec_cnt        => open,

--        state_rst_out   => state_rst_etr_i,
--        rst_o           => rst_etr_i,
--        rst_done_o      => rst_done_etr_i,

--        vmm_ena_vec     => open,
--        vmm_wen_vec     => open,
--        reset_latched   => etr_reset_latched
--    );

--readout_vmm: vmm_readout_wrapper
--    generic map(is_mmfe8 => is_mmfe8, vmmReadoutMode => vmmReadoutMode)
--    port map(
--        ------------------------------------
--        --- Continuous Readout Interface ---
--        clkTkProc       => clk_40,
--        clkDtProc       => clk_50,
--        clk             => userclk2,
--        --
--        daq_enable      => daq_enable_i,
--        trigger_pulse   => pf_trigVmmRo,
--        cktk_max        => cktk_max_num,
--        --
--        dt_state_o      => dt_state,
--        dt_cntr_st_o    => dt_cntr_st,
--        ------------------------------------
--        ---- Level-0 Readout Interface -----
--        clk_ckdt        => clk_160,
--        rst_buff        => rst_l0_buff,
--        rst_intf_proc   => rst_l0_pf,
--        --
--        level_0         => level_0,
--        wr_accept       => accept_wr,
--        --
--        vmm_conf        => conf_wen_i,
--        daq_on_inhib    => daq_on_inhib, -- synced to flow_fsm's clock
--        --
--        null_event      => bitmask_null,
--        all_ready       => ro_rdy,
--        ------------------------------------
--        ---- Packet Formation Interface ----
--        vmmWordReady    => vmmWordReady_i,
--        vmmWord         => vmmWord_i,
--        rd_ena_buff     => rd_ena_buff,
--        vmmEventDone    => vmmEventDone_i,
--        vmmId           => pf_vmmIdRo,
--        linkHealth_bmsk => linkHealth_bmsk,
--        ------------------------------------
--        ---------- VMM3 Interface ----------
--        vmm_data0_vec   => data0_in_vec,
--        vmm_data1_vec   => data1_in_vec,
--        vmm_ckdt_glbl   => CKDT_glbl,
--        vmm_ckdt_enable => vmm_ckdt_enable,
--        vmm_cktk_vec    => cktk_out_vec
--    );

--trigger_instance: trigger
--    generic map(vmmReadoutMode => vmmReadoutMode)
--    port map(
--        clk             => userclk2,
--        ckbc            => CKBC_glbl,
--        clk_art         => clk_160,
--        rst_trig        => glbl_rst_i,
        
--        ckbcMode        => ckbcMode,
--        request2ckbc    => request2ckbc,
--        cktp_enable     => cktp_enable,
--        CKTP_raw        => CKTP_raw,
--        pfBusy          => pfBusy_i,
--        cktp_pulse_width=> cktp_pulse_width(4 downto 0),
        
--        tren            => tren,                -- Trigger module enabled
--        tr_hold         => tr_hold,             -- Prevents trigger while high
--        trmode          => trig_mode_int,       -- Mode 0: internal / Mode 1: external
--        trext           => CH_TRIGGER_i,        -- External trigger is to be driven to this port
--        level_0         => level_0,              -- Level-0 accept signal
--        accept_wr       => accept_wr,

--        reset           => tr_reset,

--        event_counter   => open,
--        tr_out          => tr_out_i,
--        trraw_synced125 => trraw_synced125_i,
--        latency         => latency_conf
--    );

--FIFO2UDP_instance: FIFO2UDP
--    Port map( 
--        clk_125                     => userclk2,
--        destinationIP               => destIP,
--        daq_data_in                 => daqFIFO_din_i,
--        fifo_data_out               => open,
--        udp_txi                     => udp_txi_int,    
--        udp_tx_start                => udp_tx_start_int,
--        control                     => control.ip_controls.arp_controls.clear_cache,
--        UDPDone                     => UDPDone,   
--        re_out                      => open,    
--        udp_tx_data_out_ready       => udp_tx_data_out_ready_int,
--        wr_en                       => daqFIFO_wr_en_i,
--        end_packet                  => end_packet_i,
--        global_reset                => glbl_rst_i,
--        packet_length_in            => packet_length_int,
--        reset_DAQ_FIFO              => daqFIFO_reset,
--        confReply_packet            => start_conf_proc_int,

--        vmmID                       => pf_vmmIdRo,
        
--        trigger_out                 => trigger_i,
--        count_o                     => FIFO2UDP_state,
--        faifouki                    => faifouki
--    );       

--packet_formation_instance: packet_formation
--    generic map(is_mmfe8        => is_mmfe8,
--                vmmReadoutMode  => vmmReadoutMode,
--                artEnabled      => artEnabled)
--    port map(
--        clk             => userclk2,
        
--        newCycle        => pf_newCycle,
        
--        trigVmmRo       => pf_trigVmmRo,
--        vmmId           => pf_vmmIdRo,
--        vmmWord         => vmmWord_i,
--        vmmWordReady    => vmmWordReady_i,
--        vmmEventDone    => vmmEventDone_i,
        
--        UDPDone         => UDPDone,
--        pfBusy          => pfBusy_i,
--        glBCID          => glBCID_i,
        
--        packLen         => pf_packLen,
--        dataout         => daq_data_out_i,
--        wrenable        => daq_wr_en_i,
--        end_packet      => end_packet_daq_int,
        
--        rd_ena_buff     => rd_ena_buff,
--        rst_l0          => rst_l0_pf,
        
--        tr_hold         => tr_hold,
--        reset           => pf_rst_final,
--        rst_vmm         => rst_vmm,
--        linkHealth_bmsk => linkHealth_bmsk,
--        rst_FIFO        => pf_rst_FIFO,
        
--        elink_inhibit   => pfInhibit_i,
--        pf_rdy          => pfReady_i,
--        ro_rdy          => ro_rdy,
--        trigger_cnt     => trigger_cnt,

--        latency         => latency_conf,
--        dbg_st_o        => pf_dbg_st,
--        trraw_synced125 => trraw_synced125_i,
        
--        vmmArtData125   => vmmArtData,
--        vmmArtReady     => vmmArtReady
        
--    );   
        
--data_selection:  select_data
--    port map(
--        configuring                 => start_conf_proc_int,
--        xadc                        => xadc_busy,
--        data_acq                    => daq_enable_i,
--        we_data                     => daq_wr_en_i,
--        we_conf                     => we_conf_int,
--        we_xadc                     => xadc_fifo_enable,
--        daq_data_in                 => daq_data_out_i,
--        conf_data_in                => user_data_out_i,
--        xadc_data_in                => xadc_fifo_bus,
--        data_packet_length          => pf_packLen,
--        xadc_packet_length          => xadc_packet_len,
--        conf_packet_length          => packet_len_conf,
--        end_packet_conf             => end_packet_conf_int,
--        end_packet_daq              => end_packet_daq_int,
--        end_packet_xadc             => xadc_end_of_data,
--        fifo_rst_daq                => pf_rst_FIFO,
--        fifo_rst_xadc               => '0',
--        rstFIFO_top                 => rstFIFO_top,

--        data_out                    => daqFIFO_din_i,
--        packet_length               => packet_length_int,
--        we                          => daqFIFO_wr_en_i,
--        end_packet                  => end_packet_i,
--        fifo_rst                    => daqFIFO_reset
--    );

--xadc_instance: xadcModule
--    port map(
--        clk125                      => userclk2,
--        rst                         => glbl_rst_i,
        
--        VP_0                        => VP_0,
--        VN_0                        => VN_0,
--        Vaux0_v_n                   => Vaux0_v_n,
--        Vaux0_v_p                   => Vaux0_v_p,
--        Vaux1_v_n                   => Vaux1_v_n,
--        Vaux1_v_p                   => Vaux1_v_p,
--        Vaux2_v_n                   => Vaux2_v_n,
--        Vaux2_v_p                   => Vaux2_v_p,
--        Vaux3_v_n                   => Vaux3_v_n,
--        Vaux3_v_p                   => Vaux3_v_p,
--        Vaux8_v_n                   => Vaux8_v_n,
--        Vaux8_v_p                   => Vaux8_v_p,
--        Vaux9_v_n                   => Vaux9_v_n,
--        Vaux9_v_p                   => Vaux9_v_p,
--        Vaux10_v_n                  => Vaux10_v_n,
--        Vaux10_v_p                  => Vaux10_v_p,
--        Vaux11_v_n                  => Vaux11_v_n,
--        Vaux11_v_p                  => Vaux11_v_p,
--        data_in_rdy                 => xadc_start,
--        vmm_id                      => vmm_id_xadc,
--        sample_size                 => xadc_sample_size,
--        delay_in                    => xadc_delay,
--        UDPDone                     => UDPDone,
    
--        MuxAddr0                    => MuxAddr0_i,
--        MuxAddr1                    => MuxAddr1_i,
--        MuxAddr2                    => MuxAddr2_i,
--        MuxAddr3_p                  => MuxAddr3_p_i,
--        MuxAddr3_n                  => MuxAddr3_n_i,
--        end_of_data                 => xadc_end_of_data,
--        fifo_bus                    => xadc_fifo_bus,
--        data_fifo_enable            => xadc_fifo_enable,
--        packet_len                  => xadc_packet_len,
--        xadc_busy                   => xadc_busy          -- synced to 125 Mhz
--    );

--axi4_spi_instance: AXI4_SPI  
--    port map(
--        clk_200                => clk_200,
--        clk_125                => userclk2,
--        clk_50                 => clk_50,
        
--        myIP                   => myIP,             -- synced to 125 Mhz
--        myMAC                  => myMAC,            -- synced to 125 Mhz
--        destIP                 => destIP,           -- synced to 125 Mhz

--        default_IP             => default_IP,
--        default_MAC            => default_MAC,
--        default_destIP         => default_destIP,
        
--        myIP_set               => myIP_set,         -- synced internally to 50 Mhz
--        myMAC_set              => myMAC_set,        -- synced internally to 50 Mhz
--        destIP_set             => destIP_set,       -- synced internally to 50 Mhz

--        newip_start            => newIP_start,      -- synced internally to 50 Mhz
--        flash_busy             => flash_busy,       -- synced to 125 Mhz

--        io0_i                  => io0_i,
--        io0_o                  => io0_o,
--        io0_t                  => io0_t,
--        io1_i                  => io1_i,
--        io1_o                  => io1_o,
--        io1_t                  => io1_t,
--        ss_i                   => ss_i,
--        ss_o                   => ss_o,
--        ss_t                   => ss_t
--        --SPI_CLK                => 
--    );

--ckbc_cktp_generator: clk_gen_wrapper
--    port map(
--        ------------------------------------
--        ------- General Interface ----------
--        clk_500             => clk_500,
--        clk_160             => clk_160,
--        clk_125             => userclk2,
--        rst                 => glbl_rst_i,
--        mmcm_locked         => master_locked,
--        CKTP_raw            => CKTP_raw,
--        ------------------------------------
--        ----- Configuration Interface ------
--        cktp_enable         => cktp_enable,
--        cktp_primary        => vmm_cktp_primary, -- from flow_fsm
--        readout_mode        => ckbcMode,
--        enable_ro_ckbc      => request2ckbc,
--        cktp_pulse_width    => cktp_pulse_width(4 downto 0),
--        cktp_max_num        => cktp_max_num,
--        cktp_period         => cktp_period,
--        cktp_skew           => cktp_skew(4 downto 0),
--        ckbc_freq           => ckbc_freq(5 downto 0),
--        ckbc_max_num        => ckbc_max_num,
--        ------------------------------------
--        ---------- VMM Interface -----------
--        CKTP                => CKTP_glbl,
--        CKBC                => CKBC_glbl
--    );

--QSPI_IO0_0: IOBUF    
--   port map (
--      O  => io0_i,
--      IO => IO0_IO,
--      I  => io0_o,
--      T  => io0_t
--   );
           
--QSPI_IO1_0: IOBUF    
--   port map (
--      O  => io1_i,
--      IO => IO1_IO,
--      I  => io1_o,
--      T  => io1_t
--   );
    
--QSPI_SS_0: IOBUF     
--   port map (
--      O  => ss_i(0),
--      IO => SS_IO,
--      I  => ss_o(0),
--      T  => ss_t
--   );
   
--art_instance: artReadout
--    generic map(is_mmfe8 => is_mmfe8, 
--                artEnabled => artEnabled)
--    port map (
--        clk             => userclk2,
--        clk_art         => clk_160,
--        trigger         => trraw_synced125_i,
--        artData         => art_in_vec,
--        vmmArtData125   => vmmArtData,
--        vmmArtReady     => vmmArtReady
--   );

--vmm_oddr_inst: vmm_oddr_wrapper
--    port map(
--        -------------------------------------------------------
--        ckdt_bufg       => CKDT_glbl,
--        ckdt_enable_vec => vmm_ckdt_enable,
--        ckdt_toBuf_vec  => ckdt_out_vec,
--        -------------------------------------------------------
--        ckbc_bufg       => CKBC_glbl,
--        ckbc_enable     => ckbc_enable,
--        ckbc_toBuf_vec  => vmm_ckbc_vec,
--        -------------------------------------------------------
--        cktp_bufg       => CKTP_glbl,
--        cktp_toBuf_vec  => vmm_cktp_vec,
--        -------------------------------------------------------
--        ckart_bufg      => clk_160,
--        ckart_toBuf_vec => ckart_vec
--        -------------------------------------------------------
--    );

-- DAQ path E-link
DAQ_ELINK: elink_wrapper
    generic map(DataRate      => 80,
                elinkEncoding => "01") --8b/10b encoding
    port map(
        ---------------------------------
        ----- General/VIO Interface -----
        user_clock      => userclk2,
        pattern_ena     => '0',
        daq_ena         => '0',
        loopback_ena    => '0',
        glbl_rst        => rst_elink_glbl,
        rst_tx          => '0',
        rst_rx          => rst_elink_rx,    -- from VIO
        swap_tx         =>  '0',
        swap_rx         => swap_rx,         -- from VIO
        ttc_detected    => open,
        error_led       => enable_led,
        ---------------------------------
        -------- E-link clocking --------
        clk_40          => clk_40,
        clk_80          => clk_80,
        clk_160         => clk_160,
        clk_320         => clk_320,
        elink_locked    => master_locked,
        ---------------------------------
        ---- E-link Serial Interface ----
        elink_tx        => elink_DAQ_tx,
        elink_rx        => elink_DAQ_rx,
        ---------------------------------
        -------- UDP Interface ----------
        udp_tx_dout_rdy => udp_tx_data_out_ready_int,
        udp_tx_start    => udp_tx_start_int,
        udp_txi         => udp_txi_int,
        ---------------------------------
        ------ Readout Interface --------
        ro_rdy          => ro_rdy,
        bitmask_null    => bitmask_null,
        health_bitmask  => linkHealth_bmsk_i,
        ---------------------------------
        --------- PF Interface ----------
        din_daq         => daq_data_out_i,
        wr_en_daq       => daq_wr_en_i,
        trigger_cnt     => trigger_cnt,
        inhibit_pf      => pfInhibit_i,
        pf_busy         => pfBusy_i,
        pf_rdy          => pfReady_i,
        vmm_id          => pf_vmmIdRo
    ); 
    
vio_elink_instance: vio_elink
    port map(
        clk             => userclk2,
        probe_in0(0)    => master_locked,
        probe_out0(0)   => test_led,
        probe_out1(0)   => rst_elink_glbl,
        probe_out2(0)   => rst_elink_mmcm,
        probe_out3(0)   => swap_rx
   );

--    clk => clk,
--    probe_in0 => probe_in0,
--    probe_in1 => probe_in1,
--    probe_out0 => probe_out0,
--    probe_out1 => probe_out1,
--    probe_out2 => probe_out2,
--    probe_out3 => probe_out3,
--    probe_out4 => probe_out4,
--    probe_out5 => probe_out5,
--    probe_out6 => probe_out6,
--    probe_out7 => probe_out7,
--    probe_out8 => probe_out8

---------------------------- E-LINK BUFFERS ----------------------------------------------------------------------
elink_tx_daq_buf: OBUFDS generic map  (IOSTANDARD => "DEFAULT" , SLEW => "FAST")
                         port map     (O =>  ELINK_DAQ_TX_P, OB => ELINK_DAQ_TX_N, I =>  elink_DAQ_tx);
elink_rx_daq_buf: IBUFDS generic map  (IOSTANDARD => "DEFAULT", IBUF_LOW_PWR => FALSE, DIFF_TERM => TRUE)
                         port map     (O =>  elink_DAQ_rx, I =>  ELINK_DAQ_RX_P, IB => ELINK_DAQ_RX_N);    
elink_clk_tx_buf: OBUFDS generic map  (IOSTANDARD => "DEFAULT" , SLEW => "FAST")
                         port map     (O =>  ELINK_DAQ_CLK_P, OB =>  ELINK_DAQ_CLK_N, I => clk_40);
------------------------------------------------------------------------------------------------------------------

led_obuf:        OBUF   port map (O => LED_LOCKED, I => master_locked);

error_led_0_obuf:   OBUF   port map  (O => LED_ERROR_0, I => led_out(0));
error_led_1_obuf:   OBUF   port map  (O => LED_ERROR_1, I => led_out(1));
error_led_2_obuf:   OBUF   port map  (O => LED_ERROR_2, I => led_out(2));
error_led_3_obuf:   OBUF   port map  (O => LED_ERROR_3, I => led_out(3));
----------------------------------------------------CS------------------------------------------------------------
cs_obuf_1:  OBUF  port map  (O => CS_1, I => vmm_cs_vec_obuf(1));
cs_obuf_2:  OBUF  port map  (O => CS_2, I => vmm_cs_vec_obuf(2));
cs_obuf_3:  OBUF  port map  (O => CS_3, I => vmm_cs_vec_obuf(3));
cs_obuf_4:  OBUF  port map  (O => CS_4, I => vmm_cs_vec_obuf(4));
cs_obuf_5:  OBUF  port map  (O => CS_5, I => vmm_cs_vec_obuf(5));
cs_obuf_6:  OBUF  port map  (O => CS_6, I => vmm_cs_vec_obuf(6));
cs_obuf_7:  OBUF  port map  (O => CS_7, I => vmm_cs_vec_obuf(7));
cs_obuf_8:  OBUF  port map  (O => CS_8, I => vmm_cs_vec_obuf(8));

----------------------------------------------------SCK------------------------------------------------------------
sck_obuf_1:  OBUF  port map  (O => SCK_1, I => vmm_sck_vec_obuf(1));
sck_obuf_2:  OBUF  port map  (O => SCK_2, I => vmm_sck_vec_obuf(2));
sck_obuf_3:  OBUF  port map  (O => SCK_3, I => vmm_sck_vec_obuf(3));
sck_obuf_4:  OBUF  port map  (O => SCK_4, I => vmm_sck_vec_obuf(4));
sck_obuf_5:  OBUF  port map  (O => SCK_5, I => vmm_sck_vec_obuf(5));
sck_obuf_6:  OBUF  port map  (O => SCK_6, I => vmm_sck_vec_obuf(6));
sck_obuf_7:  OBUF  port map  (O => SCK_7, I => vmm_sck_vec_obuf(7));
sck_obuf_8:  OBUF  port map  (O => SCK_8, I => vmm_sck_vec_obuf(8));

----------------------------------------------------SDI------------------------------------------------------------
sdi_obuf_1:  OBUF  port map  (O => SDI_1, I => vmm_sdi_vec_obuf(1));
sdi_obuf_2:  OBUF  port map  (O => SDI_2, I => vmm_sdi_vec_obuf(2));
sdi_obuf_3:  OBUF  port map  (O => SDI_3, I => vmm_sdi_vec_obuf(3));
sdi_obuf_4:  OBUF  port map  (O => SDI_4, I => vmm_sdi_vec_obuf(4));
sdi_obuf_5:  OBUF  port map  (O => SDI_5, I => vmm_sdi_vec_obuf(5));
sdi_obuf_6:  OBUF  port map  (O => SDI_6, I => vmm_sdi_vec_obuf(6));
sdi_obuf_7:  OBUF  port map  (O => SDI_7, I => vmm_sdi_vec_obuf(7));
sdi_obuf_8:  OBUF  port map  (O => SDI_8, I => vmm_sdi_vec_obuf(8));

---------------------------------------------------SETT/SETB/CK6B--------------------------------------------------
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

----------------------------------------------------SDO------------------------------------------------------------
sdo_ibuf_1: IBUF port map ( O =>  vmm_sdo_vec_i(1), I =>  SDO_1);
sdo_ibuf_2: IBUF port map ( O =>  vmm_sdo_vec_i(2), I =>  SDO_2);
sdo_ibuf_3: IBUF port map ( O =>  vmm_sdo_vec_i(3), I =>  SDO_3);
sdo_ibuf_4: IBUF port map ( O =>  vmm_sdo_vec_i(4), I =>  SDO_4);
sdo_ibuf_5: IBUF port map ( O =>  vmm_sdo_vec_i(5), I =>  SDO_5);
sdo_ibuf_6: IBUF port map ( O =>  vmm_sdo_vec_i(6), I =>  SDO_6);
sdo_ibuf_7: IBUF port map ( O =>  vmm_sdo_vec_i(7), I =>  SDO_7);
sdo_ibuf_8: IBUF port map ( O =>  vmm_sdo_vec_i(8), I =>  SDO_8);

----------------------------------------------------ENA-----------------------------------------------------------
ena_diff_1: OBUFDS port map ( O =>  ENA_1_P, OB => ENA_1_N, I => vmm_ena_vec_obuf(1));    
ena_diff_2: OBUFDS port map ( O =>  ENA_2_P, OB => ENA_2_N, I => vmm_ena_vec_obuf(2));
ena_diff_3: OBUFDS port map ( O =>  ENA_3_P, OB => ENA_3_N, I => vmm_ena_vec_obuf(3));
ena_diff_4: OBUFDS port map ( O =>  ENA_4_P, OB => ENA_4_N, I => vmm_ena_vec_obuf(4));
ena_diff_5: OBUFDS port map ( O =>  ENA_5_P, OB => ENA_5_N, I => vmm_ena_vec_obuf(5));
ena_diff_6: OBUFDS port map ( O =>  ENA_6_P, OB => ENA_6_N, I => vmm_ena_vec_obuf(6));
ena_diff_7: OBUFDS port map ( O =>  ENA_7_P, OB => ENA_7_N, I => vmm_ena_vec_obuf(7));
ena_diff_8: OBUFDS port map ( O =>  ENA_8_P, OB => ENA_8_N, I => vmm_ena_vec_obuf(8));

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

----------------------------------------------------CKTK------------------------------------------------------------
cktk_diff_1: OBUFDS port map ( O =>  CKTK_1_P, OB => CKTK_1_N, I => cktk_out_vec(1));
cktk_diff_2: OBUFDS port map ( O =>  CKTK_2_P, OB => CKTK_2_N, I => cktk_out_vec(2));
cktk_diff_3: OBUFDS port map ( O =>  CKTK_3_P, OB => CKTK_3_N, I => cktk_out_vec(3));
cktk_diff_4: OBUFDS port map ( O =>  CKTK_4_P, OB => CKTK_4_N, I => cktk_out_vec(4));
cktk_diff_5: OBUFDS port map ( O =>  CKTK_5_P, OB => CKTK_5_N, I => cktk_out_vec(5));
cktk_diff_6: OBUFDS port map ( O =>  CKTK_6_P, OB => CKTK_6_N, I => cktk_out_vec(6));
cktk_diff_7: OBUFDS port map ( O =>  CKTK_7_P, OB => CKTK_7_N, I => cktk_out_vec(7));
cktk_diff_8: OBUFDS port map ( O =>  CKTK_8_P, OB => CKTK_8_N, I => cktk_out_vec(8));
    
----------------------------------------------------CKDT-------------------------------------------------------------
ckdt_diff_1: OBUFDS port map ( O => ckdt_1_P, OB => ckdt_1_N, I => ckdt_out_vec(1));
ckdt_diff_2: OBUFDS port map ( O => ckdt_2_P, OB => ckdt_2_N, I => ckdt_out_vec(2));
ckdt_diff_3: OBUFDS port map ( O => ckdt_3_P, OB => ckdt_3_N, I => ckdt_out_vec(3));
ckdt_diff_4: OBUFDS port map ( O => ckdt_4_P, OB => ckdt_4_N, I => ckdt_out_vec(4));
ckdt_diff_5: OBUFDS port map ( O => ckdt_5_P, OB => ckdt_5_N, I => ckdt_out_vec(5));
ckdt_diff_6: OBUFDS port map ( O => ckdt_6_P, OB => ckdt_6_N, I => ckdt_out_vec(6));
ckdt_diff_7: OBUFDS port map ( O => ckdt_7_P, OB => ckdt_7_N, I => ckdt_out_vec(7));
ckdt_diff_8: OBUFDS port map ( O => ckdt_8_P, OB => ckdt_8_N, I => ckdt_out_vec(8));                                               

----------------------------------------------------DATA 0-------------------------------------------------------------
data0_diff_1: IBUFDS port map ( O => data0_in_vec(1), I => DATA0_1_P, IB => DATA0_1_N);
data0_diff_2: IBUFDS port map ( O => data0_in_vec(2), I => DATA0_2_P, IB => DATA0_2_N);
data0_diff_3: IBUFDS port map ( O => data0_in_vec(3), I => DATA0_3_P, IB => DATA0_3_N);
data0_diff_4: IBUFDS port map ( O => data0_in_vec(4), I => DATA0_4_P, IB => DATA0_4_N);
data0_diff_5: IBUFDS port map ( O => data0_in_vec(5), I => DATA0_5_P, IB => DATA0_5_N);
data0_diff_6: IBUFDS port map ( O => data0_in_vec(6), I => DATA0_6_P, IB => DATA0_6_N);
data0_diff_7: IBUFDS port map ( O => data0_in_vec(7), I => DATA0_7_P, IB => DATA0_7_N);
data0_diff_8: IBUFDS port map ( O => data0_in_vec(8), I => DATA0_8_P, IB => DATA0_8_N);
    
----------------------------------------------------DATA 1-------------------------------------------------------------
data1_diff_1: IBUFDS port map ( O => data1_in_vec(1), I => DATA1_1_P, IB => DATA1_1_N);
data1_diff_2: IBUFDS port map ( O => data1_in_vec(2), I => DATA1_2_P, IB => DATA1_2_N);
data1_diff_3: IBUFDS port map ( O => data1_in_vec(3), I => DATA1_3_P, IB => DATA1_3_N);
data1_diff_4: IBUFDS port map ( O => data1_in_vec(4), I => DATA1_4_P, IB => DATA1_4_N);
data1_diff_5: IBUFDS port map ( O => data1_in_vec(5), I => DATA1_5_P, IB => DATA1_5_N);
data1_diff_6: IBUFDS port map ( O => data1_in_vec(6), I => DATA1_6_P, IB => DATA1_6_N);
data1_diff_7: IBUFDS port map ( O => data1_in_vec(7), I => DATA1_7_P, IB => DATA1_7_N);
data1_diff_8: IBUFDS port map ( O => data1_in_vec(8), I => DATA1_8_P, IB => DATA1_8_N);

----------------------------------------------------TKI/TKO-------------------------------------------------------------      
TKI_diff_1: OBUFDS port map ( O =>  TKI_P, OB => TKI_N, I => vmm_tki);
TKO_diff_1: IBUFDS port map ( O =>  tko_i, I => TKO_P, IB => TKO_N);

---------------------------------------------------CKART----------------------------------------------------------------
ckart_diff_1: OBUFDS port map ( O => CKART_1_P, OB => CKART_1_N, I => ckart_vec(1));
ckart_diff_2: OBUFDS port map ( O => CKART_2_P, OB => CKART_2_N, I => ckart_vec(2));
ckart_diff_3: OBUFDS port map ( O => CKART_3_P, OB => CKART_3_N, I => ckart_vec(3));
ckart_diff_4: OBUFDS port map ( O => CKART_4_P, OB => CKART_4_N, I => ckart_vec(4));
ckart_diff_5: OBUFDS port map ( O => CKART_5_P, OB => CKART_5_N, I => ckart_vec(5));
ckart_diff_6: OBUFDS port map ( O => CKART_6_P, OB => CKART_6_N, I => ckart_vec(6));
ckart_diff_7: OBUFDS port map ( O => CKART_7_P, OB => CKART_7_N, I => ckart_vec(7));
ckart_diff_8: OBUFDS port map ( O => CKART_8_P, OB => CKART_8_N, I => ckart_vec(8));

----------------------------------------------------ART----------------------------------------------------------------
art_diff_1: IBUFDS port map ( O => art_in_vec(1), I => ART_1_P, IB => ART_1_N);
--art_diff_2: IBUFDS port map ( O => art_in_vec(2), I => ART_2_P, IB => ART_2_N);
--art_diff_3: IBUFDS port map ( O => art_in_vec(3), I => ART_3_P, IB => ART_3_N);
--art_diff_4: IBUFDS port map ( O => art_in_vec(4), I => ART_4_P, IB => ART_4_N);
--art_diff_5: IBUFDS port map ( O => art_in_vec(5), I => ART_5_P, IB => ART_5_N);
--art_diff_6: IBUFDS port map ( O => art_in_vec(6), I => ART_6_P, IB => ART_6_N);
--art_diff_7: IBUFDS port map ( O => art_in_vec(7), I => ART_7_P, IB => ART_7_N);
--art_diff_8: IBUFDS port map ( O => art_in_vec(8), I => ART_8_P, IB => ART_8_N);

ckart_addc_buf: OBUFDS port map ( O => CKART_ADDC_P, OB => CKART_ADDC_N, I => ckart_vec(9));

----------------------------------------------------XADC----------------------------------------------------------------
xadc_mux0_obuf:   OBUF   port map  (O => MuxAddr0, I => MuxAddr0_i);
xadc_mux1_obuf:   OBUF   port map  (O => MuxAddr1, I => MuxAddr1_i);
xadc_mux2_obuf:   OBUF   port map  (O => MuxAddr2, I => MuxAddr2_i);
xadc_mux3_obufds: OBUFDS port map  (O => MuxAddr3_p, OB => MuxAddr3_n, I => MuxAddr3_p_i);

art_out_diff_1:   OBUFDS port map (O =>  ART_OUT_P, OB => ART_OUT_N, I => art2);

rstn_obuf:  OBUF  port map  (O => phy_rstn_out, I => phy_rstn);


 
-------------------------------------------------------------------
--                        Processes                              --
-------------------------------------------------------------------
    -- 1. synced_to_flowFSM
    -- 2. sel_cs
    -- 3. flow_fsm
-------------------------------------------------------------------
sync_fifo_init: process(userclk2)
begin
    if(rising_edge(userclk2))then
        glbl_fifo_init_s0 <= glbl_fifo_init;
        glbl_fifo_init_s1 <= glbl_fifo_init_s0;
    end if;
end process;

art_process: process(userclk2, art2)
begin
    if rising_edge(userclk2) then  
        if art_cnt2 < 125 and art2 = '1' then 
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
    C   => art_in_vec(1), -- Clock input
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

flow_fsm: process(userclk2)
    begin
    if rising_edge(userclk2) then
        if glbl_rst_i = '1' then
            state   <= IDLE;
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
                    rst_l0_buff_flow        <= '1';
                    pf_rst_flow             <= '0';
                    rstFIFO_flow            <= '0';
                    tren                    <= '0';
                    vmm_ena_all             <= '0';
                    vmm_tki                 <= '0';
                    ckbc_enable             <= '0';
                    vmm_cktp_primary        <= '0';
                    daq_vmm_ena_wen_enable  <= x"00";
                    daq_cktk_out_enable     <= x"00";
                    sel_cs                  <= "11";    -- drive CS high

                    if(vmm_conf = '1')then
                        state <= WAIT_FOR_CONF;

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

                    elsif(daq_on = '1' and daq_on_inhib = '0')then
                        state   <= DAQ_INIT;
                        
                    else
                        state       <= IDLE;
                        wait_cnt    <= (others => '0');
                    end if;
                    
               when WAIT_FOR_CONF =>
                   vmm_ena_all <= '0'; 
                   if(vmm_id_rdy = '1')then
                       if(wait_cnt = "00000111")then -- wait for safe assertion of multi-bit signal
                           wait_cnt    <= (others => '0');
                           state       <= CONFIGURE;
                       else
                           wait_cnt    <= wait_cnt + 1;
                           state       <= WAIT_FOR_CONF;
                       end if;
                   else
                       wait_cnt    <= (others => '0'); 
                       state       <= WAIT_FOR_CONF;
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
                    if wait_cnt = "00101000" then
                        cnt_vmm     <= cnt_vmm - 1;
                        if cnt_vmm = 1 then --VMM conf done
                            state           <= SEND_CONF_REPLY;
                        else
                            state       <= CONFIGURE_DELAY;
                        end if;
                        wait_cnt   <= (others => '0');
                    else
                        wait_cnt <= wait_cnt + 1;
                    end if;
                    
                    conf_wen_i      <= '0';

                when CONFIGURE_DELAY => -- Waits 100 ns to move to next configuration
                    is_state        <= "1011";
                    if (wait_cnt >= "00010011") then
                        wait_cnt        <= (others => '0');
                        vmm_ena_all     <= '0';
                        sel_cs          <= "00"; -- drive CS to gnd
                        state           <= CONFIGURE;
                    else
                       wait_cnt <= wait_cnt + 1;
                    end if;

                when    SEND_CONF_REPLY    =>
                    reply_enable    <= '1';
                    sel_cs          <= "00"; -- drive CS to gnd
                    vmm_ena_all     <= '0'; 
                    if(reply_done = '1' and UDPDone = '1')then
                        state        <= IDLE;
                    else
                        state        <= SEND_CONF_REPLY;
                    end if;

                when DAQ_INIT =>
                    is_state                <= "0011";
                    --for I in 1 to 100 loop
                        vmm_cktp_primary    <= '1';
                    --end loop;
                    sel_cs                  <= "11"; -- drive CS high
                    vmm_ena_all             <= '1';
                    rst_l0_buff_flow        <= '0';
                    tren                    <= '0';
                    daq_vmm_ena_wen_enable  <= x"ff";
                    daq_cktk_out_enable     <= x"ff";
                    daq_enable_i            <= '1';
                    rstFIFO_flow            <= '1';
                    pf_rst_flow             <= '1';
                    
                    if(daq_on = '0')then    -- Reset came
                        daq_vmm_ena_wen_enable  <= x"00";
                        daq_cktk_out_enable     <= x"00";
                        daq_enable_i            <= '0';
                        pf_rst_flow             <= '0';
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
                    if(vmmReadoutMode = '0')then
                        vmm_tki <= '1';
                    else
                        vmm_tki <= '0';
                    end if;
                    vmm_cktp_primary    <= '0';
                    rstFIFO_flow        <= '0';
                    pf_rst_flow         <= '0';
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

    mmcm_reset              <= glbl_rst_i; -- reset;
    glbl_rstn               <= not glbl_rst_i;
    phy_int                 <= '1';
    local_gtx_reset         <= glbl_rst_i or rx_reset or tx_reset;
    
    cktp_enable             <= '1' when ((state = DAQ and trig_mode_int = '0') or (state = XADC_wait and trig_mode_int = '0')) else '0';
    inhibit_conf            <= '0' when (state = IDLE) else '1';
    vmm_bitmask_1VMM        <= "11111111";
    vmm_bitmask             <= vmm_bitmask_8VMM when (is_mmfe8 = '1') else vmm_bitmask_1VMM;
    
    pf_newCycle             <= tr_out_i;
    CH_TRIGGER_i            <= not CH_TRIGGER;
    TRIGGER_OUT_P           <= art2;
    TRIGGER_OUT_N           <= not art2;
    MO                      <= MO_i;
    rst_l0_buff             <= rst_l0_buff_flow or rst_l0_pf or glbl_rst_i;
    pf_rst_final            <= pf_rst_flow or glbl_rst_i;
    glbl_fifo_init          <= not phy_rstn;
    rstFIFO_top             <= rstFIFO_flow or glbl_fifo_init;
    enable_led_final        <= enable_led or test_led;
    
    -- configuration assertion
    vmm_cs_vec_obuf(1)  <= vmm_cs_all;
    vmm_cs_vec_obuf(2)  <= vmm_cs_all;
    vmm_cs_vec_obuf(3)  <= vmm_cs_all;
    vmm_cs_vec_obuf(4)  <= vmm_cs_all;
    vmm_cs_vec_obuf(5)  <= vmm_cs_all;
    vmm_cs_vec_obuf(6)  <= vmm_cs_all;
    vmm_cs_vec_obuf(7)  <= vmm_cs_all;
    vmm_cs_vec_obuf(8)  <= vmm_cs_all;
    
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
    
    vmm_ena_vec_obuf(1) <= vmm_ena_all;
    vmm_ena_vec_obuf(2) <= vmm_ena_all;
    vmm_ena_vec_obuf(3) <= vmm_ena_all;
    vmm_ena_vec_obuf(4) <= vmm_ena_all;
    vmm_ena_vec_obuf(5) <= vmm_ena_all;
    vmm_ena_vec_obuf(6) <= vmm_ena_all;
    vmm_ena_vec_obuf(7) <= vmm_ena_all;
    vmm_ena_vec_obuf(8) <= vmm_ena_all;
    
    linkHealth_bmsk_i(7) <= linkHealth_bmsk(8);
    linkHealth_bmsk_i(6) <= linkHealth_bmsk(7);
    linkHealth_bmsk_i(5) <= linkHealth_bmsk(6);
    linkHealth_bmsk_i(4) <= linkHealth_bmsk(5);
    linkHealth_bmsk_i(3) <= linkHealth_bmsk(4);
    linkHealth_bmsk_i(2) <= linkHealth_bmsk(3);
    linkHealth_bmsk_i(1) <= linkHealth_bmsk(2);
    linkHealth_bmsk_i(0) <= linkHealth_bmsk(1);

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

--ila_top: ila_overview
--    port map (
--        clk     => userclk2,
--        probe0  => overviewProbe
--    );
    
--VIO_DEFAULT_IP: vio_ip
--      PORT MAP (
--        clk         => clk_50,
--        probe_out0  => default_IP,
--        probe_out1  => default_MAC
--      );
    
--    overviewProbe(3 downto 0)          <= is_state;
--    overviewProbe(8 downto 4)          <= pf_dbg_st;
--    overviewProbe(9)                   <= vmmWordReady_i;
--    overviewProbe(10)                  <= vmmEventDone_i;
--    overviewProbe(11)                  <= daq_enable_i;
--    overviewProbe(12)                  <= pf_trigVmmRo;
--    overviewProbe(14 downto 13)        <= (others => '0');
--    overviewProbe(15)                  <= rd_ena_buff;
--    overviewProbe(19 downto 16)        <= dt_state;
--    overviewProbe(23 downto 20)        <= FIFO2UDP_state;
--    overviewProbe(24)                  <= CKTP_glbl;
--    overviewProbe(25)                  <= UDPDone;
--    overviewProbe(26)                  <= CKBC_glbl;
--    overviewProbe(27)                  <= tr_out_i;
--    overviewProbe(29 downto 28)        <= (others => '0');
--    overviewProbe(30)                  <= level_0;
--    overviewProbe(31)                  <= rst_l0_pf;
--    overviewProbe(47 downto 32)        <= vmmWord_i;
--    overviewProbe(51 downto 48)        <= dt_cntr_st;
--    overviewProbe(59 downto 52)        <= linkHealth_bmsk;
--    overviewProbe(63 downto 60)        <= (others => '0');

    vmmSignalsProbe(7 downto 0)        <= (others => '0');
    vmmSignalsProbe(15 downto 8)       <= cktk_out_vec;
    vmmSignalsProbe(23 downto 16)      <= ckdt_out_vec;
    vmmSignalsProbe(31 downto 24)      <= data0_in_vec;
    vmmSignalsProbe(32)                <= '0';
    vmmSignalsProbe(33)                <= ckdt_out_vec(1);
    vmmSignalsProbe(34)                <= data0_in_vec(1);
    vmmSignalsProbe(35)                <= data1_in_vec(1);
    vmmSignalsProbe(36)                <= vmm_cs_all;
    vmmSignalsProbe(37)                <= '0';
    vmmSignalsProbe(38)                <= vmm_ena_all;
    vmmSignalsProbe(39)                <= '0';
    vmmSignalsProbe(40)                <= tko_i;
    vmmSignalsProbe(41)                <= vmm_ena_all;
    vmmSignalsProbe(42)                <= art2;
    vmmSignalsProbe(43)                <= '0';
    vmmSignalsProbe(44)                <= art_in_vec(1);
    vmmSignalsProbe(63 downto 45)      <= (others => '0'); 

    triggerETRProbe(0)                <= '0';
    triggerETRProbe(1)                <= tren;
    triggerETRProbe(2)                <= tr_hold;
    triggerETRProbe(3)                <= ext_trigger_in;
    triggerETRProbe(4)                <= trig_mode_int;
    triggerETRProbe(7 downto 5)       <= state_rst_etr_i;
    triggerETRProbe(15 downto 8)      <= (others => '0');
    triggerETRProbe(23 downto 16)     <= (others => '0');
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
