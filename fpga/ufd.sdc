## Generated SDC file "ufd.out.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.1.0 Build 162 10/23/2013 SJ Full Version"

## DATE    "Wed Aug 26 10:37:14 2015"

##
## DEVICE  "EP4CE40F23I7"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {altera_reserved_tck} -period 100.000 -waveform { 0.000 50.000 } [get_ports {altera_reserved_tck}]
create_clock -name {clk50M} -period 20.000 -waveform { 0.000 10.000 } [get_ports {i_clk50M}]
create_clock -name {rtxclk} -period 8.000 -waveform { 0.000 4.000 } [get_ports {i_eth_rxclk}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {outgtxclk} -source [get_pins {plleth|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 5 -divide_by 2 -master_clock {clk50M} [get_pins {plleth|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {gtxclk} -source [get_pins {plleth|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 5 -divide_by 2 -master_clock {clk50M} [get_pins {plleth|altpll_component|auto_generated|pll1|clk[1]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 


#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************

set_multicycle_path -setup -end -from [get_keepers {cmdproc:cmdproc_inst|param[0] cmdproc:cmdproc_inst|param[1] cmdproc:cmdproc_inst|param[2] cmdproc:cmdproc_inst|param[3] cmdproc:cmdproc_inst|param[4] cmdproc:cmdproc_inst|param[5] cmdproc:cmdproc_inst|param[6] cmdproc:cmdproc_inst|param[7] cmdproc:cmdproc_inst|param[8] cmdproc:cmdproc_inst|param[9] cmdproc:cmdproc_inst|param[10] cmdproc:cmdproc_inst|param[11] cmdproc:cmdproc_inst|param[12] cmdproc:cmdproc_inst|param[13] cmdproc:cmdproc_inst|param[14] cmdproc:cmdproc_inst|param[15] cmdproc:cmdproc_inst|param[16] cmdproc:cmdproc_inst|param[17] cmdproc:cmdproc_inst|param[18] cmdproc:cmdproc_inst|param[19] cmdproc:cmdproc_inst|param[20] cmdproc:cmdproc_inst|param[21] cmdproc:cmdproc_inst|param[22] cmdproc:cmdproc_inst|param[23] cmdproc:cmdproc_inst|param[24] cmdproc:cmdproc_inst|param[25] cmdproc:cmdproc_inst|param[26] cmdproc:cmdproc_inst|param[27] cmdproc:cmdproc_inst|param[28] cmdproc:cmdproc_inst|param[29] cmdproc:cmdproc_inst|param[30] cmdproc:cmdproc_inst|param[31]}] -to [get_keepers {cmdproc:cmdproc_inst|o_pulse[0] cmdproc:cmdproc_inst|o_pulse[1] cmdproc:cmdproc_inst|o_pulse[2] cmdproc:cmdproc_inst|o_pulse[3] cmdproc:cmdproc_inst|o_pulse[4] cmdproc:cmdproc_inst|o_pulse[5] cmdproc:cmdproc_inst|o_pulse[6] cmdproc:cmdproc_inst|o_pulse[7] cmdproc:cmdproc_inst|o_pulse[8] cmdproc:cmdproc_inst|o_pulse[9] cmdproc:cmdproc_inst|o_pulse[10] cmdproc:cmdproc_inst|o_pulse[11]}] 4


#**************************************************************
# Set Maximum Delay
#**************************************************************

set_max_delay -from [get_clocks {outgtxclk}] -to [get_ports {o_eth_gtxclk}] 5.000


#**************************************************************
# Set Minimum Delay
#**************************************************************

set_min_delay -from [get_clocks {outgtxclk}] -to [get_ports {o_eth_gtxclk}] 1.000


#**************************************************************
# Set Input Transition
#**************************************************************

