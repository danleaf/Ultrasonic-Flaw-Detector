module top0
(
	input i_rst_n,i_trig,
	input i_clk40M,i_clk50M,
	
	output o_clk_da,
	output o_trig,
	output [3:0] o_led, 
	output [7:0] o_da_data,
	
	output o_clk_ad,
	input [7:0] i_ad_data,
	
	input i_usb_flagb,i_usb_flagc,
	inout [15:0] io_usb_data,
	output o_usb_addr0,
	output o_usb_addr1,
	output o_usb_ifclk,
	output o_usb_slcs,
	output o_usb_sloe,
	output o_usb_slrd,
	output o_usb_slwr,
	output o_usb_slpked
);
	
	wire clk_sys_100M;
	wire clk_ad_180M;
	wire clk_usb_48M;

	plladusb1 i0(
		.inclk0(i_clk50M),
		.c0(clk_ad_180M),
		.c1(clk_sys_100M)
	);
	
	plladusb2 i1(
		.inclk0(i_clk40M),
		.c0(clk_usb_48M)
	);
	
	assign o_usb_ifclk	= clk_usb_48M;
	assign o_clk_ad		= clk_ad_180M;
	assign o_clk_da 		= i_clk50M;

	wire trig;
	triger trig_inst(
		.clk(i_clk50M), 
		.rst_n(i_rst_n), 
		.q(trig), 
		.q2(o_trig),
		.led(/*o_led*/),
		.dac_data(o_da_data)
	);	
	
	wire [15:0] ad_dual_data;
	wire ad_rd_empty;
	
	reg [7:0] ii_ad_data;
	reg [1:0] trigcnt;
	reg _trig;
	
	always@(posedge clk_ad_180M or negedge i_rst_n)
	if(!i_rst_n)
	begin
		ii_ad_data <= 0;
		_trig <= 0;
		trigcnt <= 0;
	end
	else
	begin
		_trig <= o_trig;
		if(!_trig & o_trig)
		begin
			ii_ad_data <= 'd251;
			trigcnt <= (trigcnt == 'd1) ? 'd1 : trigcnt + 1'd1;
		end
		else
			ii_ad_data <= (ii_ad_data == 'd10) ? 0 : ii_ad_data + 1'd1;
	end
	
	
	ad_wrapper ad_wrapper_inst (
		 .i_ad_clk(clk_ad_180M),
		 .i_rd_clk(clk_sys_100M),
		 .i_rst_n(i_rst_n),
		 .i_ad_data(i_ad_data), 
		 //.i_ad_data(ii_ad_data),	 
		 .o_dual_data(ad_dual_data),
		 .i_st(trig),
		 .i_auto(1'b0),
		 .i_stout(1'b0),
		 .o_rd_empty(ad_rd_empty),
		 .o_ad_open(),
		 .i_recv_count(16'd512),
		 .o_working()
	);
	
	wire full;
	wire [3:0] nouse;
	wire [31:0] param;
	
	
	usb uu(
		.i_rst_n(i_rst_n),
		.i_clk_sys(clk_sys_100M),
		.i_clk_usb(clk_usb_48M),
		.i_wr(!ad_rd_empty),
		.i_wr_data(ad_dual_data),
		.o_cmd_come(),
		.o_cmd({nouse,o_led}),
		.o_cmd_param(param),
		.o_full(),
		.i_flagb(i_usb_flagb),
		.i_flagc(i_usb_flagc),
		.io_data(io_usb_data),
		.o_addr0(o_usb_addr0),
		.o_addr1(o_usb_addr1),
		.o_slcs(o_usb_slcs),
		.o_sloe(o_usb_sloe),
		.o_slrd(o_usb_slrd),
		.o_slwr(o_usb_slwr),
		.o_slpked(o_usb_slpked)
	);
	
	

endmodule



