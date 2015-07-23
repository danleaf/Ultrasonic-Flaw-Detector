module AD_FIFO
#(
   parameter DSIZE = 10,
	parameter ASIZE = 4
)    
(
    input wclk,rclk,rst,
    input rreq,wreq,    
    input [DSIZE-1:0] wdata,   
    output reg [MDSIZE-1:0] rdata,
    output reg empty
);
	localparam MDSIZE = DSIZE*2;
	localparam RAMDEPTH = 1 << ASIZE;
	
	wire [ASIZE:0] raddr_next, waddr_next;
	wire [ASIZE:0] raddr_next_gray, waddr_next_gray;
	wire full_next,empty_next;
	
	reg [ASIZE:0] raddr,waddr,full;
	reg [ASIZE:0] raddr_gray,waddr_gray;
	reg [ASIZE:0] _raddr_gray_wclk, _waddr_gray_rclk;
	reg [ASIZE:0] raddr_gray_wclk, waddr_gray_rclk;

	reg [MDSIZE-1:0] mem [RAMDEPTH-1:0];
	reg [DSIZE-1:0] tmp;
	reg sig;
	
	AD_FIFO_WADDRPROC #(ASIZE) waddrproc(
		.req(wreq),
		.full_now(full),
		.waddr_now(waddr),
		.waddr_now_gray(waddr_gray),
		.raddr_gray_wclk(raddr_gray_wclk),
		.waddr_next(waddr_next),
		.waddr_next_gray(waddr_next_gray),
		.full_next(full_next));
	
	AD_FIFO_RADDRPROC #(ASIZE) raddrproc(
		.req(rreq),
		.empty_now(empty),
		.raddr_now(raddr),
		.waddr_gray_rclk(waddr_gray_rclk),
		.raddr_next(raddr_next),
		.raddr_next_gray(raddr_next_gray),
		.empty_next(empty_next));
	
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
		if(sig)
		begin
			waddr <= waddr_next;
			full <= full_next;
			waddr_gray <= waddr_next_gray;
			if(wreq && !full)
				mem[waddr[ASIZE-1:0]] <= {tmp,wdata};
			{raddr_gray_wclk, _raddr_gray_wclk} <= {_raddr_gray_wclk, raddr_gray};
		end
	end
	
	
	always@(posedge wclk or negedge rst)
	if(!rst)
	begin
		sig <= 0;
		tmp <= 0;
	end
	else
	begin
		sig <= wreq ? ~sig : 1'b0;	
		tmp <= wreq ? wdata : {DSIZE{1'bx}};
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
		end
		else
		begin
			raddr <= raddr_next;
			empty <= empty_next;
			raddr_gray <= raddr_next_gray;
			if(rreq && !empty)
			begin
				rdata <= mem[raddr[ASIZE-1:0]];
			end
			
			{waddr_gray_rclk, _waddr_gray_rclk} <= {_waddr_gray_rclk, waddr_gray};
		end
	end

endmodule

module AD_FIFO_WADDRPROC
 #(parameter ASIZE = 3)
(
	input req,full_now,
	input [ASIZE:0] waddr_now,waddr_now_gray,raddr_gray_wclk,
	output [ASIZE:0] waddr_next,waddr_next_gray,
	output full_next
);

	wire [ASIZE:0] next_gray;
	
	BinNext2Gray #(ASIZE+1) bin2gray(waddr_now, next_gray);
	
	assign waddr_next = full_now ? waddr_now : waddr_now + req;
	assign waddr_next_gray = (waddr_next >> 1'b1) ^ waddr_next;
	assign full_next = (waddr_next_gray == {~raddr_gray_wclk[ASIZE:ASIZE-1],raddr_gray_wclk[ASIZE-2:0]});
	
endmodule

module AD_FIFO_RADDRPROC
 #(parameter ASIZE = 3)
(
	input req,empty_now,
	input [ASIZE:0] raddr_now,waddr_gray_rclk,
	output [ASIZE:0] raddr_next,raddr_next_gray,
	output empty_next
);
	
	assign raddr_next = empty_now ? raddr_now : raddr_now + req;
	assign raddr_next_gray = (raddr_next >> 1'b1) ^ raddr_next;
	assign empty_next = (raddr_next_gray == waddr_gray_rclk);
	
endmodule
