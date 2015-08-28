module ufd
(
	input i_rst_n,
	input i_clk50M1,
	input i_clk50M2,
	input i_clk48M1,
	input i_clk48M2,
	input i_eth_rxclk,
	
	output o_eth_gtxclk,
	output o_ad_clk,
	
	output reg o_ad
);
	
	wire clk_ad;
	pll180m pll1(i_clk50M1,o_ad_clk,clk_ad);
	
	always@(posedge clk_ad)
		o_ad <= ~o_ad;
	

endmodule
