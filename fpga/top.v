module top
(
	input i_rst_n,
	input i_clk_sys,i_clk_sys1,i_clk_sys2,i_clk_sys3,
	input i_ctrl1,i_ctrl2,
	output o_pwm,
	
	output o_clk_da,
	output o_da_sleep,
	output [7:0] o_da_data,
	
	output o_clk_ad,
	output o_ad_pdwn,
	input [7:0] i_ad_data,
	
	output o_clk_sdram,
	inout [15:0] io_sdram_data,
	output [1:0] o_sdram_ba,
	output [12:0] o_sdram_addr,
	output o_sdram_ras,
	output o_sdram_cas,
	output o_sdram_we,
	output o_sdram_cke,
	output o_sdram_cs,
	output o_sdram_udqm,
	output o_sdram_ldqm,
	
	output o_eth_gtxclk,
	output o_eth_txen,
	output o_eth_txer,
	output [7:0] o_eth_txd,
	input i_eth_rxclk,
	input i_eth_rxdv,
	input i_eth_rxer,
	input [7:0] i_eth_rxd,
	input i_eth_crs,i_eth_col,
	inout io_eth_mdio,
	output o_eth_mdc
);
	wire clk_ad,clk_eth,clk_sdram;
	reg [7:0] da_data,eth_txd;
	reg [12:0] sdram_data;
	reg ad_pdwn,sdram_ba;

	pll180m i0(
		.inclk0(i_clk_sys1),
		.c0(o_clk_ad),
		.c1(clk_ad),
		.locked());
		
	assign o_da_data = da_data;
	always@(posedge clk_ad)
	begin
		da_data <= da_data + 1'b1;
	end
		
	pll125m i1(
		.inclk0(i_clk_sys2),
		.c0(o_eth_gtxclk),
		.c1(clk_eth),
		.locked());
		
	assign o_eth_txd = eth_txd;
	always@(posedge clk_eth)
	begin
		eth_txd <= eth_txd + 1'b1;
	end
		
	pll133m i2(
		.inclk0(i_clk_sys3),
		.c0(o_clk_sdram),
		.c1(clk_sdram),
		.locked());
		
	assign o_sdram_addr = sdram_data;
	always@(posedge clk_sdram)
	begin
		sdram_data <= sdram_data + 1'b1;
	end
	
	assign o_ad_pdwn = ad_pdwn;
	always@(posedge i_clk_sys)
		ad_pdwn <= ~ad_pdwn;
	
	assign o_sdram_ba = {sdram_ba,sdram_ba};
	always@(posedge i_eth_rxclk)
		sdram_ba <= ~sdram_ba;

endmodule



