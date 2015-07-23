module dualram
 #(parameter ASIZE = 3,    
   parameter DSIZE = 8)    
(
	input i_we,i_clk,
	input [ASIZE-1:0] i_wr_addr,i_rd_addr,
	input [DSIZE-1:0] i_data,
	output [DSIZE-1:0] o_data
);
	localparam RAMDEPTH = 1 << ASIZE;

	reg [DSIZE-1:0] mem [RAMDEPTH-1:0];

	assign o_data = mem[i_rd_addr];

	always@(posedge i_clk)
	if(i_we)
		mem[i_wr_addr] <= i_data;

endmodule

module dualram8
 #(parameter DSIZE = 8)    
(
	input i_we,i_clk,
	input [2:0] i_wr_addr,i_rd_addr,
	input [DSIZE-1:0] i_data,
	output [DSIZE-1:0] o_data
);

	reg [DSIZE-1:0] mem [7:0];

	assign o_data = mem[i_rd_addr];

	always@(posedge i_clk)
	if(i_we)
		case(i_wr_addr)
		3'd1:	mem[1] <= i_data;
		3'd2:	mem[2] <= i_data;
		3'd3:	mem[3] <= i_data;
		3'd4:	mem[4] <= i_data;
		3'd5:	mem[5] <= i_data;
		3'd6:	mem[6] <= i_data;
		3'd7:	mem[7] <= i_data;
		default:	mem[0] <= i_data;
		endcase

endmodule

module altdualram0 (
	clock,
	data,
	rdaddress,
	wraddress,
	wren,
	q);

	input	  clock;
	input	[7:0]  data;
	input	[12:0]  rdaddress;
	input	[12:0]  wraddress;
	input	  wren;
	output	[7:0]  q;
	
	reg [7:0] mem [0:8191];
	
	assign q = mem[rdaddress];
	
	always@(posedge clock)
	if(wren)
	  mem[wraddress] <= data;
	

endmodule
