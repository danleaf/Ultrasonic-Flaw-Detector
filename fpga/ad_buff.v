module ad_buff
#(
	parameter DSIZE = 8,
	parameter DATA_DELAY_CLKS = 0//4'd8
)
(	
    input i_ad_clk,i_st,i_rst_n,
    input [DSIZE-1:0] i_ad_data,
	 input [15:0] i_recv_count,
    output [DSIZE*2-1:0] o_dual_data,
	 output o_data_on,
	 output o_working
);	

	localparam ODSIZE = DSIZE*2;
	
	reg [15:0] cnt;
	reg st,working,ready,data_on;
	reg [ODSIZE-1:0] dual_data;
	
	assign o_dual_data = dual_data;
	assign o_data_on = data_on;
	assign o_working = working;
	
	always@(posedge i_ad_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		st <= 1'd1;
		working <= 0;
	end
	else
	begin
		st <= i_st;
		if(i_st && !st)
			working <= 1;
		if(cnt == i_recv_count + DATA_DELAY_CLKS)
			working <= 0;
	end
	
	always@(posedge i_ad_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		cnt <= 0;
		dual_data <= 0;
	end
	else
	begin
		if(working)
		begin
			cnt <= cnt + 1'b1;
			dual_data <= {i_ad_data,dual_data[ODSIZE-1:DSIZE]};
		end
		else
			cnt <= 0;
	end
	
	always@(posedge i_ad_clk or negedge i_rst_n)
	if(!i_rst_n)
		ready <= 0;
	else
	begin
		if(working)
		begin
			if(cnt == DATA_DELAY_CLKS + 1'b1)
				ready <= 1;
		end
		else
			ready <= 0;
	end
	
	always@(posedge i_ad_clk or negedge i_rst_n)
	if(!i_rst_n)
		data_on <= 0;
	else
	begin
		if(ready)
			data_on <= ~data_on;
		else
			data_on <= 0;
	end
	
	
endmodule
