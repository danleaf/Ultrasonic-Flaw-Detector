## Generated SDC file "ufd.sdc"

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

## DATE    "Wed Aug 19 11:41:06 2015"

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

create_clock -name {clk50M} -period 20.000 -waveform { 0.000 10.000 } [get_ports {i_clk50M}]
create_clock -name {rtxclk} -period 8.000 -waveform { 0.000 4.000 } [get_ports {i_eth_rxclk}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {outgtxclk} -source {plleth|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 2 -multiply_by 5 -duty_cycle 50.00 {plleth|altpll_component|auto_generated|pll1|clk[0]}
create_generated_clock -name {gtxclk} -source {plleth|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 2 -multiply_by 5 -duty_cycle 50.00 {plleth|altpll_component|auto_generated|pll1|clk[1]}

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



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************

set_max_delay -from [get_clocks {outgtxclk}] -to [get_ports {o_eth_gtxclk}] 5.000

#**************************************************************
# Set Maximum Delay
#**************************************************************

set_min_delay -from [get_clocks {outgtxclk}] -to [get_ports {o_eth_gtxclk}] 1.000

#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

