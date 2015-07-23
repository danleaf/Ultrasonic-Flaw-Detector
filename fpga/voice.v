module voice
(	
	input i_red,i_clk_sys50m,i_clk_ad9480,//i_rst_n,
	input [AD_DATA_WIDTH-1:0] i_ad_data,
	output o_ad9480_pdwn,
	output [6:0] o_num,
	output reg [AD_DATA_WIDTH-1:0] o_da_data,
	output [7:0] o_sel,
	output o_clk_ad25m,o_clk_da
);

	parameter AD_DATA_WIDTH = 8;

	wire clk_ad180m,clk_100m,clk_red_1us,clk_num_1ms,clk_500ms;
	wire [AD_DATA_WIDTH-1:0] ad_data;
	wire [AD_DATA_WIDTH*2-1:0] ad_dual_data;
	wire [31:0] red_data;
	wire red_intr,ad_open,ad_rd_empty;
		
	DIVCLK #(2) divclk3 (i_clk_sys50m, o_clk_ad25m);
	DIVCLK #(5) divclk4 (i_clk_sys50m, o_clk_da);
	DIVCLK #(50) divclk0 (i_clk_sys50m, clk_red_1us);
	DIVCLK #(50000) divclk1 (i_clk_sys50m, clk_num_1ms);
	DIVCLK #(25000000) divclk2 (i_clk_sys50m, clk_500ms);
	
	pll pll_ad(	
		.inclk0(i_clk_sys50m),
		.c0(clk_ad180m),
		.c1(clk_100m));
					
		
	RED_RECV redrecv(	
		.i_clk_1us(clk_red_1us),
		.i_red(i_red),
		.o_data(red_data),
		.o_intr(red_intr));

	
	ad_wrapper ad_wrapper_inst (
    .i_ad_clk(o_clk_ad25m),
	 .i_rd_clk(clk_100m),
	 .i_rst_n(1'b1),
    .i_ad_data(ad_data),   
    .o_dual_data(ad_dual_data),
	 .i_st(red_intr),
	 .i_auto(1'b0),
	 .i_stout(1'b0),
	 .o_rd_empty(ad_rd_empty),
	 .o_ad_open(ad_open),
	 .i_recv_count(16'd32));
	 
	 assign o_ad9480_pdwn = !ad_open;
	 
	 always@(posedge o_clk_da)
		o_da_data <= o_da_data + 1'b1;

		
	AD9260 adc_inst (
		.clk(o_clk_ad25m),
		.en(ad_open),
		.i_data(i_ad_data),
		.o_data(ad_data));
	
	
	wire [31:0] result;
	wire [AD_DATA_WIDTH*2-1:0] data;
	//wire [7:0] waddr_,raddr_;

	 
	fifo #(8,AD_DATA_WIDTH*2) buf_inst (
		.wclk(clk_100m),
		.rclk(clk_500ms),
		.rst(1'b1),
		.rreq(1'b1),
		.wreq(!ad_rd_empty),    
		.wdata(ad_dual_data),   
		.rdata(data)
		//,.waddr_(waddr_),
		//.raddr_(raddr_)
		);
		
		
	assign result = ad_dual_data[AD_DATA_WIDTH-1:0] * 10000 + ad_dual_data[AD_DATA_WIDTH*2-1:AD_DATA_WIDTH] * 1000000 +
						data[AD_DATA_WIDTH-1:0] + data[AD_DATA_WIDTH*2-1:AD_DATA_WIDTH] * 100;
						//waddr_ * 100 + raddr_;
						//ad_data;
	
	NUMSHOW show(clk_num_1ms, result, o_num, o_sel);
	
		

endmodule

	
	
