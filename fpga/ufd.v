module ufd
(
	input i_rst_n,
	input i_clk50M,
	input i_clk48M,
	input i_trig,
	output o_trig,
	
	input [7:0] i_ad_data,
	
	output o_eth_rst,
	output o_eth_gtxclk,
	output o_eth_txen,
	output [7:0] o_eth_txd,
	input i_eth_rxclk,
	input i_eth_rxdv,
	input [7:0] i_eth_rxd
);

endmodule
