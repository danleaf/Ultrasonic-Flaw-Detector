module sdram
#(
	parameter BANK_WIDTH = 2,
	parameter ROW_WIDTH = 13,
	parameter COL_WIDTH = 9,
	parameter DATA_WIDTH = 16
)
(
	input i_clk,i_rst_n,i_wr_cache,
	input [1:0] i_cmd,
	input [ROW_WIDTH+BANK_WIDTH+COL_WIDTH-1:0] i_addr,
	input [ROW_WIDTH+BANK_WIDTH+COL_WIDTH-1:0] i_count,
	inout [DATA_WIDTH-1:0] io_data,
	output o_busy,
	
	//connect with SDRAM chip
	output [BANK_WIDTH-1:0] o_sdram_ba,
	output [ROW_WIDTH-1:0] o_sdram_addr,
	inout [DATA_WIDTH-1:0] io_sdram_data,
	output o_sdram_clk,
	output o_sdram_udqm,
	output o_sdram_ldqm,
	output o_sdram_ras,
	output o_sdram_cas,
	output o_sdram_we,
	output o_sdram_cke,
	output o_sdram_cs
);

	

endmodule
