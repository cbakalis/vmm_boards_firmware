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
# Continuous readout generated clock
create_generated_clock -name roClkCont -source [get_pins mmcm_master/inst/mmcm_adv_inst/CLKOUT4] -divide_by 2 [get_pins readout_vmm/vmm_ckdt_i_reg/Q]

# CKBC generated clock
create_generated_clock -name ckbc_clk -source [get_pins mmcm_master/inst/mmcm_adv_inst/CLKOUT2] -divide_by 4 [get_pins ckbc_cktp_generator/ckbc_generator/ckbc_out_reg/Q]


# ODDR/CKBC
create_generated_clock -name ckbc_1 -source [get_pins vmm_oddr_inst/ODDR_CKBC_1/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKBC_1/Q]
create_generated_clock -name ckbc_2 -source [get_pins vmm_oddr_inst/ODDR_CKBC_2/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKBC_2/Q]
create_generated_clock -name ckbc_3 -source [get_pins vmm_oddr_inst/ODDR_CKBC_3/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKBC_3/Q]
create_generated_clock -name ckbc_4 -source [get_pins vmm_oddr_inst/ODDR_CKBC_4/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKBC_4/Q]
create_generated_clock -name ckbc_5 -source [get_pins vmm_oddr_inst/ODDR_CKBC_5/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKBC_5/Q]
create_generated_clock -name ckbc_6 -source [get_pins vmm_oddr_inst/ODDR_CKBC_6/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKBC_6/Q]
create_generated_clock -name ckbc_7 -source [get_pins vmm_oddr_inst/ODDR_CKBC_7/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKBC_7/Q]
create_generated_clock -name ckbc_8 -source [get_pins vmm_oddr_inst/ODDR_CKBC_8/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKBC_8/Q]

# ODDR/CKART
create_generated_clock -name ckart_1 -source [get_pins vmm_oddr_inst/ODDR_CKART_1/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKART_1/Q]
create_generated_clock -name ckart_2 -source [get_pins vmm_oddr_inst/ODDR_CKART_2/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKART_2/Q]
create_generated_clock -name ckart_3 -source [get_pins vmm_oddr_inst/ODDR_CKART_3/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKART_3/Q]
create_generated_clock -name ckart_4 -source [get_pins vmm_oddr_inst/ODDR_CKART_4/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKART_4/Q]
create_generated_clock -name ckart_5 -source [get_pins vmm_oddr_inst/ODDR_CKART_5/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKART_5/Q]
create_generated_clock -name ckart_6 -source [get_pins vmm_oddr_inst/ODDR_CKART_6/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKART_6/Q]
create_generated_clock -name ckart_7 -source [get_pins vmm_oddr_inst/ODDR_CKART_7/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKART_7/Q]
create_generated_clock -name ckart_8 -source [get_pins vmm_oddr_inst/ODDR_CKART_8/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKART_8/Q]
#============================= Clock Groups ===========================
set_clock_groups -group [get_clocks -include_generated_clocks -of_objects [get_pins mmcm_master/inst/mmcm_adv_inst/CLKIN1]] -group [get_clocks -include_generated_clocks -of_objects [get_pins core_wrapper/U0/core_clocking_i/mmcm_adv_inst/CLKIN1]] -asynchronous
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

#============================= Primary Clocks =========================
#======================================================================


#======================= TIMING EXCEPTIONS SECTION ====================
#=============================== False Paths ==========================
#VIO
#set_false_path -from [get_cells vio_ckbc_cktp/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[*].PROBE_OUT0_INST/Probe_out_reg[*]]

# CKTP/CKBC enabling false path
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_start_i_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells ckbc_cktp_generator/cktp_max_module/inhibit_async_i_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells ckbc_cktp_generator/cktp_max_module/fsm_enable_i_reg]
set_false_path -from [get_cells FSM_sequential_state_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_max_module/inhibit_async_i_reg]
set_false_path -from [get_cells FSM_sequential_state_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_start_i_reg]
set_false_path -from [get_cells FSM_sequential_state_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_max_module/fsm_enable_i_reg]
set_false_path -from [get_cells FSM_sequential_state_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_trint_module/cktp_start_s_0_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells ckbc_cktp_generator/cktp_trint_module/cktp_start_s_0_reg]
set_false_path -from [get_cells ckbc_cktp_generator/cktp_trint_module/trint_i_reg] -to [get_cells ckbc_cktp_generator/cktp_trint_module/trint_s_0_reg]

# Trigger related false paths
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells trigger_instance/trext_stage1_reg]

# AXI SPI related false paths
set_false_path -from [get_cells axi4_spi_instance/CDCC_50to125/data_in_reg_reg[*]] -to [get_cells axi4_spi_instance/CDCC_50to125/data_sync_stage_0_reg[*]]
set_false_path -from [get_cells axi4_spi_instance/CDCC_125to50/data_in_reg_reg[*]] -to [get_cells axi4_spi_instance/CDCC_125to50/data_sync_stage_0_reg[*]]
set_false_path -from [get_cells axi4_spi_instance/myIP_reg[*]]
set_false_path -from [get_cells axi4_spi_instance/myMAC_reg[*]]
set_false_path -from [get_cells axi4_spi_instance/destIP_reg[*]]

# UDP configuration related false paths
set_false_path -from [get_cells udp_din_conf_block/CDCC_40to125/data_in_reg_reg[*]] -to [get_cells udp_din_conf_block/CDCC_40to125/data_sync_stage_0_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/CDCC_125to40/data_in_reg_reg[*]] -to [get_cells udp_din_conf_block/CDCC_125to40/data_sync_stage_0_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/myIP_set_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/myMAC_set_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/destIP_set_reg[*]]

## MMCM related false paths
#set_false_path -from [get_cells clk_400_low_jitter_inst/inst/seq_reg1_reg[*]] -to [get_cells clk_400_low_jitter_inst/inst/clkout1_buf]

# Readout related false paths
set_false_path -from [get_cells packet_formation_instance/triggerVmmReadout_i_reg] -to [get_cells readout_vmm/trigger_pulse_stage1_reg]
#set_false_path -from [get_cells readout_vmm/daq_enable_stage1_Dt_reg] -to [get_cells readout_vmm/daq_enable_ff_sync_Dt_reg]
set_false_path -from [get_cells daq_enable_i_reg] -to [get_cells readout_vmm/daq_enable_stage1_reg]
set_false_path -from [get_cells readout_vmm/vmmEventDone_i_reg] -to [get_cells readout_vmm/vmmEventDone_stage1_reg]
set_false_path -from [get_cells readout_vmm/vmmWord_i_reg[*]] -to [get_cells readout_vmm/vmmWord_stage1_reg[*]]
set_false_path -from [get_cells readout_vmm/vmmWordReady_i_reg] -to [get_cells readout_vmm/vmmWordReady_stage1_reg]
set_false_path -from [get_cells readout_vmm/reading_out_word_reg] -to [get_cells readout_vmm/reading_out_word_stage1_reg]
set_false_path -from [get_cells readout_vmm/cktkSent_reg] -to [get_cells readout_vmm/cktkSent_stage1_reg]
set_false_path -from [get_cells packet_formation_instance/vmmId_i_reg[*]] -to [get_cells readout_vmm/vmm_data0_stage1_reg]
set_false_path -from [get_cells packet_formation_instance/vmmId_i_reg[*]] -to [get_cells readout_vmm/vmm_data1_stage1_reg]
set_false_path -from [get_cells daq_enable_i_reg] -to [get_cells readout_vmm/daq_enable_stage1_Dt_reg]

#CKBC related false paths
set_false_path -from [get_cells packet_formation_instance/pfBusy_i_reg] -to [get_cells event_timing_reset_instance/pfBusy_i_reg]
set_false_path -from [get_cells daq_enable_i_reg] -to [get_cells event_timing_reset_instance/daqEnable_i_reg]
set_false_path -from [get_cells event_timing_reset_instance/reset_latched_i_reg] -to [get_cells event_timing_reset_instance/reset_latched_s_0_reg]
set_false_path -from [get_cells event_timing_reset_instance/rst_i_reg] -to [get_cells event_timing_reset_instance/rst_s_0_reg]
set_false_path -from [get_cells event_timing_reset_instance/rst_done_reg] -to [get_cells event_timing_reset_instance/rst_done_i_reg]

#e-link false paths
set_false_path -from [get_cells vio_elink_instance/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[*].PROBE_OUT0_INST/Probe_out_reg[*]]

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

#====================== PHYSICAL CONSTRAINTS SECTION ==================
#====================== ASYNC_REG for synchronizers ===================
set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_50to125/data_sync_stage_0_reg[*]]
set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_50to125/data_out_s_int_reg[*]]

set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_125to50/data_sync_stage_0_reg[*]]
set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_125to50/data_out_s_int_reg[*]]

set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_125to40/data_sync_stage_0_reg[*]]
set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_125to40/data_out_s_int_reg[*]]

set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_40to125/data_sync_stage_0_reg[*]]
set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_40to125/data_out_s_int_reg[*]]

set_property ASYNC_REG true [get_cells readout_vmm/vmmEventDone_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmEventDone_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWordReady_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWordReady_ff_sync_reg]

set_property ASYNC_REG true [get_cells readout_vmm/vmmWord_stage1_reg[*]]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWord_ff_sync_reg[*]]                                                                            

set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_stage1_Dt_reg]
set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_ff_sync_Dt_reg]

set_property ASYNC_REG true [get_cells readout_vmm/trigger_pulse_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/trigger_pulse_ff_sync_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/cktk_max_i_reg[*]]
#set_property ASYNC_REG true [get_cells readout_vmm/cktk_max_sync_reg[*]]
set_property ASYNC_REG true [get_cells readout_vmm/reading_out_word_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/reading_out_word_ff_sync_reg]

set_property ASYNC_REG true [get_cells readout_vmm/vmm_data0_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmm_data0_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmm_data1_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmm_data1_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/cktkSent_stage1_reg]
set_property ASYNC_REG true [get_cells readout_vmm/cktkSent_ff_sync_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWord_i_reg[*]]
set_property ASYNC_REG true [get_cells readout_vmm/vmmWord_stage1_reg[*]]
set_property ASYNC_REG true [get_cells readout_vmm/vmmEventDone_i_reg]
set_property ASYNC_REG true [get_cells readout_vmm/vmmEventDone_stage1_reg]
set_property ASYNC_REG true [get_cells daq_enable_i_reg]
set_property ASYNC_REG true [get_cells readout_vmm/daq_enable_stage1_reg]

#set_property ASYNC_REG true [get_cells udp_din_conf_block/fpga_config_logic/daq_on_i_reg]
#set_property ASYNC_REG true [get_cells udp_din_conf_block/fpga_config_logic/daq_on_sync_reg]
#set_property ASYNC_REG true [get_cells udp_din_conf_block/fpga_config_logic/ext_trg_i_reg]
#set_property ASYNC_REG true [get_cells udp_din_conf_block/fpga_config_logic/ext_trg_sync_reg]
#=====================================================================

#======================= Configurable CKBC/CKTP Constraints ==========
# 160 MHz global clock buffer placement constraint
#set_property LOC BUFGCTRL_X0Y1 [get_cells mmcm_ckbc_cktp/inst/clkout1_buf]
# 500 Mhz global clock buffer placement constraint
#set_property LOC BUFGCTRL_X0Y2 [get_cells mmcm_ckbc_cktp/inst/clkout2_buf]

# CKBC global buffer placement constraint
set_property LOC BUFGCTRL_X0Y0 [get_cells ckbc_cktp_generator/CKBC_BUFGCE]
# register-to-CKBC buffer placement constraint
set_property LOC SLICE_X83Y145 [get_cells ckbc_cktp_generator/ckbc_generator/ckbc_out_reg]

# CKTP global buffer placement constraint
set_property LOC BUFGCTRL_X0Y3 [get_cells ckbc_cktp_generator/CKTP_BUFGMUX]
# register-to-CKTP buffer placement constraint
set_property LOC SLICE_X83Y146 [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg]
set_property LOC SLICE_X83Y147 [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]

# critical register of cktp generator placement constraint
set_property LOC SLICE_X82Y146 [get_cells ckbc_cktp_generator/cktp_generator/start_align_cnt_reg]

#ASYNC_REG to skewing pipeline
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_02_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_04_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_06_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_08_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_10_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_12_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_14_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_16_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_18_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_20_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_22_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_24_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_26_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_28_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_30_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_32_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_34_reg]
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_36_reg]

#False paths for skewing pipeline (Caution!! Those lines might not be needed. It should be validated with an oscilloscope) 
set_false_path -from [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg] -to [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]
set_false_path -from [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg] -to [get_cells ckbc_cktp_generator/skewing_module/cktp_02_reg]
#set_false_path -from [get_cells ckbc_cktp_generator/skewing_module/cktp_02_reg] -to [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]

# PBLOCKS (obsolete)
#create_pblock pblock_skewing_module
#add_cells_to_pblock [get_pblocks pblock_skewing_module] [get_cells -quiet [list ckbc_cktp_generator/skewing_module]]
#resize_pblock [get_pblocks pblock_skewing_module] -add {SLICE_X82Y146:SLICE_X83Y148}
#create_pblock pblock_ckbc_generator_block
#add_cells_to_pblock [get_pblocks pblock_ckbc_generator_block] [get_cells -quiet [list ckbc_cktp_generator/ckbc_generator]]
#resize_pblock [get_pblocks pblock_ckbc_generator_block] -add {SLICE_X76Y138:SLICE_X83Y146}
#resize_pblock [get_pblocks pblock_ckbc_generator_block] -add {RAMB18_X4Y56:RAMB18_X4Y57}
#resize_pblock [get_pblocks pblock_ckbc_generator_block] -add {RAMB36_X4Y28:RAMB36_X4Y28}
#create_pblock pblock_cktp_generator_block
#add_cells_to_pblock [get_pblocks pblock_cktp_generator_block] [get_cells -quiet [list ckbc_cktp_generator/cktp_generator]]
#resize_pblock [get_pblocks pblock_cktp_generator_block] -add {SLICE_X74Y147:SLICE_X83Y160}
#resize_pblock [get_pblocks pblock_cktp_generator_block] -add {RAMB18_X4Y60:RAMB18_X4Y63}
#resize_pblock [get_pblocks pblock_cktp_generator_block] -add {RAMB36_X4Y30:RAMB36_X4Y31}
#============================================================================================

#====================== I/O Placement - IOSTANDARDS ===================
############################# MMFE8 #############################
set_property PACKAGE_PIN W19     [get_ports X_2V5_DIFF_CLK_P]
set_property PACKAGE_PIN W20     [get_ports X_2V5_DIFF_CLK_N]
set_property IOSTANDARD LVDS_25  [get_ports X_2V5_DIFF_CLK_P]
set_property IOSTANDARD LVDS_25  [get_ports X_2V5_DIFF_CLK_N]

############################# Ethernet #############################
set_property PACKAGE_PIN F6      [get_ports gtrefclk_p]
set_property PACKAGE_PIN E6      [get_ports gtrefclk_n]
set_property PACKAGE_PIN A8      [get_ports rxn]
set_property PACKAGE_PIN B8      [get_ports rxp]
set_property PACKAGE_PIN A4      [get_ports txn]
set_property PACKAGE_PIN B4      [get_ports txp]
set_property PACKAGE_PIN P16     [get_ports phy_int]
set_property IOSTANDARD LVCMOS25 [get_ports phy_int]
set_property PACKAGE_PIN R17     [get_ports phy_rstn_out]
set_property IOSTANDARD LVCMOS25 [get_ports phy_rstn_out]

#########################TRIGGER#############################
# CTF 1.0 External Trigger
set_property PACKAGE_PIN Y21    [get_ports EXT_TRIGGER_P]
set_property PACKAGE_PIN Y22    [get_ports EXT_TRIGGER_N]
set_property IOSTANDARD LVDS_25 [get_ports EXT_TRIGGER_P]
set_property IOSTANDARD LVDS_25 [get_ports EXT_TRIGGER_N]


########################E-LINK###############################
####--------------------------------------------------------###
#Receiving data from RXP_1/RXN_1 of MMFE8 miniSAS. (DAQ)
set_property PACKAGE_PIN AA9 [get_ports ELINK_DAQ_RX_P]
set_property PACKAGE_PIN AB10 [get_ports ELINK_DAQ_RX_N]

#Transmitting data to TXP_1/TXN_1 of MMFE8 miniSAS. (DAQ)
# ?? T16 U16
set_property PACKAGE_PIN W14 [get_ports ELINK_DAQ_TX_P]
set_property PACKAGE_PIN Y14 [get_ports ELINK_DAQ_TX_N]

#ELINK clock RXP_0/RXN_0 of MMFE8 miniSAS. (DAQ)
set_property PACKAGE_PIN V13 [get_ports ELINK_DAQ_CLK_P]
set_property PACKAGE_PIN V14 [get_ports ELINK_DAQ_CLK_N]

#LOCK LED
set_property IOSTANDARD LVCMOS12 [get_ports LED_LOCKED]
set_property PACKAGE_PIN Y17      [get_ports LED_LOCKED]

#W11 P
#W12 N TTC RXP_2
####--------------------------------------------------------###

##Receiving data from RXP_1/RXN_1 of MMFE8 miniSAS. (TTC)
#set_property PACKAGE_PIN AA9         [get_ports ELINK_TTC_RX_P]
#set_property PACKAGE_PIN AB10        [get_ports ELINK_TTC_RX_N]

##ELINK TTC Clock
#set_property PACKAGE_PIN W11         [get_ports ELINK_TTC_CLK_P]
#set_property PACKAGE_PIN W12         [get_ports ELINK_TTC_CLK_N]
####--------------------------------------------------------###

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ELINK_DAQ_RX_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ELINK_DAQ_RX_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ELINK_DAQ_TX_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ELINK_DAQ_TX_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ELINK_DAQ_CLK_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ELINK_DAQ_CLK_N]

#set_property IOSTANDARD DIFF_HSUL_12 [get_ports ELINK_TTC_RX_P]
#set_property IOSTANDARD DIFF_HSUL_12 [get_ports ELINK_TTC_RX_N]
#set_property IOSTANDARD DIFF_HSUL_12 [get_ports ELINK_TTC_CLK_P]
#set_property IOSTANDARD DIFF_HSUL_12 [get_ports ELINK_TTC_CLK_N]

# Create clock on the clock input pad and use it as reference clock in set_input_delay

#create_clock -period 25.000 -name clk_elink [get_ports ELINK_DAQ_CLK_P]

create_clock -period 12.500 -name clk_elink_serdes
#80  mbps = 12.5
#160 mbps = 6.25
#320 mbps = 3.125

set_input_delay -clock clk_elink_serdes -max 0.100 [get_ports ELINK_DAQ_RX_P]

set_input_delay -clock clk_elink_serdes -min 0.200 [get_ports ELINK_DAQ_RX_P]

set_output_delay -clock clk_elink_serdes 2.000 [get_ports ELINK_DAQ_TX_P]

#########################DATA0 VMM2#############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_1_P]
set_property PACKAGE_PIN K17         [get_ports DATA0_1_P]
set_property PACKAGE_PIN J17         [get_ports DATA0_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_2_P]
set_property PACKAGE_PIN G17         [get_ports DATA0_2_P]
set_property PACKAGE_PIN G18         [get_ports DATA0_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_3_P]
set_property PACKAGE_PIN B17         [get_ports DATA0_3_P]
set_property PACKAGE_PIN B18         [get_ports DATA0_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_4_P]
set_property PACKAGE_PIN C18         [get_ports DATA0_4_P]
set_property PACKAGE_PIN C19         [get_ports DATA0_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_5_P]
set_property PACKAGE_PIN E1          [get_ports DATA0_5_P]
set_property PACKAGE_PIN D1          [get_ports DATA0_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_6_P]
set_property PACKAGE_PIN M1          [get_ports DATA0_6_P]
set_property PACKAGE_PIN L1          [get_ports DATA0_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_7_P]
set_property PACKAGE_PIN Y4          [get_ports DATA0_7_P]
set_property PACKAGE_PIN AA4         [get_ports DATA0_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_8_P]
set_property PACKAGE_PIN Y6          [get_ports DATA0_8_P]
set_property PACKAGE_PIN AA6         [get_ports DATA0_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_8_N]

#########################DATA1 VMM2#############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_1_P]
set_property PACKAGE_PIN K13         [get_ports DATA1_1_P]
set_property PACKAGE_PIN K14         [get_ports DATA1_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_2_P]
set_property PACKAGE_PIN H17         [get_ports DATA1_2_P]
set_property PACKAGE_PIN H18         [get_ports DATA1_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_3_P]
set_property PACKAGE_PIN B15         [get_ports DATA1_3_P]
set_property PACKAGE_PIN B16         [get_ports DATA1_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_4_P]
set_property PACKAGE_PIN D20         [get_ports DATA1_4_P]
set_property PACKAGE_PIN C20         [get_ports DATA1_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_5_P]
set_property PACKAGE_PIN E2          [get_ports DATA1_5_P]
set_property PACKAGE_PIN D2          [get_ports DATA1_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_6_P]
set_property PACKAGE_PIN L3          [get_ports DATA1_6_P]
set_property PACKAGE_PIN K3          [get_ports DATA1_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_7_P]
set_property PACKAGE_PIN W2          [get_ports DATA1_7_P]
set_property PACKAGE_PIN Y2          [get_ports DATA1_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_8_P]
set_property PACKAGE_PIN Y8          [get_ports DATA1_8_P]
set_property PACKAGE_PIN Y7          [get_ports DATA1_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_8_N]

##########################CKDT VMM2##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_1_P]
set_property PACKAGE_PIN J20         [get_ports CKDT_1_P]
set_property PACKAGE_PIN J21         [get_ports CKDT_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_2_P]
set_property PACKAGE_PIN C14         [get_ports CKDT_2_P]
set_property PACKAGE_PIN C15         [get_ports CKDT_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_3_P]
set_property PACKAGE_PIN B21         [get_ports CKDT_3_P]
set_property PACKAGE_PIN A21         [get_ports CKDT_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_4_P]
set_property PACKAGE_PIN B1          [get_ports CKDT_4_P]
set_property PACKAGE_PIN A1          [get_ports CKDT_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_5_P]
set_property PACKAGE_PIN F3          [get_ports CKDT_5_P]
set_property PACKAGE_PIN E3          [get_ports CKDT_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_6_P]
set_property PACKAGE_PIN U2          [get_ports CKDT_6_P]
set_property PACKAGE_PIN V2          [get_ports CKDT_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_7_P]
set_property PACKAGE_PIN V4          [get_ports CKDT_7_P]
set_property PACKAGE_PIN W4          [get_ports CKDT_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_8_P]
set_property PACKAGE_PIN AB7         [get_ports CKDT_8_P]
set_property PACKAGE_PIN AB6         [get_ports CKDT_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_8_N]

##########################CKBC VMM2##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_1_P]
set_property PACKAGE_PIN N18         [get_ports CKBC_1_P]
set_property PACKAGE_PIN N19         [get_ports CKBC_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_2_P]
set_property PACKAGE_PIN N22         [get_ports CKBC_2_P]
set_property PACKAGE_PIN M22         [get_ports CKBC_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_3_P]
set_property PACKAGE_PIN E13         [get_ports CKBC_3_P]
set_property PACKAGE_PIN E14         [get_ports CKBC_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_4_P]
set_property PACKAGE_PIN F19         [get_ports CKBC_4_P]
set_property PACKAGE_PIN F20         [get_ports CKBC_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_5_P]
set_property PACKAGE_PIN K1          [get_ports CKBC_5_P]
set_property PACKAGE_PIN J1          [get_ports CKBC_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_6_P]
set_property PACKAGE_PIN K6          [get_ports CKBC_6_P]
set_property PACKAGE_PIN J6          [get_ports CKBC_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_7_P]
set_property PACKAGE_PIN R3          [get_ports CKBC_7_P]
set_property PACKAGE_PIN R2          [get_ports CKBC_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_8_P]
set_property PACKAGE_PIN T5          [get_ports CKBC_8_P]
set_property PACKAGE_PIN U5          [get_ports CKBC_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_8_N]


##########################CKTP VMM2##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_1_P]
set_property PACKAGE_PIN L16         [get_ports CKTP_1_P]
set_property PACKAGE_PIN K16         [get_ports CKTP_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_2_P]
set_property PACKAGE_PIN F13         [get_ports CKTP_2_P]
set_property PACKAGE_PIN F14         [get_ports CKTP_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_3_P]
set_property PACKAGE_PIN C22         [get_ports CKTP_3_P]
set_property PACKAGE_PIN B22         [get_ports CKTP_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_4_P]
set_property PACKAGE_PIN P2          [get_ports CKTP_4_P]
set_property PACKAGE_PIN N2          [get_ports CKTP_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_5_P]
set_property PACKAGE_PIN H2          [get_ports CKTP_5_P]
set_property PACKAGE_PIN G2          [get_ports CKTP_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_6_P]
set_property PACKAGE_PIN M3          [get_ports CKTP_6_P]
set_property PACKAGE_PIN M2          [get_ports CKTP_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_7_P]
set_property PACKAGE_PIN U3          [get_ports CKTP_7_P]
set_property PACKAGE_PIN V3          [get_ports CKTP_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_8_P]
set_property PACKAGE_PIN R4          [get_ports CKTP_8_P]
set_property PACKAGE_PIN T4          [get_ports CKTP_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_8_N]

##########################CKTK VMM2##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_1_P]
set_property PACKAGE_PIN J19         [get_ports CKTK_1_P]
set_property PACKAGE_PIN H19         [get_ports CKTK_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_2_P]
set_property PACKAGE_PIN G21         [get_ports CKTK_2_P]
set_property PACKAGE_PIN G22         [get_ports CKTK_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_3_P]
set_property PACKAGE_PIN A15         [get_ports CKTK_3_P]
set_property PACKAGE_PIN A16         [get_ports CKTK_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_4_P]
set_property PACKAGE_PIN B20         [get_ports CKTK_4_P]
set_property PACKAGE_PIN A20         [get_ports CKTK_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_5_P]
set_property PACKAGE_PIN C2          [get_ports CKTK_5_P]
set_property PACKAGE_PIN B2          [get_ports CKTK_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_6_P]
set_property PACKAGE_PIN P5          [get_ports CKTK_6_P]
set_property PACKAGE_PIN P4          [get_ports CKTK_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_7_P]
set_property PACKAGE_PIN AB3         [get_ports CKTK_7_P]
set_property PACKAGE_PIN AB2         [get_ports CKTK_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_8_P]
set_property PACKAGE_PIN AA8         [get_ports CKTK_8_P]
set_property PACKAGE_PIN AB8         [get_ports CKTK_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_8_N]

##########################DI##############################

set_property PACKAGE_PIN M13         [get_ports DI_1_P]
set_property PACKAGE_PIN L13         [get_ports DI_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_1_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_1_N]

set_property PACKAGE_PIN L19         [get_ports DI_2_P]
set_property PACKAGE_PIN L20         [get_ports DI_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_2_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_2_N]

set_property PACKAGE_PIN C13         [get_ports DI_3_P]
set_property PACKAGE_PIN B13         [get_ports DI_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_3_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_3_N]

set_property PACKAGE_PIN F18         [get_ports DI_4_P]
set_property PACKAGE_PIN E18         [get_ports DI_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_4_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_4_N]

set_property PACKAGE_PIN H3          [get_ports DI_5_P]
set_property PACKAGE_PIN G3          [get_ports DI_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_5_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_5_N]

set_property PACKAGE_PIN L5          [get_ports DI_6_P]
set_property PACKAGE_PIN L4          [get_ports DI_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_6_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_6_N]

set_property PACKAGE_PIN W9          [get_ports DI_7_P]
set_property PACKAGE_PIN Y9          [get_ports DI_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_7_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_7_N]

set_property PACKAGE_PIN V9          [get_ports DI_8_P]
set_property PACKAGE_PIN V8          [get_ports DI_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_8_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DI_8_N]

##########################DO##############################

set_property PACKAGE_PIN N20         [get_ports DO_1_P]
set_property PACKAGE_PIN M20         [get_ports DO_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_1_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_1_N]
set_property PULLDOWN TRUE           [get_ports DO_1_P]

set_property PACKAGE_PIN F16         [get_ports DO_2_P]
set_property PACKAGE_PIN E17         [get_ports DO_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_2_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_2_N]
set_property PULLDOWN TRUE           [get_ports DO_2_P]

set_property PACKAGE_PIN D14         [get_ports DO_3_P]
set_property PACKAGE_PIN D15         [get_ports DO_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_3_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_3_N]
set_property PULLDOWN TRUE           [get_ports DO_3_P]

set_property PACKAGE_PIN A18         [get_ports DO_4_P]
set_property PACKAGE_PIN A19         [get_ports DO_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_4_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_4_N]
set_property PULLDOWN TRUE           [get_ports DO_4_P]

set_property PACKAGE_PIN K2          [get_ports DO_5_P]
set_property PACKAGE_PIN J2          [get_ports DO_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_5_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_5_N]
set_property PULLDOWN TRUE           [get_ports DO_5_P]

set_property PACKAGE_PIN N4          [get_ports DO_6_P]
set_property PACKAGE_PIN N3          [get_ports DO_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_6_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_6_N]
set_property PULLDOWN TRUE           [get_ports DO_6_P]

set_property PACKAGE_PIN W1          [get_ports DO_7_P]
set_property PACKAGE_PIN Y1          [get_ports DO_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_7_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_7_N]
set_property PULLDOWN TRUE           [get_ports DO_7_P]

set_property PACKAGE_PIN R6          [get_ports DO_8_P]
set_property PACKAGE_PIN T6          [get_ports DO_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_8_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DO_8_N]
set_property PULLDOWN TRUE           [get_ports DO_8_P]

##########################ENA VMM2##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_1_P]
set_property PACKAGE_PIN M18         [get_ports ENA_1_P]
set_property PACKAGE_PIN L18         [get_ports ENA_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_2_P]
set_property PACKAGE_PIN K18         [get_ports ENA_2_P]
set_property PACKAGE_PIN K19         [get_ports ENA_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_3_P]
set_property PACKAGE_PIN A13         [get_ports ENA_3_P]
set_property PACKAGE_PIN A14         [get_ports ENA_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_4_P]
set_property PACKAGE_PIN E19         [get_ports ENA_4_P]
set_property PACKAGE_PIN D19         [get_ports ENA_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_5_P]
set_property PACKAGE_PIN G1          [get_ports ENA_5_P]
set_property PACKAGE_PIN F1          [get_ports ENA_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_6_P]
set_property PACKAGE_PIN K4          [get_ports ENA_6_P]
set_property PACKAGE_PIN J4          [get_ports ENA_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_7_P]
set_property PACKAGE_PIN AA5         [get_ports ENA_7_P]
set_property PACKAGE_PIN AB5         [get_ports ENA_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_8_P]
set_property PACKAGE_PIN V7          [get_ports ENA_8_P]
set_property PACKAGE_PIN W7          [get_ports ENA_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_8_N]

##########################WEN VMM2##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_1_P]
set_property PACKAGE_PIN M15         [get_ports WEN_1_P]
set_property PACKAGE_PIN M16         [get_ports WEN_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_2_P]
set_property PACKAGE_PIN E22         [get_ports WEN_2_P]
set_property PACKAGE_PIN D22         [get_ports WEN_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_3_P]
set_property PACKAGE_PIN E16         [get_ports WEN_3_P]
set_property PACKAGE_PIN D16         [get_ports WEN_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_4_P]
set_property PACKAGE_PIN P6          [get_ports WEN_4_P]
set_property PACKAGE_PIN N5          [get_ports WEN_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_5_P]
set_property PACKAGE_PIN J5          [get_ports WEN_5_P]
set_property PACKAGE_PIN H5          [get_ports WEN_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_6_P]
set_property PACKAGE_PIN R1          [get_ports WEN_6_P]
set_property PACKAGE_PIN P1          [get_ports WEN_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_7_P]
set_property PACKAGE_PIN Y3          [get_ports WEN_7_P]
set_property PACKAGE_PIN AA3         [get_ports WEN_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_8_P]
set_property PACKAGE_PIN U6          [get_ports WEN_8_P]
set_property PACKAGE_PIN V5          [get_ports WEN_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports WEN_8_N]

##########################SETT/SETB/TKI/TKO VMM2#####################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports SETT_P]
set_property PACKAGE_PIN AA15        [get_ports SETT_P]
set_property PACKAGE_PIN AB15        [get_ports SETT_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports SETT_N]
#set_property PULLDOWN TRUE           [get_ports SETT_P]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports SETB_P]
set_property PACKAGE_PIN AB16        [get_ports SETB_P]
set_property PACKAGE_PIN AB17        [get_ports SETB_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports SETB_N]
#set_property PULLDOWN TRUE           [get_ports SETB_P]

set_property PACKAGE_PIN AA13        [get_ports TKI_P]
set_property PACKAGE_PIN AB13        [get_ports TKI_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports TKI_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports TKI_N]
#set_property PULLDOWN TRUE           [get_ports TKI_P]

set_property PACKAGE_PIN Y16         [get_ports TKO_P]
set_property PACKAGE_PIN AA16        [get_ports TKO_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports TKO_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports TKO_N]
#set_property PULLDOWN TRUE           [get_ports TKO_P]

##########################CKART VMM2##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_1_P]
set_property PACKAGE_PIN L14         [get_ports CKART_1_P]
set_property PACKAGE_PIN L15         [get_ports CKART_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_2_P]
set_property PACKAGE_PIN E21         [get_ports CKART_2_P]
set_property PACKAGE_PIN D21         [get_ports CKART_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_2_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_3_P]
set_property PACKAGE_PIN D17         [get_ports CKART_3_P]
set_property PACKAGE_PIN C17         [get_ports CKART_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_3_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_4_P]
set_property PACKAGE_PIN M6          [get_ports CKART_4_P]
set_property PACKAGE_PIN M5          [get_ports CKART_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_4_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_5_P]
set_property PACKAGE_PIN H4          [get_ports CKART_5_P]
set_property PACKAGE_PIN G4          [get_ports CKART_5_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_5_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_6_P]
set_property PACKAGE_PIN T1          [get_ports CKART_6_P]
set_property PACKAGE_PIN U1          [get_ports CKART_6_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_6_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_7_P]
set_property PACKAGE_PIN AA1         [get_ports CKART_7_P]
set_property PACKAGE_PIN AB1         [get_ports CKART_7_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_7_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_8_P]
set_property PACKAGE_PIN W6          [get_ports CKART_8_P]
set_property PACKAGE_PIN W5          [get_ports CKART_8_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_8_N]

##########################CKART ADDC##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_ADDC_P]
set_property PACKAGE_PIN V10         [get_ports CKART_ADDC_P]
set_property PACKAGE_PIN W10         [get_ports CKART_ADDC_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_ADDC_N]

###########################XADC MMFE8#############################
# Dedicated Analog Inputs
set_property IOSTANDARD LVCMOS25     [get_ports VP_0]
set_property PACKAGE_PIN L10         [get_ports VP_0]
set_property PACKAGE_PIN M9          [get_ports VN_0]
set_property IOSTANDARD LVCMOS25     [get_ports VN_0]

## Analog Multiplexer Pins
set_property PACKAGE_PIN T20     [get_ports MuxAddr0]
set_property IOSTANDARD LVCMOS25 [get_ports MuxAddr0]
set_property PACKAGE_PIN P14     [get_ports MuxAddr1]
set_property IOSTANDARD LVCMOS25 [get_ports MuxAddr1]
set_property PACKAGE_PIN R14     [get_ports MuxAddr2]
set_property IOSTANDARD LVCMOS25 [get_ports MuxAddr2]
set_property PACKAGE_PIN R18     [get_ports MuxAddr3_p]
set_property IOSTANDARD LVDS_25  [get_ports MuxAddr3_p]
set_property PACKAGE_PIN T18     [get_ports MuxAddr3_n]
set_property IOSTANDARD LVDS_25  [get_ports MuxAddr3_n]


set_property PACKAGE_PIN H13 [get_ports Vaux0_v_p]
set_property PACKAGE_PIN G13 [get_ports Vaux0_v_n]
set_property PACKAGE_PIN J14 [get_ports Vaux1_v_p]
set_property PACKAGE_PIN H14 [get_ports Vaux1_v_n]
set_property PACKAGE_PIN J22 [get_ports Vaux2_v_p]
set_property PACKAGE_PIN H22 [get_ports Vaux2_v_n]
set_property PACKAGE_PIN K21 [get_ports Vaux3_v_p]
set_property PACKAGE_PIN K22 [get_ports Vaux3_v_n]
set_property PACKAGE_PIN G15 [get_ports Vaux8_v_p]
set_property PACKAGE_PIN G16 [get_ports Vaux8_v_n]
set_property PACKAGE_PIN J15 [get_ports Vaux9_v_p]
set_property PACKAGE_PIN H15 [get_ports Vaux9_v_n]
set_property PACKAGE_PIN H20 [get_ports Vaux10_v_p]
set_property PACKAGE_PIN G20 [get_ports Vaux10_v_n]
set_property PACKAGE_PIN M21 [get_ports Vaux11_v_p]
set_property PACKAGE_PIN L21 [get_ports Vaux11_v_n]

set_property IOSTANDARD LVCMOS12 [get_ports Vaux0_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux0_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux1_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux1_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux2_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux2_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux3_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux3_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux8_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux8_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux9_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux9_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux10_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux10_v_p]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux11_v_n]
set_property IOSTANDARD LVCMOS12 [get_ports Vaux11_v_p]

######################### SPI FLASH ##########################
#set_property IOSTANDARD LVCMOS25 [get_ports SPI_CLK]
set_property IOSTANDARD LVCMOS25 [get_ports IO0_IO]
set_property IOSTANDARD LVCMOS25 [get_ports IO1_IO]
set_property IOSTANDARD LVCMOS25 [get_ports SS_IO]
#set_property PACKAGE_PIN V22 [get_ports SPI_CLK]
set_property PACKAGE_PIN P22 [get_ports IO0_IO]
set_property PACKAGE_PIN R22 [get_ports IO1_IO]
set_property PACKAGE_PIN T19 [get_ports SS_IO]
#set_property OFFCHIP_TERM NONE [get_ports SPI_CLK]
set_property OFFCHIP_TERM NONE [get_ports IO0_IO]
set_property OFFCHIP_TERM NONE [get_ports IO1_IO]
set_property OFFCHIP_TERM NONE [get_ports SS_IO]

################# GENERAL CONSTRAINTS ########################
set_property CONFIG_MODE SPIx1 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

#######################DEBUGGING##############################
