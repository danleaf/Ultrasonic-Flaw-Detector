module GrayCounter4Bit
 #(parameter ASIZE = 3)
(
	input req,clk,full_now,
	input [ASIZE:0] raddr_gray_wclk,waddr_now,waddr_now_gray,
	//output [ASIZE:0] waddr_next,waddr_next_gray
	output full_next
);

	wire full_next1,full_next2;
	
	assign waddr_next = waddr_now + 1'b1;
	assign waddr_next_gray = (waddr_next>>1)^waddr_next;
	assign full_next1 = (waddr_next_gray == {~raddr_gray_wclk[ASIZE:ASIZE-1],raddr_gray_wclk[ASIZE-2:0]});
	assign full_next2 = (waddr_now_gray == {~raddr_gray_wclk[ASIZE:ASIZE-1],raddr_gray_wclk[ASIZE-2:0]});
	
	assign full_next = (!full_now || req) ? full_next1 : full_next2;
	
	
	
endmodule

