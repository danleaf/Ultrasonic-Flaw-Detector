`timescale 1ns/1ps

module testusb
(
	output [15:0] o_usb_data,
	output o_usb_addr0,
	output o_usb_addr1,
	output o_usb_slcs,
	output o_usb_sloe,
	output o_usb_slrd,
	output o_usb_slwr,
	output o_usb_slpked
);
	
	reg i_rst_n,i_trig;
	reg i_usb_flagb;
	
	reg clk_sys_100M;
	reg clk_ad_180M;
	reg clk_usb_48M;
	
	initial
	begin
		i_rst_n = 'd1;
		i_trig = 0;
		i_usb_flagb = 'd1;
		clk_sys_100M = 'd1;
		clk_ad_180M = 'd1;
		clk_usb_48M = 'd1;
		#10 i_rst_n = 0;
		#10 i_rst_n = 'd1;
	end
	
	
	always #5 clk_sys_100M = ~clk_sys_100M;
	always #2.778 clk_ad_180M = ~clk_ad_180M;
	always #10 clk_usb_48M = ~clk_usb_48M;

	reg [15:0] cnt1,cnt2;
	always@(posedge clk_usb_48M or negedge i_rst_n)
	if(!i_rst_n)
	begin
		cnt1 <= 0;
		cnt2 <= 0;
		i_trig <= 0;
	end
	else
	begin
		cnt1 <= cnt1 + 'd1;
		cnt2 <= (cnt2==1023) ? 0 : cnt2 + 'd1;
		if(cnt1 == 16'd4)
			i_trig <= 1'd1;
		if(cnt1 == 16'd16)
			i_trig <= 0;
			
		if(cnt2 == 'd511)
		  i_usb_flagb <= 'd0;
		if(cnt2 == 'd1023)
		  i_usb_flagb <= 'd1;
	end
	
	
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
		_trig <= i_trig;
		if(!_trig & i_trig)
		begin
			ii_ad_data <= 'd251;
			trigcnt <= (trigcnt == 2'd1) ? 2'd1 : trigcnt + 2'd1;
		end
		else
			ii_ad_data <= (ii_ad_data == 8'd199) ? 0 : ii_ad_data + 1'd1;
			
	end
	
	ad_wrapper ad_wrapper_inst (
		 .i_ad_clk(clk_ad_180M),
		 .i_rd_clk(clk_sys_100M),
		 .i_rst_n(i_rst_n),
		 .i_ad_data(ii_ad_data),	 
		 .o_dual_data(ad_dual_data),
		 .i_st(i_trig),
		 .i_auto(1'b0),
		 .i_stout(1'b0),
		 .o_rd_empty(ad_rd_empty),
		 .o_ad_open(),
		 .i_recv_count(16'd4000),
		 .o_working()
	);
	
	usb uu(
		.i_rst_n(i_rst_n),
		.i_clk_sys(clk_sys_100M),
		.i_clk_usb(clk_usb_48M),
		.i_wr(!ad_rd_empty),
		.i_data(ad_dual_data),
		.i_flagb(i_usb_flagb),
		.o_data(o_usb_data),
		.o_addr0(o_usb_addr0),
		.o_addr1(o_usb_addr1),
		.o_slcs(o_usb_slcs),
		.o_sloe(o_usb_sloe),
		.o_slrd(o_usb_slrd),
		.o_slwr(o_usb_slwr),
		.o_slpked(o_usb_slpked)
	);

endmodule



