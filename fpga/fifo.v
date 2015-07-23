module fifo
 #(parameter ASIZE = 3,    
   parameter DSIZE = 32)    
(
    input wclk,rclk,rst,
    input rreq,wreq,    
    input [DSIZE-1:0] wdata,   
    output reg [DSIZE-1:0] rdata,
    output reg full,empty
	 //,output [ASIZE-1:0] waddr_,raddr_
);

	//assign waddr_ = waddr;
	//assign raddr_ = raddr;

	wire empty_next,empty_next1,empty_next2;
	wire [ASIZE:0] raddr_next,raddr_next_gray;
	reg [ASIZE:0] raddr,raddr_gray;
	reg [ASIZE:0] _waddr_gray_rclk,waddr_gray_rclk;
	
	wire full_next,full_next1,full_next2;
	wire [ASIZE:0] waddr_next,waddr_next_gray;
	reg [ASIZE:0] waddr,waddr_gray;
	reg [ASIZE:0] _raddr_gray_wclk,raddr_gray_wclk;
	
	wire [DSIZE-1:0] mem_o_data;
	
	assign waddr_next = waddr + 1'b1;
	assign waddr_next_gray = (waddr_next >> 1) ^ waddr_next;
	assign full_next1 = (waddr_next_gray == {~raddr_gray_wclk[ASIZE:ASIZE-1],raddr_gray_wclk[ASIZE-2:0]});
	assign full_next2 = (waddr_gray == {~raddr_gray_wclk[ASIZE:ASIZE-1],raddr_gray_wclk[ASIZE-2:0]});	
	assign full_next = (!full && wreq) ? full_next1 : full_next2;

	
	assign raddr_next = raddr + 1'b1;
	assign raddr_next_gray = (raddr_next >> 1'b1) ^ raddr_next;
	assign empty_next1 = (raddr_next_gray == waddr_gray_rclk);
	assign empty_next2 = (raddr_gray == waddr_gray_rclk);
	assign empty_next = (!empty && rreq) ? empty_next1 : empty_next2;
	
	wire we;
	
	assign we = !full && wreq;
	
	initial 
	begin
		waddr = 0;
		waddr_gray = 0;
		full = 0;
		_raddr_gray_wclk = 0;
		raddr_gray_wclk = 0;
		raddr = 0;
		rdata = 0;
		empty = 1;
		_waddr_gray_rclk = 0;
		waddr_gray_rclk = 0;
	end
	
	dualram #(ASIZE,DSIZE) mem(
		.i_we(we),
		.i_clk(wclk),
		.i_wr_addr(waddr[ASIZE-1:0]),
		.i_rd_addr(raddr[ASIZE-1:0]),
		.i_data(wdata),
		.o_data(mem_o_data)
	);

	
	always@(posedge wclk or negedge rst)
	if(!rst)
	begin
		waddr <= 0;
		waddr_gray <= 0;
		full <= 0;
		_raddr_gray_wclk <= 0;
		raddr_gray_wclk <= 0;
	end
	else
	begin
		if(!full && wreq)
		begin
			waddr <= waddr_next;
			waddr_gray <= waddr_next_gray;
		end
		
		full <= full_next;
		{raddr_gray_wclk, _raddr_gray_wclk} <= {_raddr_gray_wclk, raddr_gray};
	end
	

		
	always@(posedge rclk or negedge rst)
	begin
		if(!rst)
		begin
			raddr <= 0;
			rdata <= 0;
			empty <= 1;
			_waddr_gray_rclk <= 0;
			waddr_gray_rclk <= 0;
			raddr_gray <= 0;
		end
		else
		begin
			if(!empty && rreq)
			begin
				raddr <= raddr_next;
				raddr_gray <= raddr_next_gray;
				rdata <= mem_o_data;
			end
			
			empty <= empty_next;
			{waddr_gray_rclk, _waddr_gray_rclk} <= {_waddr_gray_rclk, waddr_gray};
		end
	end

endmodule


