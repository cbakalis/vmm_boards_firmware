#
# Vivado (TM) v2017.2 (64-bit)
#
# buildvmmFrontEnd.tcl: Tcl script for creating generic VMM Front End projects 
#
# This file contains the Vivado Tcl commands for re-creating the project to the state*
# when this script was generated. In order to re-create the project, please source this
# file in the Vivado Tcl Shell.
#
# * Note that the runs in the created project will be configured the same way as the
#   original project, however they will not be launched automatically. To regenerate the
#   run results please launch the synthesis/implementation runs as needed.
#
#*****************************************************************************************
#################################  README FIRST ##########################################
#*****************************************************************************************
#
# This generic .tcl script points to the source files needed to re-create the project
# 'vmmFrontEnd'. The user may change the project name at the #Set project name
#  field as he wishes. (e.g. set projectname "myproject"). 
#
# For more info on how to make further changes to the script, see: 
# http://xillybus.com/tutorials/vivado-version-control-packaging
# 
#*****************************************************************************************
##########################-Christos Bakalis, christos.bakalis@cern.ch-####################
#######################-Paris Moschovakos, paris.moschovakos@cern.ch-#####################
#*****************************************************************************************
# Set part type
set thepart "xc7a200tfbg484-2"

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir [file dirname [info script]]

    #Set project name from argument
        if {$argv == "mdt_mu2e"} {    
            set projectname "MDT_MU2E"
            puts "Correct. Building Project for MDT MU2E board..."
        } elseif {$argv == "gpvmm"} {
	    set thepart "xc7a100tfgg484-2"
            set projectname "GPVMM"
            puts "Correct. Building Project for MDT GPVMM board..."
        } elseif {$argv == "mmfe1"} {
	    set thepart "xc7a100tfgg484-2"
            set projectname "MMFE1"
            puts "Correct. Building Project for MDT MMFE1 board..."
	} elseif {$argv == "mdt_446"} {
            set projectname "MDT_446"
            puts "Correct. Building Project for MDT 446 board..."
        } elseif {$argv == "mmfe8_vmm3"} {
            set projectname "MMFE8_VMM3"
            puts "Correct. Building Project for MMFE8 VMM3 board..."
        } else {
            puts "ERROR! Please, give argument mdt_mu2e or mdt_446 or mmfe8_vmm3 or mmfe1 or gpvmm."
        }

# Create project
create_project $projectname $origin_dir/$projectname 

## Use origin directory path location variable, if specified in the tcl shell
#if { [info exists ::origin_dir_loc] } {
#  set origin_dir $::origin_dir_loc
#}

variable script_file
set script_file "build_mmfe8.tcl"

# Help information for this script
proc help {} {
  variable script_file
  puts "\nDescription:"
  puts "Recreate a Vivado project from this script. The created project will be"
  puts "functionally equivalent to the original project for which this script was"
  puts "generated. The script contains commands for creating a project, filesets,"
  puts "runs, adding/importing sources and setting properties on various objects.\n"
  puts "Syntax:"
  puts "$script_file"
  puts "$script_file -tclargs \[--origin_dir <path>\]"
  puts "$script_file -tclargs \[--help\]\n"
  puts "Usage:"
  puts "Name                   Description"
  puts "-------------------------------------------------------------------------"
  puts "\[--origin_dir <path>\]  Determine source file paths wrt this path. Default"
  puts "                       origin_dir path value is \".\", otherwise, the value"
  puts "                       that was set with the \"-paths_relative_to\" switch"
  puts "                       when this script was generated.\n"
  puts "\[--help\]               Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < [llength $::argc]} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--origin_dir" { incr i; set origin_dir [lindex $::argv $i] }
      "--help"       { help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "$origin_dir"]"

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Reconstruct message rules
# None

# Set project properties
set obj [get_projects $projectname]
set_property "default_lib" "xil_defaultlib" $obj
set_property "generate_ip_upgrade_log" "0" $obj
set_property "part" $thepart $obj
set_property "sim.ip.auto_export_scripts" "1" $obj
set_property "simulator_language" "VHDL" $obj
set_property "target_language" "VHDL" $obj
set_property "xpm_libraries" "XPM_CDC XPM_MEMORY" $obj

# # Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
# set obj [get_filesets sources_1]
set obj [get_filesets sources_1]   
set files [list \
 "[file normalize "$origin_dir/sources_1/vmmFrontEnd.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/udp_data_in_handler.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/udp_reply_handler.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/fpga_config_block.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/vmm_config_block.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/axi_quad_top.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/clk_gen_wrapper.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/cktp_gen.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/cktp_counter.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/trint_gen.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/ckbc_gen.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/skew_gen.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/vmm_oddr_wrapper.vhd"]"\
 "[file normalize "$origin_dir/sources_1/configuration/fpga_config_router.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/arp_REQ.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/arp.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/arp_RX.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/axi.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/temac_10_100_1000_config_vector_sm.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/arp_STORE_br.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/IP_complete_nomac.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/tx_arbitrator.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/arp_SYNC.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/IPv4_RX.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/UDP_ICMP_Complete_nomac.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/ICMP_RX.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/ICMP_TX.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/ping_reply_processor.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/icmp_udp_mux.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/arp_SYNC.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/arp_TX.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/IPv4_TX.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/UDP_RX.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/arp_types.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/ipv4_types.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/UDP_TX.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/arpv2.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/IPv4.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/i2c_top.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/temac_10_100_1000_fifo_block.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/temac_10_100_1000_block.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/axi_ipif/temac_10_100_1000_ipif_pkg.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/fifo/temac_10_100_1000_rx_client_fifo.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/fifo/temac_10_100_1000_tx_client_fifo.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/fifo/temac_10_100_1000_ten_100_1g_eth_fifo.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/common/temac_10_100_1000_reset_sync.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/common/temac_10_100_1000_sync_block.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/CDCC.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/Code8b10bPkg.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/Decoder8b10b.vhd"]"\
 "[file normalize "$origin_dir/sources_1/imports/StdRtlPkg.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/8b10_dec.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/8b10_dec_wrap.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/BLOCK_WORD_COUNTER.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/CD_COUNTER.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/centralRouter_package.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/Elink2FIFO.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/elink_daq_driver.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/elink_daq_tester.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/elink_wrapper.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/enc_8b10.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/enc8b10_wrap.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPATH_FIFO_WRAP.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_FIFO_DRIVER.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_IN16_ALIGN_BLOCK.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_IN16_DEC8b10b.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_IN16_direct.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_IN16.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_IN2_DEC8b10b.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_IN2_HDLC.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_IN2.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_IN4_DEC8b10b.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_IN4.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_IN8_DEC8b10b.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_IN8.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_OUT2_direct.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_OUT2_ENC8b10b.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_OUT2_HDLC.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_OUT2.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_OUT4_direct.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_OUT4_ENC8b10b.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_OUT4.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_OUT8_ENC8b10b.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/EPROC_OUT8.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/FIFO2Elink.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/KcharTest.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/MUX2_Nbit.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/MUX4_Nbit.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/MUX4.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/MUX8_Nbit.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/pulse_fall_pw01.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/pulse_pdxx_pwxx.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/reg8to16bit.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/SCDataMANAGER.vhd"]"\
 "[file normalize "$origin_dir/sources_1/elinks/upstreamEpathFifoWrap.vhd"]"\
 "[file normalize "$origin_dir/sources_1/ip/ila_0_1.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/ila_user_FIFO.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/ila_pf.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/readout_fifo.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/ila_readout.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/temac_10_100_1000.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/gig_ethernet_pcs_pma_0.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/ila_top_level.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/packet_len_fifo.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/ila_1.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/ila_l0.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/ila_overview.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/vio_0.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/vio_ip.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/vio_elink.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/clk_wiz_gen.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/ila_spi_flash.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/axi_quad_spi_0.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/icmp_payload_buffer.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/level0_buffer.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/cont_buffer.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/vmm_conf_buffer.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/fpga_reg_buffer.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/DAQelinkFIFO.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/AuxElinkFIFO.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/adapterFIFO.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/EPATH_FIFO.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/fh_epath_fifo2K_18bit_wide.xcix"]"\
 "[file normalize "$origin_dir/sources_1/ip/hdlc_bist_fifo.xcix"]"\
 "[file normalize "$origin_dir/sources_1/readout/event_timing_reset.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/select_data.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/vmmSignalsDemux.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/FIFO2UDP.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/trigger.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/vmm_readout.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/packet_formation.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/vmm_driver.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/vmm_readout_wrapper.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/level0_wrapper.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/l0_buffer_wrapper.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/l0_deserializer_decoder.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/artReadout.vhd"]"\
 "[file normalize "$origin_dir/sources_1/readout/l0_link_health.vhd"]"\
]

add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset file properties for remote files
set file "$origin_dir/sources_1/vmmFrontEnd.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/udp_data_in_handler.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/udp_reply_handler.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/vmm_config_block.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/fpga_config_block.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/axi_quad_top.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/clk_gen_wrapper.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/cktp_gen.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/cktp_counter.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/trint_gen.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/ckbc_gen.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/skew_gen.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/vmm_oddr_wrapper.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/configuration/fpga_config_router.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/arp_REQ.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/arp.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/arp_RX.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/axi.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/temac_10_100_1000_config_vector_sm.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/arp_STORE_br.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/IP_complete_nomac.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/tx_arbitrator.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/arp_SYNC.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/IPv4_RX.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/UDP_ICMP_Complete_nomac.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/arp_SYNC.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/arp_TX.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/IPv4_TX.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/UDP_RX.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/ICMP_RX.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/ICMP_TX.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/ping_reply_processor.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/icmp_udp_mux.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/arp_types.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/ipv4_types.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/UDP_TX.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/arpv2.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/IPv4.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/i2c_top.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/temac_10_100_1000_fifo_block.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/temac_10_100_1000_block.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/axi_ipif/temac_10_100_1000_ipif_pkg.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/fifo/temac_10_100_1000_rx_client_fifo.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/fifo/temac_10_100_1000_tx_client_fifo.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/fifo/temac_10_100_1000_ten_100_1g_eth_fifo.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/common/temac_10_100_1000_reset_sync.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/sgmii_10_100_1000/ipcore_dir/temac_10_100_1000/example_design/common/temac_10_100_1000_sync_block.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/CDCC.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/Code8b10bPkg.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/Decoder8b10b.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/imports/StdRtlPkg.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/event_timing_reset.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/select_data.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/vmmSignalsDemux.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/FIFO2UDP.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/trigger.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/packet_formation.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/vmm_driver.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/vmm_readout.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/vmm_readout_wrapper.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/level0_wrapper.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/l0_buffer_wrapper.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/l0_deserializer_decoder.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/artReadout.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/readout/l0_link_health.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/8b10_dec.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/8b10_dec_wrap.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/BLOCK_WORD_COUNTER.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/CD_COUNTER.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/centralRouter_package.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/Elink2FIFO.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/elink_daq_driver.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/elink_daq_tester.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/elink_wrapper.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/enc_8b10.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/enc8b10_wrap.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPATH_FIFO_WRAP.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_FIFO_DRIVER.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_IN16_ALIGN_BLOCK.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_IN16_DEC8b10b.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_IN16_direct.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_IN16.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_IN2_DEC8b10b.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_IN2_HDLC.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_IN2.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_IN4_DEC8b10b.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_IN4.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_IN8_DEC8b10b.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_IN8.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_OUT2_direct.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_OUT2_ENC8b10b.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_OUT2_HDLC.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_OUT2.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_OUT4_direct.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_OUT4_ENC8b10b.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_OUT4.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_OUT8_ENC8b10b.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/EPROC_OUT8.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/FIFO2Elink.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/KcharTest.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/MUX2_Nbit.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/MUX4_Nbit.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/MUX4.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/MUX8_Nbit.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/pulse_fall_pw01.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/pulse_pdxx_pwxx.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/reg8to16bit.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/SCDataMANAGER.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

set file "$origin_dir/sources_1/elinks/upstreamEpathFifoWrap.vhd"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "file_type" "VHDL" $file_obj

if {$argv == "mmfe8_vmm3"} {

    set obj [get_filesets sources_1]
    set files [list \
     "[file normalize "$origin_dir/sources_1/xadc/mmfe8_xadc/xadc.v"]"\
     "[file normalize "$origin_dir/sources_1/xadc/mmfe8_xadc/xadc_read.v"]"\
     "[file normalize "$origin_dir/sources_1/xadc/mmfe8_xadc/xadc_wiz_0.xcix"]"
    ]
    add_files -norecurse -fileset $obj $files

    set file "$origin_dir/sources_1/xadc/mmfe8_xadc/xadc.v"
    set file [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
    set_property "file_type" "verilog" $file_obj

    set file "$origin_dir/sources_1/xadc/mmfe8_xadc/xadc_read.v"
    set file [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
    set_property "file_type" "verilog" $file_obj

} else {

    set obj [get_filesets sources_1]
    set files [list \
     "[file normalize "$origin_dir/sources_1/xadc/mdt_xadc/xadc.v"]"\
     "[file normalize "$origin_dir/sources_1/xadc/mdt_xadc/xadc_read.v"]"\
     "[file normalize "$origin_dir/sources_1/xadc/mdt_xadc/xadc_wiz_0.xcix"]"
    ]
    add_files -norecurse -fileset $obj $files

    set file "$origin_dir/sources_1/xadc/mdt_xadc/xadc.v"
    set file [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
    set_property "file_type" "verilog" $file_obj

    set file "$origin_dir/sources_1/xadc/mdt_xadc/xadc_read.v"
    set file [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
    set_property "file_type" "verilog" $file_obj
}


# Set 'sources_1' fileset file properties for local files
# None

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "top" "vmmFrontEnd" $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# General constraints add
set file "[file normalize "$origin_dir/constrs_1/vmm3_glbl_constr.xdc"]"
set file_added [add_files -norecurse -fileset $obj $file]
set file "$origin_dir/constrs_1/vmm3_glbl_constr.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property "file_type" "XDC" $file_obj

if {$argv == "mdt_mu2e"} {    
    # Add/Import constrs file and set constrs file properties from argument
    set file "[file normalize "$origin_dir/constrs_1/mdt_mu2e.xdc"]"
    set file_added [add_files -norecurse -fileset $obj $file]
    set file "$origin_dir/constrs_1/mdt_mu2e.xdc"
    set file [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
    set_property "file_type" "XDC" $file_obj
} elseif {$argv == "mdt_446"} {
    # Add/Import constrs file and set constrs file properties from argument
    set file "[file normalize "$origin_dir/constrs_1/mdt_446.xdc"]"
    set file_added [add_files -norecurse -fileset $obj $file]
    set file "$origin_dir/constrs_1/mdt_446.xdc"
    set file [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
    set_property "file_type" "XDC" $file_obj
} elseif {$argv == "gpvmm"} {
    # Add/Import constrs file and set constrs file properties from argument
    set file "[file normalize "$origin_dir/constrs_1/gpvmm.xdc"]"
    set file_added [add_files -norecurse -fileset $obj $file]
    set file "$origin_dir/constrs_1/gpvmm.xdc"
    set file [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
    set_property "file_type" "XDC" $file_obj
} elseif {$argv == "mmfe1"} {
    # Add/Import constrs file and set constrs file properties from argument
    set file "[file normalize "$origin_dir/constrs_1/mmfe1.xdc"]"
    set file_added [add_files -norecurse -fileset $obj $file]
    set file "$origin_dir/constrs_1/mmfe1.xdc"
    set file [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
    set_property "file_type" "XDC" $file_obj
} elseif {$argv == "mmfe8_vmm3"} {
    # Add/Import constrs file and set constrs file properties from argument
    set file "[file normalize "$origin_dir/constrs_1/mmfe8_vmm3.xdc"]"
    set file_added [add_files -norecurse -fileset $obj $file]
    set file "$origin_dir/constrs_1/mmfe8_vmm3.xdc"
    set file [file normalize $file]
    set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
    set_property "file_type" "XDC" $file_obj
} else { puts "ERROR!"} 

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# # Set 'sim_1' fileset object
# set obj [get_filesets sim_1]
# set files [list \
#  "[file normalize "$origin_dir/sims/packet_formation_tester_top_tb.vhd"]"\
# ]
# add_files -norecurse -fileset $obj $files

# # Set 'sim_1' fileset file properties for remote files
# set file "$origin_dir/sims/packet_formation_tester_top_tb.vhd"
# set file [file normalize $file]
# set file_obj [get_files -of_objects [get_filesets sim_1] [list "*$file"]]
# set_property "file_type" "VHDL" $file_obj


# Set 'sim_1' fileset file properties for local files
# None

# Set 'sim_1' fileset properties
# set obj [get_filesets sim_1]
# set_property "top" "packet_formation_tester_top_tb" $obj
# set_property "transport_int_delay" "0" $obj
# set_property "transport_path_delay" "0" $obj
# set_property "xelab.nosort" "1" $obj
# set_property "xelab.unifast" "" $obj

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part $thepart -flow {Vivado Synthesis 2017} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2017" [get_runs synth_1]
}
set obj [get_runs synth_1]
set_property "part" "$thepart" $obj

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part $thepart -flow {Vivado Implementation 2017} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2017" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property "part" $thepart $obj
set_property "steps.write_bitstream.args.readback_file" "0" $obj
set_property "steps.write_bitstream.args.verbose" "0" $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "Copyright Notice/Copying Permission:
    Copyright 2017 Paris Moschovakos, Panagiotis Gkountoumis & Christos Bakalis\n

    This file is part of NTUA-BNL_VMM_firmware.\n

    NTUA-BNL_VMM_firmware is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NTUA-BNL_VMM_firmware is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NTUA-BNL_VMM_firmware.  If not, see <http://www.gnu.org/licenses/>.\n"
puts "INFO: Project created:$projectname"
