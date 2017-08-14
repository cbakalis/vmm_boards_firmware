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
create_generated_clock -name roClkCont -source [get_pins mmcm_master/inst/mmcm_adv_inst/CLKOUT3] -divide_by 2 [get_pins readout_vmm/continuousReadoutMode.readout_vmm_cont/vmm_ckdt_i_reg/Q]

# CKBC generated clock
create_generated_clock -name ckbc_clk -source [get_pins mmcm_master/inst/mmcm_adv_inst/CLKOUT0] -divide_by 4 [get_pins ckbc_cktp_generator/ckbc_generator/ckbc_out_reg/Q]

# ODDR/CKDT
create_generated_clock -name ckdt_1 -source [get_pins vmm_oddr_inst/ODDR_CKDT_1/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKDT_1/Q]
create_generated_clock -name ckdt_2 -source [get_pins vmm_oddr_inst/ODDR_CKDT_2/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKDT_2/Q]
create_generated_clock -name ckdt_3 -source [get_pins vmm_oddr_inst/ODDR_CKDT_3/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKDT_3/Q]
create_generated_clock -name ckdt_4 -source [get_pins vmm_oddr_inst/ODDR_CKDT_4/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKDT_4/Q]
create_generated_clock -name ckdt_5 -source [get_pins vmm_oddr_inst/ODDR_CKDT_5/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKDT_5/Q]
create_generated_clock -name ckdt_6 -source [get_pins vmm_oddr_inst/ODDR_CKDT_6/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKDT_6/Q]
create_generated_clock -name ckdt_7 -source [get_pins vmm_oddr_inst/ODDR_CKDT_7/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKDT_7/Q]
create_generated_clock -name ckdt_8 -source [get_pins vmm_oddr_inst/ODDR_CKDT_8/C] -divide_by 1 [get_pins vmm_oddr_inst/ODDR_CKDT_8/Q]

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
# Exclusive clock group between the two possible CKDTs
#set_clock_groups -name exclusive_clk0_clk1 -physically_exclusive -group roClkCont -group [get_pins mmcm_master/inst/mmcm_adv_inst/CLKOUT2]

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

#set_input_delay 1.0 -clock [get_clocks -of_objects [get_pins clk_user_inst/inst/mmcm_adv_inst/CLKOUT0]] [get_ports CH_TRIGGER]
#mmcm_master/inst/mmcm_adv_inst/CLKOUT1
#============================= Primary Clocks =========================
#======================================================================

#======================= TIMING EXCEPTIONS SECTION ====================
#=============================== False Paths ==========================
set_false_path -from [get_ports LEMO_TRIGGER]

# Global reset false path
set_false_path -reset_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_rst_reg]
set_false_path -reset_path -from [get_cells i2c_module/phy_resetn_reg]

# ART readout
set_false_path -from [get_cells art_instance/vmmArtData_reg[*]] -to [get_cells art_instance/vmmArtData160_125_reg[*]]
set_false_path -from [get_cells art_instance/vmmArtReady160_reg] -to [get_cells art_instance/vmmArtReady160_125_reg]
set_false_path -from [get_cells tr_hold_ext_s_reg] -to [get_cells art_instance/tr_hold125_160_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells art_instance/tr_hold125_160_reg]
set_false_path -from [get_cells packet_formation_instance/tr_hold_reg] -to [get_cells art_instance/tr_hold125_160_reg]
set_false_path -from [get_cells art_instance/art2triggerCnt_reg[*]] -to [get_cells art_instance/art2trigger160_125_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/artTimeout_i_reg[*]] -to [get_cells art_instance/artTimeout125_160_reg[*]]

# FPGA configuration registers false paths
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/ckbc_freq_i_reg[*]] -to [get_cells ckbc_cktp_generator/ckbc_generator/ckbc_out_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/ckbc_freq_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/ckbc_freq_i_reg[*]] -to [get_cells ckbc_cktp_generator/ckbc_generator/count_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/ckbc_freq_i_reg[*]] -to [get_cells ckbc_cktp_generator/ckbc_generator/count_ro_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/ckbc_freq_i_reg[*]] -to [get_cells ckbc_cktp_generator/ckbc_generator/ckbc_ro_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/ckbc_freq_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_start_aligned_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktp_skew_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ckbcMode_reg] -to [get_pins ckbc_cktp_generator/CKBC_BUFGMUX/CE0]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktp_skew_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_cnt_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/ckbc_freq_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/align_cnt_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktk_max_num_i_reg[*]] -to [get_cells readout_vmm/continuousReadoutMode.readout_vmm_cont/cktk_max_i_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktp_width_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktp_width_i_reg[*]] -to [get_cells trigger_instance/cktp_trint_module/state_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktp_period_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktp_width_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_cnt_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktp_period_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_cnt_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/ckbc_freq_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_cnt_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/ckbc_freq_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_cnt_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/latency_extra_i_reg[*]] -to [get_cells trigger_instance/generate_2ckbc.trigLatencyCnt_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/latency_i_reg[*]]       -to [get_cells trigger_instance/generate_2ckbc.trigLatencyCnt_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/latency_i_reg[*]]       -to [get_cells trigger_instance/FSM_onehot_generate_2ckbc.state_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/latency_extra_i_reg[*]] -to [get_cells trigger_instance/FSM_onehot_generate_2ckbc.state_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktp_max_num_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_max_module/inhibit_async_i_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktp_max_num_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_max_module/cktp_cnt_state_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/ckbc_freq_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_start_aligned_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktp_max_num_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_max_module/cktp_inhibit_fsm_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/ckbc_max_num_i_reg[*]] -to [get_cells ckbc_cktp_generator/ckbc_generator/state_cnt_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/ckbc_max_num_i_reg[*]] -to [get_cells ckbc_cktp_generator/ckbc_generator/ckbc_inhibit_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktp_width_i_reg[*]] -to [get_cells trigger_instance/cktp_trint_module/cktp_start_s_0_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ckbcMode_reg] -to [get_cells ckbc_cktp_generator/ckbc_generator/readout_mode_i_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/cktp_max_num_i_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_max_module/fsm_enable_i_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ckbcMode_reg] -to [get_cells trigger_instance/ckbcMode_stage1_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ckbcMode_reg] -to [get_cells ckbc_cktp_generator/cktp_generator/ckbc_mode_i_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/latency_i_reg[*]] -to [get_cells trigger_instance/generate_level0.trigLatencyCnt_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/latency_i_reg[*]] -to [get_cells trigger_instance/generate_level0.accept_wr_i_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/fpga_conf_router_inst/latency_i_reg[*]] -to [get_cells trigger_instance/generate_level0.state_l0_reg[*]]

# CKTP/CKBC enabling false path
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_start_i_reg]
set_false_path -from [get_cells rstFIFO_flow_reg]      -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_primary_i_reg]
#set_false_path -from [get_cells ckbc_enable_reg]      -to [get_cells ckbc_cktp_generator/ckbc_generator/ready_i_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells ckbc_cktp_generator/cktp_max_module/inhibit_async_i_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells ckbc_cktp_generator/cktp_max_module/fsm_enable_i_reg]
set_false_path -from [get_cells FSM_sequential_state_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_max_module/inhibit_async_i_reg]
set_false_path -from [get_cells FSM_sequential_state_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_generator/cktp_start_i_reg]
set_false_path -from [get_cells FSM_sequential_state_reg[*]] -to [get_cells ckbc_cktp_generator/cktp_max_module/fsm_enable_i_reg]
set_false_path -from [get_cells FSM_sequential_state_reg[*]] -to [get_cells trigger_instance/cktp_trint_module/cktp_start_s_0_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells trigger_instance/cktp_trint_module/cktp_start_s_0_reg]
#set_false_path -from [get_cells ckbc_cktp_generator/cktp_trint_module/trint_i_reg] -to [get_cells ckbc_cktp_generator/cktp_trint_module/trint_s_0_reg]

# Trigger related false paths
set_false_path -from [get_cells trigger_instance/tr_out_i_reg] -to [get_cells trigger_instance/tr_out_i_stage1_reg]
set_false_path -from [get_cells trigger_instance/generate_2ckbc.trigger_pf_i_reg] -to [get_cells trigger_instance/trigger_pf_i_stage1_reg]
set_false_path -from [get_cells trigger_instance/cktp_trint_module/trint_i_reg] -to [get_cells trigger_instance/trint_stage_synced125_reg]
set_false_path -from [get_cells trigger_instance/tren_buff_reg] -to [get_cells trigger_instance/tren_buff_stage1_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells trigger_instance/trext_stage1_reg]
set_false_path -from [get_cells udp_din_conf_block/fpga_config_logic/ext_trigger_reg] -to [get_cells trigger_instance/trmode_stage1_reg]
set_false_path -from [get_cells trigger_instance/mode_reg] -to [get_cells trigger_instance/mode_stage1_reg]
set_false_path -from [get_cells trigger_instance/trext_ff_synced_reg] -to [get_cells trigger_instance/trext_stage_resynced_reg]
#set_false_path -from [get_cells ckbc_cktp_generator/cktp_trint_module/trint_s_reg] -to [get_cells trigger_instance/trint_stage1_reg]

# AXI SPI related false paths
set_false_path -from [get_cells axi4_spi_instance/CDCC_50to125/data_in_reg_reg[*]] -to [get_cells axi4_spi_instance/CDCC_50to125/data_sync_stage_0_reg[*]]
set_false_path -from [get_cells axi4_spi_instance/CDCC_125to50/data_in_reg_reg[*]] -to [get_cells axi4_spi_instance/CDCC_125to50/data_sync_stage_0_reg[*]]

# UDP configuration related false paths
set_false_path -from [get_cells udp_din_conf_block/CDCC_40to125/data_in_reg_reg[*]] -to [get_cells udp_din_conf_block/CDCC_40to125/data_sync_stage_0_reg[*]]
set_false_path -from [get_cells udp_din_conf_block/CDCC_125to40/data_in_reg_reg[*]] -to [get_cells udp_din_conf_block/CDCC_125to40/data_sync_stage_0_reg[*]]

# MMCM related false paths
#set_false_path -from [get_cells clk_400_low_jitter_inst/inst/seq_reg1_reg[*]] -to [get_cells clk_400_low_jitter_inst/inst/clkout1_buf]

# Continuous Readout related false paths
#125
set_false_path -from [get_cells readout_vmm/continuousReadoutMode.readout_vmm_cont/vmmEventDone_i_reg] -to [get_cells readout_vmm/continuousReadoutMode.readout_vmm_cont/vmmEventDone_i_125_reg]
set_false_path -from [get_cells readout_vmm/continuousReadoutMode.readout_vmm_cont/reading_out_word_reg] -to [get_cells readout_vmm/continuousReadoutMode.readout_vmm_cont/reading_out_word_i_125_reg]

#50
set_false_path -from [get_cells daq_enable_i_reg] -to [get_cells readout_vmm/continuousReadoutMode.readout_vmm_cont/daq_enable_stage1_Dt_reg]
set_false_path -from [get_cells readout_vmm/continuousReadoutMode.readout_vmm_cont/cktkSent_reg] -to [get_cells readout_vmm/continuousReadoutMode.readout_vmm_cont/cktkSent_stage1_reg]

#40
set_false_path -from [get_cells packet_formation_instance/triggerVmmReadout_i_reg] -to [get_cells readout_vmm/continuousReadoutMode.readout_vmm_cont/trigger_pulse_stage1_reg]
set_false_path -from [get_cells daq_enable_i_reg] -to [get_cells readout_vmm/continuousReadoutMode.readout_vmm_cont/daq_enable_stage1_reg]
set_false_path -from [get_cells readout_vmm/continuousReadoutMode.readout_vmm_cont/reading_out_word_reg] -to [get_cells readout_vmm/continuousReadoutMode.readout_vmm_cont/reading_out_word_stage1_reg]

# Level-0 Readout related false paths
set_false_path -from [get_cells readout_vmm/level0_readout_case.readout_vmm_l0/readout_instances[*].l0_buf_wr_inst/inhibit_write_reg] -to [get_cells readout_vmm/level0_readout_case.readout_vmm_l0/readout_instances[*].l0_buf_wr_inst/inhib_wr_i_reg]
set_false_path -from [get_cells readout_vmm/level0_readout_case.readout_vmm_l0/readout_instances[*].des_dec_inst/commas_true_reg] -to [get_cells readout_vmm/level0_readout_case.readout_vmm_l0/readout_instances[*].l0_buf_wr_inst/commas_true_i_reg]
set_false_path -from [get_cells trigger_instance/generate_level0.accept_wr_i_reg] -to [get_cells trigger_instance/accept_wr_i_stage1_reg]
set_false_path -from [get_cells packet_formation_instance/pfBusy_i_reg] -to [get_cells trigger_instance/pfBusy_stage1_reg]
set_false_path -from [get_cells readout_vmm/level0_readout_case.readout_vmm_l0/readout_instances[*].des_dec_inst/commas_true_reg] -to [get_cells readout_vmm/level0_readout_case.readout_vmm_l0/commas_true_s0_reg[*]]

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
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ART_1_P]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ART_1_N]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {CLK_40_IBUF}]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets art_in_i]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ART_1_P]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ART_1_N]
#======================================================================

#====================== PHYSICAL CONSTRAINTS SECTION ==================
#====================== ASYNC_REG for synchronizers ===================
#Obsolete. Moved to respective .vhd files
#set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_50to125/data_sync_stage_0_reg[*]]
#set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_50to125/data_out_s_int_reg[*]]

#set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_125to50/data_sync_stage_0_reg[*]]
#set_property ASYNC_REG true [get_cells axi4_spi_instance/CDCC_125to50/data_out_s_int_reg[*]]

#set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_125to40/data_sync_stage_0_reg[*]]
#set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_125to40/data_out_s_int_reg[*]]

#set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_40to125/data_sync_stage_0_reg[*]]
#set_property ASYNC_REG true [get_cells udp_din_conf_block/CDCC_40to125/data_out_s_int_reg[*]]

#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/vmmEventDone_stage1_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/vmmEventDone_ff_sync_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/vmmWordReady_stage1_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/vmmWordReady_ff_sync_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/vmmWord_stage1_reg[*]]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/vmmWord_ff_sync_reg[*]]

#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/daq_enable_stage1_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/daq_enable_ff_sync_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/daq_enable_stage1_Dt_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/daq_enable_ff_sync_Dt_reg]

#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/trigger_pulse_stage1_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/trigger_pulse_ff_sync_reg]
        
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/cktk_max_i_reg[*]]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/cktk_max_sync_reg[*]]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/reading_out_word_stage1_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/reading_out_word_ff_sync_reg]

#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/vmm_data0_stage1_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/vmm_data0_ff_sync_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/vmm_data1_stage1_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/vmm_data1_ff_sync_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/cktkSent_stage1_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/cktkSent_ff_sync_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/vmmEventDone_i_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/vmmEventDone_stage1_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/daq_enable_stage1_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/driverBusy_stage1_reg]
#set_property ASYNC_REG true [get_cells readout_vmm/readout_vmm_cont/driverBusy_ff_sync_reg]

#set_property ASYNC_REG true [get_cells trigger_instance/tr_out_i_stage1_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/tr_out_i_ff_synced_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/trext_stage_resynced_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/trext_ff_resynced_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/trext_stage1_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/trext_ff_synced_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/tren_buff_stage1_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/tren_buff_ff_synced_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/mode_stage1_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/mode_ff_synced_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/trmode_stage1_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/trmode_ff_synced_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/trint_stage1_reg]
#set_property ASYNC_REG true [get_cells trigger_instance/trint_ff_synced_reg]

#set_property ASYNC_REG true [get_cells udp_din_conf_block/fpga_config_logic/daq_on_i_reg]
#set_property ASYNC_REG true [get_cells udp_din_conf_block/fpga_config_logic/daq_on_sync_reg]
#set_property ASYNC_REG true [get_cells udp_din_conf_block/fpga_config_logic/ext_trg_i_reg]
#set_property ASYNC_REG true [get_cells udp_din_conf_block/fpga_config_logic/ext_trg_sync_reg]
#=====================================================================

#======================= Configurable CKBC/CKTP Constraints ==========

# CKBC global buffer placement constraint
set_property LOC BUFGCTRL_X0Y0 [get_cells ckbc_cktp_generator/CKBC_BUFGMUX]

# CKTP global buffer placement constraint
set_property LOC BUFGCTRL_X0Y3 [get_cells ckbc_cktp_generator/CKTP_BUFGMUX]

#ASYNC_REG to skewing pipeline
#set_property ASYNC_REG true [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]
set_property ASYNC_REG true [get_cells ckbc_cktp_generator/skewing_module/cktp_02_reg]

#False paths for skewing pipeline (Caution!! Those lines might not be needed. It should be validated with an oscilloscope) 
set_false_path -from [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg] -to [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]
set_false_path -from [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg] -to [get_cells ckbc_cktp_generator/skewing_module/cktp_02_reg]
#set_false_path -from [get_cells ckbc_cktp_generator/skewing_module/cktp_02_reg] -to [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]

# Added to disable timing to known artifact of phase skewing 
set arcs [get_timing_arcs -of_objects \
[get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]]
set_disable_timing $arcs
#============================================================================================