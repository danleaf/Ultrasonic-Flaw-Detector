## Generated SDC file "voice.out.sdc"

## Copyright (C) 1991-2010 Altera Corporation
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
## VERSION "Version 10.1 Build 153 11/29/2010 SJ Full Version"

## DATE    "Sun Apr 05 13:40:36 2015"

##
## DEVICE  "EP2C8Q208C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {sysclk} -period 20.000 -waveform { 0.000 10.000 } [get_ports {i_clk_sys50m}]


#**************************************************************
# Create Generated Clock
#**************************************************************

derive_pll_clocks -use_net_name -create_base_clocks
#create_generated_clock -name {pll100m:pll_inst|altpll:altpll_component|_clk0} -source [get_pins {pll_inst|altpll_component|pll|inclk[0]}] -multiply_by 2 -master_clock {sysclk} [get_pins {pll_inst|altpll_component|pll|clk[0]}] 
#create_generated_clock -name {pll100m:pll_inst|altpll:altpll_component|_clk1} -source [get_pins {pll_inst|altpll_component|pll|inclk[0]}] -multiply_by 2 -phase -57.60 -master_clock {sysclk} [get_pins {pll_inst|altpll_component|pll|clk[1]}] 
create_generated_clock -name {sdramclk} -source [get_pins {pll_inst|altpll_component|pll|clk[1]}] -master_clock {pll100m:pll_inst|altpll:altpll_component|_clk1} [get_ports {o_sdram_clk}] 
create_generated_clock -name {clkred} -source [get_ports {i_clk_sys50m}] -divide_by 50 -master_clock {sysclk} [get_nets {divclk0|outclk}] 
create_generated_clock -name {clknum} -source [get_ports {i_clk_sys50m}] -divide_by 50000 -master_clock {sysclk} [get_nets {divclk1|outclk}] 
create_generated_clock -name {clkshow} -source [get_ports {i_clk_sys50m}] -divide_by 50000 -master_clock {sysclk} [get_nets {divclk2|outclk}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[0]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[0]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[1]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[1]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[2]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[2]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[3]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[3]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[4]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[4]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[5]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[5]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[6]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[6]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[7]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[7]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[8]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[8]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[9]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[9]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[10]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[10]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[11]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[11]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[12]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[12]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[13]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[13]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[14]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[14]}]
set_input_delay -add_delay -max -clock [get_clocks {sdramclk}]  -7.000 [get_ports {io_sdram_data[15]}]
set_input_delay -add_delay -min -clock [get_clocks {sdramclk}]  -8.000 [get_ports {io_sdram_data[15]}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[0]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[0]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[1]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[1]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[2]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[2]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[3]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[3]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[4]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[4]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[5]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[5]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[6]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[6]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[7]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[7]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[8]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[8]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[9]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[9]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[10]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[10]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[11]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[11]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[12]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[12]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[13]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[13]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[14]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[14]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {io_sdram_data[15]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {io_sdram_data[15]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[0]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[0]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[1]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[1]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[2]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[2]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[3]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[3]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[4]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[4]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[5]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[5]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[6]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[6]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[7]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[7]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[8]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[8]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[9]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[9]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[10]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[10]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[11]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[11]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_addr[12]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_addr[12]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_ba[0]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_ba[0]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_ba[1]}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_ba[1]}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_cas}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_cas}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_ras}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_ras}]
set_output_delay -add_delay -max -clock [get_clocks {sdramclk}]  1.800 [get_ports {o_sdram_we}]
set_output_delay -add_delay -min -clock [get_clocks {sdramclk}]  -1.100 [get_ports {o_sdram_we}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path  -from  [get_clocks {clkred}]  -to  [get_clocks {pll100m:pll_inst|altpll:altpll_component|_clk0}]
set_false_path  -from  [get_clocks {pll100m:pll_inst|altpll:altpll_component|_clk0}]  -to  [get_clocks {clknum}]
set_false_path  -from  [get_clocks {pll100m:pll_inst|altpll:altpll_component|_clk0}]  -to  [get_clocks {clkshow}]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************

set_max_delay -from [get_clocks {pll100m:pll_inst|altpll:altpll_component|_clk1}] -to [get_ports {o_sdram_clk}] 5.000


#**************************************************************
# Set Minimum Delay
#**************************************************************

set_min_delay -from [get_clocks {pll100m:pll_inst|altpll:altpll_component|_clk1}] -to [get_ports {o_sdram_clk}] 1.000


#**************************************************************
# Set Input Transition
#**************************************************************

