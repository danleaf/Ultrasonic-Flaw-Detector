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
	 output o_rd_empty,
	 output reg o_reading,		//从触发开始到一个波形读取完毕之间一直为1，其余为0
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
	
	initial
	begin
		st0 = 1'b1;
		st1 = 1'b1;
		st = 0;
	end
	
	always@(posedge i_ad_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		st <= 0;
		{st0,st1} <= 2'b11;
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
	 
	
	reg stt,_stt;
	reg [15:0] rdcnt;
	always@(posedge i_rd_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		o_reading <= 0;
		rdcnt <= 0;
		stt <= 1'd1;
		_stt <= 1'd1;
	end
	else
	begin
		{stt,_stt} <= {_stt, start};
		if(!o_reading & !stt & _stt)
		begin
			o_reading <= 1'd1;
			rdcnt <= 0;
		end
		else if(o_reading & !o_rd_empty)
			rdcnt <= rdcnt + 2'd2;			//每周期读2个字节
			
		if(o_reading & rdcnt == i_recv_count)
			o_reading <= 0;
	end

endmodule 
