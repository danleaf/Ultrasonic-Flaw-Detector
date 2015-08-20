module dualram			//读地址立即起效，用寄存器实现，容量不能大，大了编译慢，太大编译不过
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

module dualram_rdreg				//读地址打一拍，用sram模块实现，适合较大容量
 #(parameter ASIZE = 13,    
   parameter DSIZE = 8)  
(
	clock,
	data,
	rdaddress,
	wraddress,
	wren,
	q);

	input	clock;
	input	[DSIZE-1:0]  data;
	input	[ASIZE-1:0]  rdaddress;
	input	[ASIZE-1:0]  wraddress;
	input	 wren;
	output [DSIZE-1:0]  q;
	
	localparam RAMDEPTH = 1 << ASIZE;

	reg [DSIZE-1:0] mem [RAMDEPTH-1:0];
	reg [ASIZE-1:0]  rdaddr;
	
	assign q = mem[rdaddr];
	
	always@(posedge clock)
	begin
		if(wren)
		  mem[wraddress] <= data;
	rdaddr <= rdaddress;
	end
	

endmodule

