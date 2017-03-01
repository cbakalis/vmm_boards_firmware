#======================= TIMING ASSERTIONS SECTION ====================
#============================= Primary Clocks =========================
create_clock -period 5.000 -name X_2V5_DIFF_CLK_P -waveform {0.000 2.500} [get_ports X_2V5_DIFF_CLK_P]
create_clock -period 8.000 -name gtrefclk_p       -waveform {0.000 4.000} [get_ports gtrefclk_p]
#============================= Virtual Clocks =========================
#============================= Generated Clocks =======================
## SPI FLASH BEGIN ##
# Following command creates a divide by 2 clock
# It also takes into account the delay added by STARTUP block to route the CCLK
# create_generated_clock -name clk_sck -source [get_pins -hierarchical *axi_quad_spi_0/ext_spi_clk] [get_pins -hierarchical *USRCCLKO] -edges {3 5 7} -edge_shift [list $cclk_delay $cclk_delay $cclk_delay]
create_generated_clock -name clk_sck -source [get_pins -hierarchical *axi_SPI/ext_spi_clk] -edges {3 5 7} -edge_shift {6.700 6.700 6.700} [get_pins -hierarchical *USRCCLKO]
## SPI FLASH END ##
#============================= Clock Groups ===========================
#============================= I/O Delays =============================
## SPI FLASH BEGIN ##
# Data is captured into FPGA on the second rising edge of ext_spi_clk after the SCK falling edge
# Data is driven by the FPGA on every alternate rising_edge of ext_spi_clk
set_input_delay -clock clk_sck -clock_fall -max 7.450 [get_ports IO*_IO]
set_input_delay -clock clk_sck -clock_fall -min 1.450 [get_ports IO*_IO]

# Data is captured into SPI on the following rising edge of SCK
# Data is driven by the IP on alternate rising_edge of the ext_spi_clk
set_output_delay -clock clk_sck -max 2.050 [get_ports IO*_IO]
set_output_delay -clock clk_sck -min -2.950 [get_ports IO*_IO]
## SPI FLASH END ##

set_input_delay 1.0 -clock [get_clocks -of_objects [get_pins clk_user_inst/inst/mmcm_adv_inst/CLKOUT0]] [get_ports CH_TRIGGER]
set_false_path -from [get_ports CH_TRIGGER]
#============================= Primary Clocks =========================
#======================================================================


#======================= TIMING EXCEPTIONS SECTION ====================
#=============================== False Paths ==========================
#============================== Min/Max Delay =========================
## SPI FLASH BEGIN ##
# this is to ensure min routing delay from SCK generation to STARTUP input
# User should change this value based on the results
# having more delay on this net reduces the Fmax
set_max_delay -datapath_only -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO] 1.500
set_min_delay -from [get_pins -hier *SCK_O_reg_reg/C] -to [get_pins -hier *USRCCLKO] 0.100
## SPI FLASH END ##
#set_max_delay 10.000 -from [get_cells *user_side_FIFO/tx_fifo_i/*rd_addr_txfer*] -to [get_cells *user_side_FIFO/tx_fifo_i/wr_rd_addr*]
#============================= Multicycle Paths =======================
## SPI FLASH BEGIN ##
set_multicycle_path -setup -from clk_sck -to     [get_clocks -of_objects [get_pins -hierarchical *ext_spi_clk]] 2
set_multicycle_path -hold -end -from clk_sck -to [get_clocks -of_objects [get_pins -hierarchical *ext_spi_clk]] 1
set_multicycle_path -setup -start -from          [get_clocks -of_objects [get_pins -hierarchical *ext_spi_clk]] -to clk_sck 2
set_multicycle_path -hold -from                  [get_clocks -of_objects [get_pins -hierarchical *ext_spi_clk]] -to clk_sck 1
## SPI FLASH END ##
#============================= Case Analysis  =========================
## SPI FLASH BEGIN ##
# You must provide all the delay numbers
# CCLK delay is 0.5, 6.7 ns min/max for K7-2; refer Data sheet
# Consider the max delay for worst case analysis
set cclk_delay 6.7
# Following are the SPI device parameters
# Max Tco
set tco_max 7
# Min Tco
set tco_min 1
# Setup time requirement
set tsu 2
# Hold time requirement
set th 3
# Following are the board/trace delay numbers
# Assumption is that all Data lines are matched
set tdata_trace_delay_max 0.25
set tdata_trace_delay_min 0.25
set tclk_trace_delay_max 0.2
set tclk_trace_delay_min 0.2
### End of user provided delay numbers
## SPI FLASH END ##
#============================= Disable Timing =========================
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets gtx_clk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_pins FDCE_inst/C] 
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets art_P]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets art_N]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {CLK_40_IBUF}]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets art_in_i]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets art_P]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets art_N]
#======================================================================

#====================== PHYSICAL CONSTRAINTS SECTION ==================
#====================== ASYNC_REG for synchronizers ===================
#set_property ASYNC_REG true [get_cells xadc_instance/CDCC_200to125/sync_block_CDCC_0[*].FDRE_sync_CDCC_0]
#set_property ASYNC_REG true [get_cells xadc_instance/CDCC_200to125/sync_block_CDCC_1[*].FDRE_sync_CDCC_1]

set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_50to125/sync_block_CDCC_0[*].FDRE_sync_CDCC_0]
set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_50to125/sync_block_CDCC_1[*].FDRE_sync_CDCC_1]

set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_125to50/sync_block_CDCC_0[*].FDRE_sync_CDCC_0]
set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_125to50/sync_block_CDCC_1[*].FDRE_sync_CDCC_1]

set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_125to40/sync_block_CDCC_0[*].FDRE_sync_CDCC_0]
set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_125to40/sync_block_CDCC_1[*].FDRE_sync_CDCC_1]

set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_40to125/sync_block_CDCC_0[*].FDRE_sync_CDCC_0]
set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_40to125/sync_block_CDCC_1[*].FDRE_sync_CDCC_1]

set_property ASYNC_REG true [get_cells readout_vmm/vmmEventDone_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmEventDone_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWordReady_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWordReady_ff_sync_reg]

set_property ASYNC_REG true [get_cells readout_vmm/vmmWord_stage1_reg[*]]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWord_ff_sync_reg[*]]                                                                            

set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/trigger_pulse_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/trigger_pulse_ff_sync_reg]
#=====================================================================

#====================== I/O Placement - IOSTANDARDS ===================
############################# MDT #############################
set_property PACKAGE_PIN V4      [get_ports X_2V5_DIFF_CLK_P]
set_property PACKAGE_PIN W4      [get_ports X_2V5_DIFF_CLK_N]
set_property IOSTANDARD LVDS_25  [get_ports X_2V5_DIFF_CLK_P]
set_property IOSTANDARD LVDS_25  [get_ports X_2V5_DIFF_CLK_N]
#set_property PACKAGE_PIN V20     [get_ports CLK_40]
#set_property IOSTANDARD LVCMOS33 [get_ports CLK_40]
############################# Ethernet #############################
set_property PACKAGE_PIN F6      [get_ports gtrefclk_p]
set_property PACKAGE_PIN E6      [get_ports gtrefclk_n]
set_property PACKAGE_PIN A8      [get_ports rxn]
set_property PACKAGE_PIN B8      [get_ports rxp]
set_property PACKAGE_PIN A4      [get_ports txn]
set_property PACKAGE_PIN B4      [get_ports txp]
set_property PACKAGE_PIN AA8     [get_ports phy_int]
set_property IOSTANDARD LVCMOS25 [get_ports phy_int]
set_property PACKAGE_PIN AB8     [get_ports phy_rstn_out]
set_property IOSTANDARD LVCMOS25 [get_ports phy_rstn_out]
#########################TRIGGER-MDT#############################
# CTF 1.0 External Trigger
set_property PACKAGE_PIN V18     [get_ports CH_TRIGGER]
set_property IOSTANDARD LVCMOS33 [get_ports CH_TRIGGER]

set_property PACKAGE_PIN W21     [get_ports TRIGGER_OUT_P]
set_property PACKAGE_PIN W22     [get_ports TRIGGER_OUT_N]
set_property IOSTANDARD LVCMOS33 [get_ports TRIGGER_OUT_P]
set_property IOSTANDARD LVCMOS33 [get_ports TRIGGER_OUT_N]

######################## ETHERNET-MDT##################################

#set_property PACKAGE_PIN AB7 [get_ports SDA_inout]
#set_property IOSTANDARD LVCMOS25 [get_ports SDA_inout]

#set_property PACKAGE_PIN AB6 [get_ports SCL_out]
#set_property IOSTANDARD LVCMOS25 [get_ports SCL_out]



#set_property PACKAGE_PIN W19 [get_ports glbl_rst]
#set_property IOSTANDARD LVCMOS25 [get_ports glbl_rst]

#########################DIP SWITCES VMM3#############################
#set_property PACKAGE_PIN P15     [get_ports DIP_5]
#set_property IOSTANDARD LVCMOS33 [get_ports DIP_5]

#set_property PACKAGE_PIN R16     [get_ports DIP_4]
#set_property IOSTANDARD LVCMOS33 [get_ports DIP_4]

#set_property PACKAGE_PIN N13     [get_ports DIP_3]
#set_property IOSTANDARD LVCMOS33 [get_ports DIP_3]

#set_property PACKAGE_PIN N14     [get_ports DIP_2]
#set_property IOSTANDARD LVCMOS33 [get_ports DIP_2]

#set_property PACKAGE_PIN P16     [get_ports DIP_1]
#set_property IOSTANDARD LVCMOS33 [get_ports DIP_1]

#set_property PACKAGE_PIN R17     [get_ports DIP_0]
#set_property IOSTANDARD LVCMOS33 [get_ports DIP_0]
#########################   LEDs MDT  #############################
#set_property PACKAGE_PIN Y17 [get_ports LED_D12]
#set_property IOSTANDARD LVCMOS25 [get_ports LED_D12]

#set_property PACKAGE_PIN U7 [get_ports LED_D13]
#set_property IOSTANDARD LVCMOS25 [get_ports LED_D13]

#set_property PACKAGE_PIN F4 [get_ports LED_D14]
#set_property IOSTANDARD LVCMOS25 [get_ports LED_D14]

#set_property PACKAGE_PIN P20 [get_ports LED_D15]
#set_property IOSTANDARD LVCMOS25 [get_ports LED_D15]

#set_property PACKAGE_PIN T3 [get_ports LED_D16]
#set_property IOSTANDARD LVCMOS25 [get_ports LED_D16]
#########################DATA0 VMM3#############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_1_P]
set_property PACKAGE_PIN B16 [get_ports DATA0_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_1_N]

#########################DATA1 VMM3#############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_1_P]
set_property PACKAGE_PIN C15 [get_ports DATA1_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_1_N]

##########################DI-VMM2##############################

#set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_1_P]
#set_property PACKAGE_PIN L13 [get_ports DI_1_N]
#set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_1_N]

##########################DO-VMM2##############################

#set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_1_P]
#set_property PACKAGE_PIN M20 [get_ports DO_1_N]
#set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_1_N]

################################################################
######################### BANK 15 ##############################
################################################################

#INTERNAL_VREF_BANK15 = 0.5;

##########################CKBC VMM3##############################

set_property PACKAGE_PIN J19 [get_ports CKBC_1_P]
set_property PACKAGE_PIN H19 [get_ports CKBC_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_1_P]

##########################CKTP VMM3##############################

set_property PACKAGE_PIN H20 [get_ports CKTP_1_P]
set_property PACKAGE_PIN G20 [get_ports CKTP_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_1_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_1_N]

##########################CKTK VMM3##############################

set_property PACKAGE_PIN M21 [get_ports CKTK_1_P]
set_property PACKAGE_PIN L21 [get_ports CKTK_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_1_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_1_N]

############################# SDI B17 ###########################

set_property PACKAGE_PIN G17     [get_ports SDI_1]
set_property IOSTANDARD LVCMOS12 [get_ports SDI_1]

############################# SDO B18 ###########################

set_property PACKAGE_PIN G18 [get_ports SDO_1]
set_property IOSTANDARD LVCMOS12 [get_ports SDO_1]

############################ MO/TDO/PDO #########################

#set_property PACKAGE_PIN H13 [get_ports MO_p]
#set_property PACKAGE_PIN G13 [get_ports MO_n]

#set_property IOSTANDARD DIFF_HSUL_12 [get_ports MO_p]
#set_property IOSTANDARD DIFF_HSUL_12 [get_ports MO_n]

#set_property PACKAGE_PIN J14 [get_ports TDO_p]
#set_property PACKAGE_PIN H14 [get_ports TDO_n]

#set_property IOSTANDARD DIFF_HSUL_12 [get_ports TDO_p]
#set_property IOSTANDARD DIFF_HSUL_12 [get_ports TDO_n]

#set_property PACKAGE_PIN G15 [get_ports PDO_p]
#set_property PACKAGE_PIN G16 [get_ports PDO_n]

#set_property IOSTANDARD DIFF_HSUL_12 [get_ports PDO_p]
#set_property IOSTANDARD DIFF_HSUL_12 [get_ports PDO_n]

############################# TKI TKO ###########################

set_property PACKAGE_PIN K17 [get_ports TKI_P]
set_property PACKAGE_PIN J17 [get_ports TKI_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports TKI_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports TKI_N]


set_property PACKAGE_PIN J20 [get_ports TKO_P]
set_property PACKAGE_PIN J21 [get_ports TKO_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports TKO_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports TKO_N]
 

################################################################
########################## BANK  16 ##############################
################################################################

##########################WEN VMM3##############################

#set_property PACKAGE_PIN D17 [get_ports WEN_1_P]
#set_property PACKAGE_PIN C17 [get_ports WEN_1_N]

#set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_1_P]
#set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_1_N]

##########################ENA VMM3##############################

set_property PACKAGE_PIN F18 [get_ports ENA_1_P]
set_property PACKAGE_PIN E18 [get_ports ENA_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_1_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_1_N]

##########################CKDT VMM3##############################

set_property PACKAGE_PIN B20 [get_ports CKDT_1_P]
set_property PACKAGE_PIN A20 [get_ports CKDT_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_1_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_1_N]

##########################ART VMM3##############################

set_property PACKAGE_PIN C18 [get_ports art_clk_P]
set_property PACKAGE_PIN C19 [get_ports art_clk_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports art_clk_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports art_clk_N]

set_property PACKAGE_PIN A18 [get_ports art_P]
set_property PACKAGE_PIN A19 [get_ports art_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports art_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports art_N]


########################## ART OUT ##############################

set_property PACKAGE_PIN B17 [get_ports art_clkout_P]
set_property PACKAGE_PIN B18 [get_ports art_clkout_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports art_clkout_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports art_clkout_N]


set_property PACKAGE_PIN A15 [get_ports ART_OUT_P]
set_property PACKAGE_PIN A16 [get_ports ART_OUT_N]


set_property IOSTANDARD DIFF_HSUL_12 [get_ports ART_OUT_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ART_OUT_N]


##########################SPI VMM3##############################

#######CS B19 @VMM3
set_property PACKAGE_PIN E19 [get_ports VMM_CS]
set_property IOSTANDARD LVCMOS12 [get_ports VMM_CS]

########SCK B20 @VMM3
set_property PACKAGE_PIN D19 [get_ports VMM_SCK]
set_property IOSTANDARD LVCMOS12 [get_ports VMM_SCK]

###########################XADC MDT#############################
# Dedicated Analog Inputs
#set_property IOSTANDARD LVCMOS25 [get_ports VP_0]
#set_property PACKAGE_PIN L10 [get_ports VP_0]
#set_property IOSTANDARD LVCMOS25 [get_ports VN_0]
#set_property PACKAGE_PIN M9 [get_ports VN_0]

## Analog Multiplexer Pins
#set_property PACKAGE_PIN T20 [get_ports MuxAddr0]
#set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr0]
#set_property PACKAGE_PIN P14 [get_ports MuxAddr1]
#set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr1]
#set_property PACKAGE_PIN R14 [get_ports MuxAddr2]
#set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr2]
#set_property PACKAGE_PIN R18 [get_ports MuxAddr3_p]
#set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr3_p]
#set_property PACKAGE_PIN T18 [get_ports MuxAddr3_n]
#set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr3_n]

#set_property PACKAGE_PIN G16 [get_ports Vaux8_v_n]
#set_property PACKAGE_PIN G15 [get_ports Vaux8_v_p]

#set_property PACKAGE_PIN H14 [get_ports Vaux1_v_n]
#set_property PACKAGE_PIN J14 [get_ports Vaux1_v_p]

#set_property PACKAGE_PIN J22 [get_ports Vaux2_v_p]
#set_property PACKAGE_PIN H22 [get_ports Vaux2_v_n]
#set_property PACKAGE_PIN K22 [get_ports Vaux3_v_n]
#set_property PACKAGE_PIN K21 [get_ports Vaux3_v_p]

#set_property PACKAGE_PIN H15 [get_ports Vaux9_v_n]
#set_property PACKAGE_PIN J15 [get_ports Vaux9_v_p]

#set_property PACKAGE_PIN G20 [get_ports Vaux10_v_n]
#set_property PACKAGE_PIN H20 [get_ports Vaux10_v_p]

#set_property PACKAGE_PIN N22 [get_ports Vaux10_v_n]
#set_property PACKAGE_PIN M22 [get_ports Vaux10_v_p]

#set_property PACKAGE_PIN L21 [get_ports Vaux11_v_n]
#set_property PACKAGE_PIN M21 [get_ports Vaux11_v_p]

#set_property PACKAGE_PIN L19 [get_ports Vaux11_v_n]
#set_property PACKAGE_PIN L20 [get_ports Vaux11_v_p]

#set_property IOSTANDARD LVCMOS12 [get_ports Vaux0_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux0_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux1_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux1_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux2_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux2_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux3_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux3_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux8_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux8_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux9_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux9_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux10_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux10_v_p]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux11_v_n]
#set_property IOSTANDARD LVCMOS12 [get_ports Vaux11_v_p]

######################### SPI FLASH ##########################

set_property CONFIG_MODE SPIx1 [current_design]
#set_property IOSTANDARD LVCMOS25 [get_ports SPI_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports IO0_IO]
set_property IOSTANDARD LVCMOS33 [get_ports IO1_IO]
set_property IOSTANDARD LVCMOS33 [get_ports SS_IO]
#set_property PACKAGE_PIN V22 [get_ports SPI_CLK]
set_property PACKAGE_PIN P22 [get_ports IO0_IO]
set_property PACKAGE_PIN R22 [get_ports IO1_IO]
set_property PACKAGE_PIN T19 [get_ports SS_IO]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
#set_property OFFCHIP_TERM NONE [get_ports SPI_CLK]
set_property OFFCHIP_TERM NONE [get_ports IO0_IO]
set_property OFFCHIP_TERM NONE [get_ports IO1_IO]
set_property OFFCHIP_TERM NONE [get_ports SS_IO]

#=================== ASYNC REG =======================================
#set_property ASYNC_REG true [get_cells xadc_instance/CDCC_200to125/sync_block_CDCC_0[*].FDRE_sync_CDCC_0]
#set_property ASYNC_REG true [get_cells xadc_instance/CDCC_200to125/sync_block_CDCC_1[*].FDRE_sync_CDCC_1]

set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_50to125/sync_block_CDCC_0[*].FDRE_sync_CDCC_0]
set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_50to125/sync_block_CDCC_1[*].FDRE_sync_CDCC_1]

set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_125to50/sync_block_CDCC_0[*].FDRE_sync_CDCC_0]
set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_125to50/sync_block_CDCC_1[*].FDRE_sync_CDCC_1]

set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_125to40/sync_block_CDCC_0[*].FDRE_sync_CDCC_0]
set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_125to40/sync_block_CDCC_1[*].FDRE_sync_CDCC_1]

set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_40to125/sync_block_CDCC_0[*].FDRE_sync_CDCC_0]
set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_40to125/sync_block_CDCC_1[*].FDRE_sync_CDCC_1]

set_property ASYNC_REG true [get_cells readout_vmm/vmmEventDone_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmEventDone_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWordReady_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWordReady_ff_sync_reg]

set_property ASYNC_REG true [get_cells readout_vmm/vmmWord_stage1_reg[*]]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWord_ff_sync_reg[*]]                                                                            

set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/trigger_pulse_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/trigger_pulse_ff_sync_reg]
#=====================================================================