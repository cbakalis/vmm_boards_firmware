#----------------------------------------------------------------------
#----------------------------------------------------------------------
#================================ GPVMM ===============================
#----------------------------------------------------------------------
#----------------------------------------------------------------------

# Data Lines input delays
#-----------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------
set_input_delay -clock [get_clocks ckdt_1] -min 0.200 [get_ports DATA0_1_P]
set_input_delay -clock [get_clocks ckdt_1] -max 0.400 [get_ports DATA0_1_N]
set_input_delay -clock [get_clocks ckdt_1] -min 0.200 [get_ports DATA1_1_P]
set_input_delay -clock [get_clocks ckdt_1] -max 0.400 [get_ports DATA1_1_N]
#-----------------------------------------------------------------------------------------------------------------------------

#-------------------------------------- CKTK/L0 delay ------------------------------------------------------------------------
set_output_delay -clock [get_clocks ckbc_1] 0.300 [get_ports CKTK_1_P]
set_output_delay -clock [get_clocks ckbc_1] 0.300 [get_ports CKTK_1_N]
#-----------------------------------------------------------------------------------------------------------------------------

#------------------- CKBC/CKTP placement constraints  ------------------------------------------------------------------------
# register-to-CKBC buffer placement constraint
# xc7a100tfgg484
set_property LOC SLICE_X51Y95 [get_cells ckbc_cktp_generator/ckbc_generator/ckbc_out_reg]

# register-to-CKTP buffer placement constraint
# xc7a100tfgg484
set_property LOC SLICE_X51Y96 [get_cells ckbc_cktp_generator/cktp_generator/vmm_cktp_reg]
set_property LOC SLICE_X51Y97 [get_cells ckbc_cktp_generator/skewing_module/CKTP_skewed_reg]

# critical register of cktp generator placement constraint
# xc7a100tfgg484
set_property LOC SLICE_X52Y96 [get_cells ckbc_cktp_generator/cktp_generator/start_align_cnt_reg]
#-----------------------------------------------------------------------------------------------------------------------------

#====================== I/O Placement - IOSTANDARDS ===================

############################# GPVMM #############################
set_property PACKAGE_PIN V4 [get_ports X_2V5_DIFF_CLK_P]
set_property PACKAGE_PIN W4 [get_ports X_2V5_DIFF_CLK_N]
set_property IOSTANDARD LVDS_25 [get_ports X_2V5_DIFF_CLK_P]
set_property IOSTANDARD LVDS_25 [get_ports X_2V5_DIFF_CLK_N]

############################# Ethernet #############################
set_property PACKAGE_PIN F6 [get_ports gtrefclk_p]
set_property PACKAGE_PIN E6 [get_ports gtrefclk_n]
set_property PACKAGE_PIN A8 [get_ports rxn]
set_property PACKAGE_PIN B8 [get_ports rxp]
set_property PACKAGE_PIN A4 [get_ports txn]
set_property PACKAGE_PIN B4 [get_ports txp]
set_property PACKAGE_PIN AA8 [get_ports phy_int]
set_property IOSTANDARD LVCMOS25 [get_ports phy_int]
set_property PACKAGE_PIN AB8 [get_ports phy_rstn_out]
set_property IOSTANDARD LVCMOS25 [get_ports phy_rstn_out]

######################### Trigger GPVMM #############################
set_property PACKAGE_PIN V18 [get_ports CH_TRIGGER]
set_property IOSTANDARD LVCMOS33 [get_ports CH_TRIGGER]

set_property PACKAGE_PIN W21 [get_ports TRIGGER_OUT_P]
set_property PACKAGE_PIN W22 [get_ports TRIGGER_OUT_N]
set_property IOSTANDARD LVCMOS33 [get_ports TRIGGER_OUT_P]
set_property IOSTANDARD LVCMOS33 [get_ports TRIGGER_OUT_N]

############################ MO GPVMM #########################
set_property PACKAGE_PIN H13 [get_ports MO]
set_property IOSTANDARD LVCMOS12 [get_ports MO]
set_property PULLDOWN true [get_ports MO]

########################## ART VMM3 GPVMM ############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ART_1_P]
set_property PACKAGE_PIN A18 [get_ports ART_1_P]
set_property PACKAGE_PIN A19 [get_ports ART_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ART_1_N]

#set_property IOSTANDARD DIFF_HSUL_12 [get_ports ART_2_P]
#set_property PACKAGE_PIN H17         [get_ports ART_2_P]
#set_property PACKAGE_PIN H18         [get_ports ART_2_N]
#set_property IOSTANDARD DIFF_HSUL_12 [get_ports ART_2_N]
#set_property PULLDOWN TRUE           [get_ports ART_2_P]

#set_property IOSTANDARD TMDS_33      [get_ports ART_3_P]
#set_property PACKAGE_PIN P19         [get_ports ART_3_P]
#set_property PACKAGE_PIN R19         [get_ports ART_3_N]
#set_property IOSTANDARD TMDS_33      [get_ports ART_3_N]
#set_property PULLDOWN TRUE           [get_ports ART_3_P]

#set_property IOSTANDARD DIFF_HSUL_12 [get_ports ART_4_P]
#set_property PACKAGE_PIN D20         [get_ports ART_4_P]
#set_property PACKAGE_PIN C20         [get_ports ART_4_N]
#set_property IOSTANDARD DIFF_HSUL_12 [get_ports ART_4_N]
#set_property PULLDOWN TRUE           [get_ports ART_4_P]

#set_property IOSTANDARD LVDS_25      [get_ports ART_5_P]
#set_property PACKAGE_PIN E2          [get_ports ART_5_P]
#set_property PACKAGE_PIN D2          [get_ports ART_5_N]
#set_property IOSTANDARD LVDS_25      [get_ports ART_5_N]
#set_property PULLDOWN TRUE           [get_ports ART_5_P]

#set_property IOSTANDARD LVDS_25      [get_ports ART_6_P]
#set_property PACKAGE_PIN L3          [get_ports ART_6_P]
#set_property PACKAGE_PIN K3          [get_ports ART_6_N]
#set_property IOSTANDARD LVDS_25      [get_ports ART_6_N]
#set_property PULLDOWN TRUE           [get_ports ART_6_P]

#set_property IOSTANDARD LVDS_25      [get_ports ART_7_P]
#set_property PACKAGE_PIN W2          [get_ports ART_7_P]
#set_property PACKAGE_PIN Y2          [get_ports ART_7_N]
#set_property IOSTANDARD LVDS_25      [get_ports ART_7_N]
#set_property PULLDOWN TRUE           [get_ports ART_7_P]

#set_property IOSTANDARD LVDS_25      [get_ports ART_8_P]
#set_property PACKAGE_PIN Y8          [get_ports ART_8_P]
#set_property PACKAGE_PIN Y7          [get_ports ART_8_N]
#set_property IOSTANDARD LVDS_25      [get_ports ART_8_N]
#set_property PULLDOWN TRUE           [get_ports ART_8_P]

set_property PACKAGE_PIN A15 [get_ports ART_OUT_P]
set_property PACKAGE_PIN A16 [get_ports ART_OUT_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ART_OUT_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ART_OUT_N]
set_property PULLDOWN true [get_ports ART_OUT_P]

######################### DATA0 VMM3 #############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_1_P]
set_property PACKAGE_PIN B15 [get_ports DATA0_1_P]
set_property PACKAGE_PIN B16 [get_ports DATA0_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA0_1_N]

set_property IOSTANDARD TMDS_33 [get_ports DATA0_2_P]
set_property PACKAGE_PIN T21 [get_ports DATA0_2_P]
set_property PACKAGE_PIN U21 [get_ports DATA0_2_N]
set_property IOSTANDARD TMDS_33 [get_ports DATA0_2_N]
set_property PULLDOWN true [get_ports DATA0_2_P]

set_property IOSTANDARD TMDS_33 [get_ports DATA0_3_P]
set_property PACKAGE_PIN AA20 [get_ports DATA0_3_P]
set_property PACKAGE_PIN AA21 [get_ports DATA0_3_N]
set_property IOSTANDARD TMDS_33 [get_ports DATA0_3_N]
set_property PULLDOWN true [get_ports DATA0_3_P]

set_property IOSTANDARD TMDS_33 [get_ports DATA0_4_P]
set_property PACKAGE_PIN Y21 [get_ports DATA0_4_P]
set_property PACKAGE_PIN Y22 [get_ports DATA0_4_N]
set_property IOSTANDARD TMDS_33 [get_ports DATA0_4_N]
set_property PULLDOWN true [get_ports DATA0_4_P]

set_property IOSTANDARD LVDS_25 [get_ports DATA0_5_P]
set_property PACKAGE_PIN E1 [get_ports DATA0_5_P]
set_property PACKAGE_PIN D1 [get_ports DATA0_5_N]
set_property IOSTANDARD LVDS_25 [get_ports DATA0_5_N]
set_property PULLDOWN true [get_ports DATA0_5_P]

set_property IOSTANDARD LVDS_25 [get_ports DATA0_6_P]
set_property PACKAGE_PIN M1 [get_ports DATA0_6_P]
set_property PACKAGE_PIN L1 [get_ports DATA0_6_N]
set_property IOSTANDARD LVDS_25 [get_ports DATA0_6_N]
set_property PULLDOWN true [get_ports DATA0_6_P]

set_property IOSTANDARD TMDS_33 [get_ports DATA0_7_P]
set_property PACKAGE_PIN Y4 [get_ports DATA0_7_P]
set_property PACKAGE_PIN AA4 [get_ports DATA0_7_N]
set_property IOSTANDARD TMDS_33 [get_ports DATA0_7_N]
set_property PULLDOWN true [get_ports DATA0_7_P]

set_property IOSTANDARD LVDS_25 [get_ports DATA0_8_P]
set_property PACKAGE_PIN Y6 [get_ports DATA0_8_P]
set_property PACKAGE_PIN AA6 [get_ports DATA0_8_N]
set_property IOSTANDARD LVDS_25 [get_ports DATA0_8_N]
set_property PULLDOWN true [get_ports DATA0_8_P]

######################### DATA1 VMM3 #############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_1_P]
set_property PACKAGE_PIN C14 [get_ports DATA1_1_P]
set_property PACKAGE_PIN C15 [get_ports DATA1_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_2_P]
set_property PACKAGE_PIN H17 [get_ports DATA1_2_P]
set_property PACKAGE_PIN H18 [get_ports DATA1_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_2_N]
set_property PULLDOWN true [get_ports DATA1_2_P]

set_property IOSTANDARD TMDS_33 [get_ports DATA1_3_P]
set_property PACKAGE_PIN P19 [get_ports DATA1_3_P]
set_property PACKAGE_PIN R19 [get_ports DATA1_3_N]
set_property IOSTANDARD TMDS_33 [get_ports DATA1_3_N]
set_property PULLDOWN true [get_ports DATA1_3_P]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_4_P]
set_property PACKAGE_PIN D20 [get_ports DATA1_4_P]
set_property PACKAGE_PIN C20 [get_ports DATA1_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports DATA1_4_N]
set_property PULLDOWN true [get_ports DATA1_4_P]

set_property IOSTANDARD LVDS_25 [get_ports DATA1_5_P]
set_property PACKAGE_PIN E2 [get_ports DATA1_5_P]
set_property PACKAGE_PIN D2 [get_ports DATA1_5_N]
set_property IOSTANDARD LVDS_25 [get_ports DATA1_5_N]
set_property PULLDOWN true [get_ports DATA1_5_P]

set_property IOSTANDARD LVDS_25 [get_ports DATA1_6_P]
set_property PACKAGE_PIN L3 [get_ports DATA1_6_P]
set_property PACKAGE_PIN K3 [get_ports DATA1_6_N]
set_property IOSTANDARD LVDS_25 [get_ports DATA1_6_N]
set_property PULLDOWN true [get_ports DATA1_6_P]

set_property IOSTANDARD LVDS_25 [get_ports DATA1_7_P]
set_property PACKAGE_PIN W2 [get_ports DATA1_7_P]
set_property PACKAGE_PIN Y2 [get_ports DATA1_7_N]
set_property IOSTANDARD LVDS_25 [get_ports DATA1_7_N]
set_property PULLDOWN true [get_ports DATA1_7_P]

set_property IOSTANDARD LVDS_25 [get_ports DATA1_8_P]
set_property PACKAGE_PIN Y8 [get_ports DATA1_8_P]
set_property PACKAGE_PIN Y7 [get_ports DATA1_8_N]
set_property IOSTANDARD LVDS_25 [get_ports DATA1_8_N]
set_property PULLDOWN true [get_ports DATA1_8_P]

########################## CKDT VMM3 ##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_1_P]
set_property PACKAGE_PIN B20 [get_ports CKDT_1_P]
set_property PACKAGE_PIN A20 [get_ports CKDT_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_1_N]

set_property IOSTANDARD TMDS_33 [get_ports CKDT_2_P]
set_property PACKAGE_PIN AA18 [get_ports CKDT_2_P]
set_property PACKAGE_PIN AB18 [get_ports CKDT_2_N]
set_property IOSTANDARD TMDS_33 [get_ports CKDT_2_N]
set_property PULLDOWN true [get_ports CKDT_2_P]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_3_P]
set_property PACKAGE_PIN B21 [get_ports CKDT_3_P]
set_property PACKAGE_PIN A21 [get_ports CKDT_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKDT_3_N]
set_property PULLDOWN true [get_ports CKDT_3_P]

set_property IOSTANDARD LVDS_25 [get_ports CKDT_4_P]
set_property PACKAGE_PIN B1 [get_ports CKDT_4_P]
set_property PACKAGE_PIN A1 [get_ports CKDT_4_N]
set_property IOSTANDARD LVDS_25 [get_ports CKDT_4_N]
set_property PULLDOWN true [get_ports CKDT_4_P]

set_property IOSTANDARD LVDS_25 [get_ports CKDT_5_P]
set_property PACKAGE_PIN F3 [get_ports CKDT_5_P]
set_property PACKAGE_PIN E3 [get_ports CKDT_5_N]
set_property IOSTANDARD LVDS_25 [get_ports CKDT_5_N]
set_property PULLDOWN true [get_ports CKDT_5_P]

set_property IOSTANDARD LVDS_25 [get_ports CKDT_6_P]
set_property PACKAGE_PIN U2 [get_ports CKDT_6_P]
set_property PACKAGE_PIN V2 [get_ports CKDT_6_N]
set_property IOSTANDARD LVDS_25 [get_ports CKDT_6_N]
set_property PULLDOWN true [get_ports CKDT_6_P]

set_property IOSTANDARD TMDS_33 [get_ports CKDT_7_P]
set_property PACKAGE_PIN W19 [get_ports CKDT_7_P]
set_property PACKAGE_PIN W20 [get_ports CKDT_7_N]
set_property IOSTANDARD TMDS_33 [get_ports CKDT_7_N]
set_property PULLDOWN true [get_ports CKDT_7_P]

set_property IOSTANDARD TMDS_33 [get_ports CKDT_8_P]
set_property PACKAGE_PIN N13 [get_ports CKDT_8_P]
set_property PACKAGE_PIN N14 [get_ports CKDT_8_N]
set_property IOSTANDARD TMDS_33 [get_ports CKDT_8_N]
set_property PULLDOWN true [get_ports CKDT_8_P]

########################## CKBC VMM3 ##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_1_P]
set_property PACKAGE_PIN J19 [get_ports CKBC_1_P]
set_property PACKAGE_PIN H19 [get_ports CKBC_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_2_P]
set_property PACKAGE_PIN N22 [get_ports CKBC_2_P]
set_property PACKAGE_PIN M22 [get_ports CKBC_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_2_N]
set_property PULLDOWN true [get_ports CKBC_2_P]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_3_P]
set_property PACKAGE_PIN E13 [get_ports CKBC_3_P]
set_property PACKAGE_PIN E14 [get_ports CKBC_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_3_N]
set_property PULLDOWN true [get_ports CKBC_3_P]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_4_P]
set_property PACKAGE_PIN F19 [get_ports CKBC_4_P]
set_property PACKAGE_PIN F20 [get_ports CKBC_4_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKBC_4_N]
set_property PULLDOWN true [get_ports CKBC_4_P]

set_property IOSTANDARD LVDS_25 [get_ports CKBC_5_P]
set_property PACKAGE_PIN K1 [get_ports CKBC_5_P]
set_property PACKAGE_PIN J1 [get_ports CKBC_5_N]
set_property IOSTANDARD LVDS_25 [get_ports CKBC_5_N]
set_property PULLDOWN true [get_ports CKBC_5_P]

set_property IOSTANDARD LVDS_25 [get_ports CKBC_6_P]
set_property PACKAGE_PIN K6 [get_ports CKBC_6_P]
set_property PACKAGE_PIN J6 [get_ports CKBC_6_N]
set_property IOSTANDARD LVDS_25 [get_ports CKBC_6_N]
set_property PULLDOWN true [get_ports CKBC_6_P]

set_property IOSTANDARD LVDS_25 [get_ports CKBC_7_P]
set_property PACKAGE_PIN R3 [get_ports CKBC_7_P]
set_property PACKAGE_PIN R2 [get_ports CKBC_7_N]
set_property IOSTANDARD LVDS_25 [get_ports CKBC_7_N]
set_property PULLDOWN true [get_ports CKBC_7_P]

set_property IOSTANDARD LVDS_25 [get_ports CKBC_8_P]
set_property PACKAGE_PIN T5 [get_ports CKBC_8_P]
set_property PACKAGE_PIN U5 [get_ports CKBC_8_N]
set_property IOSTANDARD LVDS_25 [get_ports CKBC_8_N]
set_property PULLDOWN true [get_ports CKBC_8_P]

########################## CKTP VMM3 ##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_1_P]
set_property PACKAGE_PIN H20 [get_ports CKTP_1_P]
set_property PACKAGE_PIN G20 [get_ports CKTP_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_2_P]
set_property PACKAGE_PIN F13 [get_ports CKTP_2_P]
set_property PACKAGE_PIN F14 [get_ports CKTP_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_2_N]
set_property PULLDOWN true [get_ports CKTP_2_P]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_3_P]
set_property PACKAGE_PIN C22 [get_ports CKTP_3_P]
set_property PACKAGE_PIN B22 [get_ports CKTP_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTP_3_N]
set_property PULLDOWN true [get_ports CKTP_3_P]

set_property IOSTANDARD LVDS_25 [get_ports CKTP_4_P]
set_property PACKAGE_PIN P2 [get_ports CKTP_4_P]
set_property PACKAGE_PIN N2 [get_ports CKTP_4_N]
set_property IOSTANDARD LVDS_25 [get_ports CKTP_4_N]
set_property PULLDOWN true [get_ports CKTP_4_P]

set_property IOSTANDARD LVDS_25 [get_ports CKTP_5_P]
set_property PACKAGE_PIN H2 [get_ports CKTP_5_P]
set_property PACKAGE_PIN G2 [get_ports CKTP_5_N]
set_property IOSTANDARD LVDS_25 [get_ports CKTP_5_N]
set_property PULLDOWN true [get_ports CKTP_5_P]

set_property IOSTANDARD LVDS_25 [get_ports CKTP_6_P]
set_property PACKAGE_PIN M3 [get_ports CKTP_6_P]
set_property PACKAGE_PIN M2 [get_ports CKTP_6_N]
set_property IOSTANDARD LVDS_25 [get_ports CKTP_6_N]
set_property PULLDOWN true [get_ports CKTP_6_P]

set_property IOSTANDARD LVDS_25 [get_ports CKTP_7_P]
set_property PACKAGE_PIN U3 [get_ports CKTP_7_P]
set_property PACKAGE_PIN V3 [get_ports CKTP_7_N]
set_property IOSTANDARD LVDS_25 [get_ports CKTP_7_N]
set_property PULLDOWN true [get_ports CKTP_7_P]

set_property IOSTANDARD LVDS_25 [get_ports CKTP_8_P]
set_property PACKAGE_PIN R4 [get_ports CKTP_8_P]
set_property PACKAGE_PIN T4 [get_ports CKTP_8_N]
set_property IOSTANDARD LVDS_25 [get_ports CKTP_8_N]
set_property PULLDOWN true [get_ports CKTP_8_P]

########################## CKTK VMM3 ##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_1_P]
set_property PACKAGE_PIN M21 [get_ports CKTK_1_P]
set_property PACKAGE_PIN L21 [get_ports CKTK_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_2_P]
set_property PACKAGE_PIN G21 [get_ports CKTK_2_P]
set_property PACKAGE_PIN G22 [get_ports CKTK_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKTK_2_N]
set_property PULLDOWN true [get_ports CKTK_2_P]

set_property IOSTANDARD TMDS_33 [get_ports CKTK_3_P]
set_property PACKAGE_PIN AA19 [get_ports CKTK_3_P]
set_property PACKAGE_PIN AB20 [get_ports CKTK_3_N]
set_property IOSTANDARD TMDS_33 [get_ports CKTK_3_N]
set_property PULLDOWN true [get_ports CKTK_3_P]

set_property IOSTANDARD TMDS_33 [get_ports CKTK_4_P]
set_property PACKAGE_PIN Y18 [get_ports CKTK_4_P]
set_property PACKAGE_PIN Y19 [get_ports CKTK_4_N]
set_property IOSTANDARD TMDS_33 [get_ports CKTK_4_N]
set_property PULLDOWN true [get_ports CKTK_4_P]

set_property IOSTANDARD LVDS_25 [get_ports CKTK_5_P]
set_property PACKAGE_PIN C2 [get_ports CKTK_5_P]
set_property PACKAGE_PIN B2 [get_ports CKTK_5_N]
set_property IOSTANDARD LVDS_25 [get_ports CKTK_5_N]
set_property PULLDOWN true [get_ports CKTK_5_P]

set_property IOSTANDARD LVDS_25 [get_ports CKTK_6_P]
set_property PACKAGE_PIN P5 [get_ports CKTK_6_P]
set_property PACKAGE_PIN P4 [get_ports CKTK_6_N]
set_property IOSTANDARD LVDS_25 [get_ports CKTK_6_N]
set_property PULLDOWN true [get_ports CKTK_6_P]

set_property IOSTANDARD LVDS_25 [get_ports CKTK_7_P]
set_property PACKAGE_PIN AB3 [get_ports CKTK_7_P]
set_property PACKAGE_PIN AB2 [get_ports CKTK_7_N]
set_property IOSTANDARD LVDS_25 [get_ports CKTK_7_N]
set_property PULLDOWN true [get_ports CKTK_7_P]

set_property IOSTANDARD TMDS_33 [get_ports CKTK_8_P]
set_property PACKAGE_PIN P16 [get_ports CKTK_8_P]
set_property PACKAGE_PIN R17 [get_ports CKTK_8_N]
set_property IOSTANDARD TMDS_33 [get_ports CKTK_8_N]
set_property PULLDOWN true [get_ports CKTK_8_P]

############################# SDI VMM3 ###########################

set_property PACKAGE_PIN G17 [get_ports SDI_1]
set_property IOSTANDARD LVCMOS12 [get_ports SDI_1]

set_property PACKAGE_PIN L19 [get_ports SDI_2]
set_property IOSTANDARD LVCMOS12 [get_ports SDI_2]
set_property PULLDOWN true [get_ports SDI_2]

set_property PACKAGE_PIN C13 [get_ports SDI_3]
set_property IOSTANDARD LVCMOS12 [get_ports SDI_3]
set_property PULLDOWN true [get_ports SDI_3]

set_property PACKAGE_PIN F4 [get_ports SDI_4]
set_property IOSTANDARD LVCMOS25 [get_ports SDI_4]
set_property PULLDOWN true [get_ports SDI_4]

set_property PACKAGE_PIN H3 [get_ports SDI_5]
set_property IOSTANDARD LVCMOS25 [get_ports SDI_5]
set_property PULLDOWN true [get_ports SDI_5]

set_property PACKAGE_PIN L5 [get_ports SDI_6]
set_property IOSTANDARD LVCMOS25 [get_ports SDI_6]
set_property PULLDOWN true [get_ports SDI_6]

set_property PACKAGE_PIN W9 [get_ports SDI_7]
set_property IOSTANDARD LVCMOS25 [get_ports SDI_7]
set_property PULLDOWN true [get_ports SDI_7]

set_property PACKAGE_PIN V9 [get_ports SDI_8]
set_property IOSTANDARD LVCMOS25 [get_ports SDI_8]
set_property PULLDOWN true [get_ports SDI_8]

############################# SDO VMM3 ###########################

set_property PACKAGE_PIN G18 [get_ports SDO_1]
set_property IOSTANDARD LVCMOS12 [get_ports SDO_1]

set_property PACKAGE_PIN L20 [get_ports SDO_2]
set_property IOSTANDARD LVCMOS12 [get_ports SDO_2]
set_property PULLDOWN true [get_ports SDO_2]

set_property PACKAGE_PIN B13 [get_ports SDO_3]
set_property IOSTANDARD LVCMOS12 [get_ports SDO_3]
set_property PULLDOWN true [get_ports SDO_3]

set_property PACKAGE_PIN P20 [get_ports SDO_4]
set_property IOSTANDARD LVCMOS33 [get_ports SDO_4]
set_property PULLDOWN true [get_ports SDO_4]

set_property PACKAGE_PIN G3 [get_ports SDO_5]
set_property IOSTANDARD LVCMOS25 [get_ports SDO_5]
set_property PULLDOWN true [get_ports SDO_5]

set_property PACKAGE_PIN L4 [get_ports SDO_6]
set_property IOSTANDARD LVCMOS25 [get_ports SDO_6]
set_property PULLDOWN true [get_ports SDO_6]

set_property PACKAGE_PIN Y9 [get_ports SDO_7]
set_property IOSTANDARD LVCMOS25 [get_ports SDO_7]
set_property PULLDOWN true [get_ports SDO_7]

set_property PACKAGE_PIN V8 [get_ports SDO_8]
set_property IOSTANDARD LVCMOS25 [get_ports SDO_8]
set_property PULLDOWN true [get_ports SDO_8]

############################# TKI/TKO ###########################

set_property PACKAGE_PIN K17 [get_ports TKI_P]
set_property PACKAGE_PIN J17 [get_ports TKI_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports TKI_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports TKI_N]

set_property PACKAGE_PIN J20 [get_ports TKO_P]
set_property PACKAGE_PIN J21 [get_ports TKO_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports TKO_P]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports TKO_N]

########################## ENA VMM3 ##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_1_P]
set_property PACKAGE_PIN F18 [get_ports ENA_1_P]
set_property PACKAGE_PIN E18 [get_ports ENA_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_2_P]
set_property PACKAGE_PIN K18 [get_ports ENA_2_P]
set_property PACKAGE_PIN K19 [get_ports ENA_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_2_N]
set_property PULLDOWN true [get_ports ENA_2_P]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_3_P]
set_property PACKAGE_PIN A13 [get_ports ENA_3_P]
set_property PACKAGE_PIN A14 [get_ports ENA_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports ENA_3_N]
set_property PULLDOWN true [get_ports ENA_3_P]

set_property IOSTANDARD TMDS_33 [get_ports ENA_4_P]
set_property PACKAGE_PIN P15 [get_ports ENA_4_P]
set_property PACKAGE_PIN R16 [get_ports ENA_4_N]
set_property IOSTANDARD TMDS_33 [get_ports ENA_4_N]
set_property PULLDOWN true [get_ports ENA_4_P]

set_property IOSTANDARD LVDS_25 [get_ports ENA_5_P]
set_property PACKAGE_PIN G1 [get_ports ENA_5_P]
set_property PACKAGE_PIN F1 [get_ports ENA_5_N]
set_property IOSTANDARD LVDS_25 [get_ports ENA_5_N]
set_property PULLDOWN true [get_ports ENA_5_P]

set_property IOSTANDARD LVDS_25 [get_ports ENA_6_P]
set_property PACKAGE_PIN K4 [get_ports ENA_6_P]
set_property PACKAGE_PIN J4 [get_ports ENA_6_N]
set_property IOSTANDARD LVDS_25 [get_ports ENA_6_N]
set_property PULLDOWN true [get_ports ENA_6_P]

set_property IOSTANDARD LVDS_25 [get_ports ENA_7_P]
set_property PACKAGE_PIN AA5 [get_ports ENA_7_P]
set_property PACKAGE_PIN AB5 [get_ports ENA_7_N]
set_property IOSTANDARD LVDS_25 [get_ports ENA_7_N]
set_property PULLDOWN true [get_ports ENA_7_P]

set_property IOSTANDARD LVDS_25 [get_ports ENA_8_P]
set_property PACKAGE_PIN V7 [get_ports ENA_8_P]
set_property PACKAGE_PIN W7 [get_ports ENA_8_N]
set_property IOSTANDARD LVDS_25 [get_ports ENA_8_N]
set_property PULLDOWN true [get_ports ENA_8_P]

########################## CS VMM3 ##############################

set_property PACKAGE_PIN E19 [get_ports CS_1]
set_property IOSTANDARD LVCMOS12 [get_ports CS_1]

set_property PACKAGE_PIN F16 [get_ports CS_2]
set_property IOSTANDARD LVCMOS12 [get_ports CS_2]
set_property PULLDOWN true [get_ports CS_2]

set_property PACKAGE_PIN D14 [get_ports CS_3]
set_property IOSTANDARD LVCMOS12 [get_ports CS_3]
set_property PULLDOWN true [get_ports CS_3]

set_property PACKAGE_PIN U7 [get_ports CS_4]
set_property IOSTANDARD LVCMOS25 [get_ports CS_4]
set_property PULLDOWN true [get_ports CS_4]

set_property PACKAGE_PIN K2 [get_ports CS_5]
set_property IOSTANDARD LVCMOS25 [get_ports CS_5]
set_property PULLDOWN true [get_ports CS_5]

set_property PACKAGE_PIN N4 [get_ports CS_6]
set_property IOSTANDARD LVCMOS25 [get_ports CS_6]
set_property PULLDOWN true [get_ports CS_6]

set_property PACKAGE_PIN W1 [get_ports CS_7]
set_property IOSTANDARD LVCMOS25 [get_ports CS_7]
set_property PULLDOWN true [get_ports CS_7]

set_property PACKAGE_PIN R6 [get_ports CS_8]
set_property IOSTANDARD LVCMOS25 [get_ports CS_8]
set_property PULLDOWN true [get_ports CS_8]

########################## SCK VMM3 ##############################

set_property PACKAGE_PIN D19 [get_ports SCK_1]
set_property IOSTANDARD LVCMOS12 [get_ports SCK_1]

set_property PACKAGE_PIN E17 [get_ports SCK_2]
set_property IOSTANDARD LVCMOS12 [get_ports SCK_2]
set_property PULLDOWN true [get_ports SCK_2]

set_property PACKAGE_PIN D15 [get_ports SCK_3]
set_property IOSTANDARD LVCMOS12 [get_ports SCK_3]
set_property PULLDOWN true [get_ports SCK_3]

set_property PACKAGE_PIN Y17 [get_ports SCK_4]
set_property IOSTANDARD LVCMOS25 [get_ports SCK_4]
set_property PULLDOWN true [get_ports SCK_4]

set_property PACKAGE_PIN J2 [get_ports SCK_5]
set_property IOSTANDARD LVCMOS25 [get_ports SCK_5]
set_property PULLDOWN true [get_ports SCK_5]

set_property PACKAGE_PIN N3 [get_ports SCK_6]
set_property IOSTANDARD LVCMOS25 [get_ports SCK_6]
set_property PULLDOWN true [get_ports SCK_6]

set_property PACKAGE_PIN Y1 [get_ports SCK_7]
set_property IOSTANDARD LVCMOS25 [get_ports SCK_7]
set_property PULLDOWN true [get_ports SCK_7]

set_property PACKAGE_PIN T6 [get_ports SCK_8]
set_property IOSTANDARD LVCMOS25 [get_ports SCK_8]
set_property PULLDOWN true [get_ports SCK_8]

########################## SETT/SETB/CK6B VMM3 #####################

set_property IOSTANDARD LVDS_25 [get_ports SETT_P]
set_property PACKAGE_PIN AA15 [get_ports SETT_P]
set_property PACKAGE_PIN AB15 [get_ports SETT_N]
set_property IOSTANDARD LVDS_25 [get_ports SETT_N]
set_property PULLDOWN true [get_ports SETT_P]

set_property IOSTANDARD LVDS_25 [get_ports SETB_P]
set_property PACKAGE_PIN AB16 [get_ports SETB_P]
set_property PACKAGE_PIN AB17 [get_ports SETB_N]
set_property IOSTANDARD LVDS_25 [get_ports SETB_N]
set_property PULLDOWN true [get_ports SETB_P]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CK6B_1_P]
set_property PACKAGE_PIN M15 [get_ports CK6B_1_P]
set_property PACKAGE_PIN M16 [get_ports CK6B_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CK6B_1_N]
set_property PULLDOWN true [get_ports CK6B_1_P]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CK6B_2_P]
set_property PACKAGE_PIN E22 [get_ports CK6B_2_P]
set_property PACKAGE_PIN D22 [get_ports CK6B_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CK6B_2_N]
set_property PULLDOWN true [get_ports CK6B_2_P]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CK6B_3_P]
set_property PACKAGE_PIN E16 [get_ports CK6B_3_P]
set_property PACKAGE_PIN D16 [get_ports CK6B_3_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CK6B_3_N]
set_property PULLDOWN true [get_ports CK6B_3_P]

set_property IOSTANDARD LVDS_25 [get_ports CK6B_4_P]
set_property PACKAGE_PIN P6 [get_ports CK6B_4_P]
set_property PACKAGE_PIN N5 [get_ports CK6B_4_N]
set_property IOSTANDARD LVDS_25 [get_ports CK6B_4_N]
set_property PULLDOWN true [get_ports CK6B_4_P]

set_property IOSTANDARD LVDS_25 [get_ports CK6B_5_P]
set_property PACKAGE_PIN J5 [get_ports CK6B_5_P]
set_property PACKAGE_PIN H5 [get_ports CK6B_5_N]
set_property IOSTANDARD LVDS_25 [get_ports CK6B_5_N]
set_property PULLDOWN true [get_ports CK6B_5_P]

set_property IOSTANDARD LVDS_25 [get_ports CK6B_6_P]
set_property PACKAGE_PIN R1 [get_ports CK6B_6_P]
set_property PACKAGE_PIN P1 [get_ports CK6B_6_N]
set_property IOSTANDARD LVDS_25 [get_ports CK6B_6_N]
set_property PULLDOWN true [get_ports CK6B_6_P]

set_property IOSTANDARD LVDS_25 [get_ports CK6B_7_P]
set_property PACKAGE_PIN Y3 [get_ports CK6B_7_P]
set_property PACKAGE_PIN AA3 [get_ports CK6B_7_N]
set_property IOSTANDARD LVDS_25 [get_ports CK6B_7_N]
set_property PULLDOWN true [get_ports CK6B_7_P]

set_property IOSTANDARD LVDS_25 [get_ports CK6B_8_P]
set_property PACKAGE_PIN U6 [get_ports CK6B_8_P]
set_property PACKAGE_PIN V5 [get_ports CK6B_8_N]
set_property IOSTANDARD LVDS_25 [get_ports CK6B_8_N]
set_property PULLDOWN true [get_ports CK6B_8_P]

########################## CKART VMM3 ##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_1_P]
set_property PACKAGE_PIN C18 [get_ports CKART_1_P]
set_property PACKAGE_PIN C19 [get_ports CKART_1_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_1_N]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_2_P]
set_property PACKAGE_PIN E21 [get_ports CKART_2_P]
set_property PACKAGE_PIN D21 [get_ports CKART_2_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_2_N]
set_property PULLDOWN true [get_ports CKART_2_P]

set_property IOSTANDARD LVDS_25 [get_ports CKART_3_P]
set_property PACKAGE_PIN Y11 [get_ports CKART_3_P]
set_property PACKAGE_PIN Y12 [get_ports CKART_3_N]
set_property IOSTANDARD LVDS_25 [get_ports CKART_3_N]
set_property PULLDOWN true [get_ports CKART_3_P]

set_property IOSTANDARD LVDS_25 [get_ports CKART_4_P]
set_property PACKAGE_PIN M6 [get_ports CKART_4_P]
set_property PACKAGE_PIN M5 [get_ports CKART_4_N]
set_property IOSTANDARD LVDS_25 [get_ports CKART_4_N]
set_property PULLDOWN true [get_ports CKART_4_P]

set_property IOSTANDARD LVDS_25 [get_ports CKART_5_P]
set_property PACKAGE_PIN H4 [get_ports CKART_5_P]
set_property PACKAGE_PIN G4 [get_ports CKART_5_N]
set_property IOSTANDARD LVDS_25 [get_ports CKART_5_N]
set_property PULLDOWN true [get_ports CKART_5_P]

set_property IOSTANDARD LVDS_25 [get_ports CKART_6_P]
set_property PACKAGE_PIN T1 [get_ports CKART_6_P]
set_property PACKAGE_PIN U1 [get_ports CKART_6_N]
set_property IOSTANDARD LVDS_25 [get_ports CKART_6_N]
set_property PULLDOWN true [get_ports CKART_6_P]

set_property IOSTANDARD LVDS_25 [get_ports CKART_7_P]
set_property PACKAGE_PIN AA1 [get_ports CKART_7_P]
set_property PACKAGE_PIN AB1 [get_ports CKART_7_N]
set_property IOSTANDARD LVDS_25 [get_ports CKART_7_N]
set_property PULLDOWN true [get_ports CKART_7_P]

set_property IOSTANDARD LVDS_25 [get_ports CKART_8_P]
set_property PACKAGE_PIN W6 [get_ports CKART_8_P]
set_property PACKAGE_PIN W5 [get_ports CKART_8_N]
set_property IOSTANDARD LVDS_25 [get_ports CKART_8_N]
set_property PULLDOWN true [get_ports CKART_8_P]

########################## CKART ADDC ##############################

set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_ADDC_P]
set_property PACKAGE_PIN B17 [get_ports CKART_ADDC_P]
set_property PACKAGE_PIN B18 [get_ports CKART_ADDC_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports CKART_ADDC_N]
set_property PULLDOWN true [get_ports CKART_ADDC_P]

########################### XADC GPVMM #############################
# Dedicated Analog Inputs
set_property IOSTANDARD LVCMOS25 [get_ports VP_0]
set_property IOSTANDARD LVCMOS25 [get_ports VN_0]

## Analog Multiplexer Pins
set_property PACKAGE_PIN T20 [get_ports MuxAddr0]
set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr0]
set_property PULLDOWN true [get_ports MuxAddr0]
set_property PACKAGE_PIN P14 [get_ports MuxAddr1]
set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr1]
set_property PULLDOWN true [get_ports MuxAddr1]
set_property PACKAGE_PIN R14 [get_ports MuxAddr2]
set_property IOSTANDARD LVCMOS33 [get_ports MuxAddr2]
set_property PULLDOWN true [get_ports MuxAddr2]
set_property IOSTANDARD TMDS_33 [get_ports MuxAddr3_p]
set_property PACKAGE_PIN R18 [get_ports MuxAddr3_p]
set_property PACKAGE_PIN T18 [get_ports MuxAddr3_n]
set_property IOSTANDARD TMDS_33 [get_ports MuxAddr3_n]
set_property PULLDOWN true [get_ports MuxAddr3_p]

#PDO
#TDO
set_property PACKAGE_PIN J14 [get_ports Vaux1_v_p]
set_property PACKAGE_PIN H14 [get_ports Vaux1_v_n]
set_property PACKAGE_PIN G15 [get_ports Vaux8_v_p]
set_property PACKAGE_PIN G16 [get_ports Vaux8_v_n]
set_property PACKAGE_PIN L10 [get_ports VP_0]
set_property PACKAGE_PIN M9 [get_ports VN_0]

set_property PACKAGE_PIN AB10 [get_ports Vaux0_v_n]
set_property PACKAGE_PIN AA9 [get_ports Vaux0_v_p]
set_property PULLDOWN true [get_ports Vaux0_v_p]

set_property PACKAGE_PIN J22 [get_ports Vaux2_v_p]
set_property PACKAGE_PIN H22 [get_ports Vaux2_v_n]
set_property PULLDOWN true [get_ports Vaux2_v_p]

set_property PACKAGE_PIN K22 [get_ports Vaux3_v_n]
set_property PACKAGE_PIN K21 [get_ports Vaux3_v_p]
set_property PULLDOWN true [get_ports Vaux3_v_p]

set_property PACKAGE_PIN H15 [get_ports Vaux9_v_n]
set_property PACKAGE_PIN J15 [get_ports Vaux9_v_p]
set_property PULLDOWN true [get_ports Vaux9_v_p]


set_property PACKAGE_PIN W17 [get_ports Vaux10_v_n]
set_property PACKAGE_PIN V17 [get_ports Vaux10_v_p]
set_property PULLDOWN true [get_ports Vaux10_v_p]

set_property PACKAGE_PIN U18 [get_ports Vaux11_v_n]
set_property PACKAGE_PIN U17 [get_ports Vaux11_v_p]
set_property PULLDOWN true [get_ports Vaux11_v_p]

set_property IOSTANDARD LVCMOS25 [get_ports Vaux0_v_p]
set_property IOSTANDARD LVCMOS25 [get_ports Vaux0_v_n]
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
set_property IOSTANDARD LVCMOS33 [get_ports Vaux10_v_n]
set_property IOSTANDARD LVCMOS33 [get_ports Vaux10_v_p]
set_property IOSTANDARD LVCMOS33 [get_ports Vaux11_v_n]
set_property IOSTANDARD LVCMOS33 [get_ports Vaux11_v_p]

######################### SPI FLASH ##########################

#set_property IOSTANDARD LVCMOS25 [get_ports SPI_CLK]
set_property IOSTANDARD LVCMOS33 [get_ports IO0_IO]
set_property IOSTANDARD LVCMOS33 [get_ports IO1_IO]
set_property IOSTANDARD LVCMOS33 [get_ports SS_IO]
#set_property PACKAGE_PIN V22 [get_ports SPI_CLK]
set_property PACKAGE_PIN P22 [get_ports IO0_IO]
set_property PACKAGE_PIN R22 [get_ports IO1_IO]
set_property PACKAGE_PIN T19 [get_ports SS_IO]
#set_property OFFCHIP_TERM NONE [get_ports SPI_CLK]

################# GENERAL CONSTRAINTS ########################
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]


set_false_path -from [get_pins udp_din_conf_block/vmm_config_logic/wr_ready_reg/C] -to [get_pins udp_din_conf_block/vmm_config_logic/wr_ready_0_reg/D]


set_property OFFCHIP_TERM NONE [get_ports IO0_IO]
set_property OFFCHIP_TERM NONE [get_ports IO1_IO]
set_property OFFCHIP_TERM NONE [get_ports SS_IO]
create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list core_wrapper/U0/core_clocking_i/userclk2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 11 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {udp_din_conf_block/xadc_sample_size[0]} {udp_din_conf_block/xadc_sample_size[1]} {udp_din_conf_block/xadc_sample_size[2]} {udp_din_conf_block/xadc_sample_size[3]} {udp_din_conf_block/xadc_sample_size[4]} {udp_din_conf_block/xadc_sample_size[5]} {udp_din_conf_block/xadc_sample_size[6]} {udp_din_conf_block/xadc_sample_size[7]} {udp_din_conf_block/xadc_sample_size[8]} {udp_din_conf_block/xadc_sample_size[9]} {udp_din_conf_block/xadc_sample_size[10]}]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list mmcm_master/inst/clk_out_40]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 1 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list udp_din_conf_block/vmm_config_logic/first_rd_done]]
create_debug_core u_ila_2 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_2]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_2]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_2]
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_2]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_2]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_2]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_2]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_2]
set_property port_width 1 [get_debug_ports u_ila_2/clk]
connect_debug_port u_ila_2/clk [get_nets [list udp_din_conf_block/fpga_rst]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe0]
set_property port_width 8 [get_debug_ports u_ila_2/probe0]
connect_debug_port u_ila_2/probe0 [get_nets [list {udp_din_conf_block/cnt_bytes[0]} {udp_din_conf_block/cnt_bytes[1]} {udp_din_conf_block/cnt_bytes[2]} {udp_din_conf_block/cnt_bytes[3]} {udp_din_conf_block/cnt_bytes[4]} {udp_din_conf_block/cnt_bytes[5]} {udp_din_conf_block/cnt_bytes[6]} {udp_din_conf_block/cnt_bytes[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 16 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {udp_din_conf_block/vmm_id_xadc[0]} {udp_din_conf_block/vmm_id_xadc[1]} {udp_din_conf_block/vmm_id_xadc[2]} {udp_din_conf_block/vmm_id_xadc[3]} {udp_din_conf_block/vmm_id_xadc[4]} {udp_din_conf_block/vmm_id_xadc[5]} {udp_din_conf_block/vmm_id_xadc[6]} {udp_din_conf_block/vmm_id_xadc[7]} {udp_din_conf_block/vmm_id_xadc[8]} {udp_din_conf_block/vmm_id_xadc[9]} {udp_din_conf_block/vmm_id_xadc[10]} {udp_din_conf_block/vmm_id_xadc[11]} {udp_din_conf_block/vmm_id_xadc[12]} {udp_din_conf_block/vmm_id_xadc[13]} {udp_din_conf_block/vmm_id_xadc[14]} {udp_din_conf_block/vmm_id_xadc[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 18 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {udp_din_conf_block/xadc_delay[0]} {udp_din_conf_block/xadc_delay[1]} {udp_din_conf_block/xadc_delay[2]} {udp_din_conf_block/xadc_delay[3]} {udp_din_conf_block/xadc_delay[4]} {udp_din_conf_block/xadc_delay[5]} {udp_din_conf_block/xadc_delay[6]} {udp_din_conf_block/xadc_delay[7]} {udp_din_conf_block/xadc_delay[8]} {udp_din_conf_block/xadc_delay[9]} {udp_din_conf_block/xadc_delay[10]} {udp_din_conf_block/xadc_delay[11]} {udp_din_conf_block/xadc_delay[12]} {udp_din_conf_block/xadc_delay[13]} {udp_din_conf_block/xadc_delay[14]} {udp_din_conf_block/xadc_delay[15]} {udp_din_conf_block/xadc_delay[16]} {udp_din_conf_block/xadc_delay[17]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 8 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {udp_din_conf_block/user_data_prv[0]} {udp_din_conf_block/user_data_prv[1]} {udp_din_conf_block/user_data_prv[2]} {udp_din_conf_block/user_data_prv[3]} {udp_din_conf_block/user_data_prv[4]} {udp_din_conf_block/user_data_prv[5]} {udp_din_conf_block/user_data_prv[6]} {udp_din_conf_block/user_data_prv[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 3 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {udp_din_conf_block/conf_state[0]} {udp_din_conf_block/conf_state[1]} {udp_din_conf_block/conf_state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list udp_din_conf_block/daq_on]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list udp_din_conf_block/ext_trigger]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list udp_din_conf_block/flash_busy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list udp_din_conf_block/flashPacket_rdy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list udp_din_conf_block/fpgaPacket_rdy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list udp_din_conf_block/newIP_rdy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list udp_din_conf_block/top_rdy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list udp_din_conf_block/user_last_prv]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list udp_din_conf_block/user_valid_prv]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list udp_din_conf_block/vmmConf_done]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list udp_din_conf_block/xadc_rdy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list udp_din_conf_block/xadcPacket_rdy]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 1 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list udp_din_conf_block/vmm_config_logic/init_ser]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 1 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list udp_din_conf_block/vmm_config_logic/rst_ram]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 1 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list udp_din_conf_block/vmm_cfg_bit]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 1 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list udp_din_conf_block/vmm_ser_done]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe1]
set_property port_width 1 [get_debug_ports u_ila_2/probe1]
connect_debug_port u_ila_2/probe1 [get_nets [list udp_din_conf_block/flash_conf]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe2]
set_property port_width 1 [get_debug_ports u_ila_2/probe2]
connect_debug_port u_ila_2/probe2 [get_nets [list udp_din_conf_block/fpga_conf]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe3]
set_property port_width 1 [get_debug_ports u_ila_2/probe3]
connect_debug_port u_ila_2/probe3 [get_nets [list udp_din_conf_block/vmm_conf_rdy]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe4]
set_property port_width 1 [get_debug_ports u_ila_2/probe4]
connect_debug_port u_ila_2/probe4 [get_nets [list udp_din_conf_block/vmmConf_rdy]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe5]
set_property port_width 1 [get_debug_ports u_ila_2/probe5]
connect_debug_port u_ila_2/probe5 [get_nets [list udp_din_conf_block/xadc_busy]]
create_debug_port u_ila_2 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe6]
set_property port_width 1 [get_debug_ports u_ila_2/probe6]
connect_debug_port u_ila_2/probe6 [get_nets [list udp_din_conf_block/xadc_conf]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets userclk2]
