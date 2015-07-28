module ad_wrapper
#(
	parameter AD_DATA_SIZE = 8
)
(	
    input i_ad_clk,i_rd_clk,i_rst_n,
	 input i_st,i_isout,i_stout,   
	 input [15:0] i_recv_count,
    input [AD_DATA_SIZE-1:0] i_ad_data,
    output [AD_DATA_SIZE*2-1:0] o_dual_data,
	 output o_rd_empty,o_working,
	 output reg o_ad_open
);	
	localparam OUT_DATA_SIZE = AD_DATA_SIZE*2;
	localparam ST_IDEL = 4'b0;
	localparam ST_START = 4'b1;
	localparam ST_COLLECT = 4'b10;
	localparam ST_END = 4'b100;
	
	wire [OUT_DATA_SIZE-1:0] buffer;
	wire start,we_fifo,working;
	reg st0,st1,st,working0;
	
	assign start = i_isout ? i_stout : i_st;
	assign o_working = working;
	
	initial
	begin
		st0 = 0;
		st1 = 0;
		st = 0;
	end
	
	always@(posedge i_ad_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		{st0,st1,st} <= 3'b000;
		o_ad_open <= 0;
	end
	else
	begin
		{st0,st1} <= {start,st0};
		working0 <= working;
		if(st0 && !st1)
			o_ad_open <= 1'b1;
		if(o_ad_open)
			st <= 1'b1;
		if(working0 && !working)
			{o_ad_open,st} <= 2'b0;
	end
	
	ad_buff ad_buff_inst(
		.i_ad_clk(i_ad_clk),
		.i_st(st),
		.i_rst_n(i_rst_n),
		.i_recv_count(i_recv_count),
		.o_dual_data(buffer),
		.o_data_on(we_fifo),
		.o_working(working),
		.i_ad_data(i_ad_data));
	
	indififo #(OUT_DATA_SIZE) fifo_inst(
    .i_wr_clk(i_ad_clk),
	 .i_rd_clk(i_rd_clk),
	 .i_rst_n(i_rst_n),
	 .i_wr_req(we_fifo),    
    .i_wr_data(buffer),   
    .o_rd_data(o_dual_data),
	 .o_empty(o_rd_empty));

endmodule 
