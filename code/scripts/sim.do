#!/usr/bin/tclsh

# Main proc at the end #

#------------------------------------------------------------------------------
proc vhdl_compile { } {
  global Path_VHDL
  global Path_TB
  puts "\nVHDL compilation :"

  vcom -2008 $Path_VHDL/ble_packet_analyzer.vhd
  vlog -sv $Path_TB/ble_packet_analyzer_tb.sv
}

#------------------------------------------------------------------------------
proc sim_start { testcase errno} {

  vsim -t 1ns -novopt -GTESTCASE=$testcase -GERRNO=$errno work.packet_analyzer_tb
#  do wave.do
  add wave -r *
  wave refresh
  run -all
}

#------------------------------------------------------------------------------
proc do_all { testcase errno } {
  vhdl_compile
  sim_start $testcase $errno
}

## MAIN #######################################################################

# Compile folder ----------------------------------------------------
if {[file exists work] == 0} {
  vlib work
}

puts -nonewline "  Path_VHDL => "
set Path_VHDL     "../src_vhd"
set Path_TB       "../src_tb"

global Path_VHDL
global Path_TB

# start of sequence -------------------------------------------------

if {$argc==1} {
  if {[string compare $1 "all"] == 0} {
    do_all 0 0
  } elseif {[string compare $1 "comp_vhdl"] == 0} {
    vhdl_compile
  } elseif {[string compare $1 "sim"] == 0} {
    sim_start 0
  }

} else {
  do_all 0 0
}
