module indififo
 #(parameter DSIZE = 32)    
(
    input i_wr_clk,i_rd_clk,i_rst_n,
    input i_wr_req,
    input [DSIZE-1:0] i_wr_data,   
    output reg [DSIZE-1:0] o_rd_data,
    output reg o_empty
);
	localparam ASIZE = 3;

	wire empty_next,empty_next1,empty_next2;
	wire [ASIZE:0] raddr_next,raddr_next_gray;
	reg [ASIZE:0] raddr,raddr_gray;
	reg [ASIZE:0] _waddr_gray_rclk,waddr_gray_rclk;
	
	wire [ASIZE:0] waddr_next,waddr_next_gray;
	reg [ASIZE:0] waddr,waddr_gray;
	
	reg empty;
	
	wire [DSIZE-1:0] mem_o_data;
	
	initial
	begin
		waddr = 0;
		waddr_gray = 0;
		raddr = 0;
		o_rd_data = 0;
		o_empty = 1;
		empty = 1;
		_waddr_gray_rclk = 0;
		waddr_gray_rclk = 0;
	end
	
	assign waddr_next = waddr + 1'b1;
	assign waddr_next_gray = (waddr_next >> 1) ^ waddr_next;

	
	assign raddr_next = raddr + 1'b1;
	assign raddr_next_gray = (raddr_next >> 1'b1) ^ raddr_next;
	assign empty_next1 = (raddr_next_gray == waddr_gray_rclk);
	assign empty_next2 = (raddr_gray == waddr_gray_rclk);
	assign empty_next = !empty ? empty_next1 : empty_next2;
	
	dualram #(ASIZE,DSIZE) mem(
		.i_we(i_wr_req),
		.i_clk(i_wr_clk),
		.i_wr_addr(waddr[ASIZE-1:0]),
		.i_rd_addr(raddr[ASIZE-1:0]),
		.i_data(i_wr_data),
		.o_data(mem_o_data)
	);

	
	always@(posedge i_wr_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		waddr <= 0;
		waddr_gray <= 0;
	end
	else
	begin
		if(i_wr_req)
		begin
			waddr <= waddr_next;
			waddr_gray <= waddr_next_gray;
		end
	end
	

		
	always@(posedge i_rd_clk or negedge i_rst_n)
	begin
		if(!i_rst_n)
		begin
			raddr <= 0;
			o_rd_data <= 0;
			o_empty <= 1;
			empty <= 1;
			raddr_gray <= 0;
			_waddr_gray_rclk <= 0;
			waddr_gray_rclk <= 0;
		end
		else
		begin
			if(!empty)
			begin
				raddr <= raddr_next;
				raddr_gray <= raddr_next_gray;
				o_rd_data <= mem_o_data;
			end
			
			empty <= empty_next;
			o_empty <= empty;
			{waddr_gray_rclk, _waddr_gray_rclk} <= {_waddr_gray_rclk, waddr_gray};
		end
	end

endmodule


