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

	
	wire run,outmode,outnegedge;
	wire cmd_finish;
	wire [15:0] waveRawSize;
	wire [2:0] waveRate;
	wire [19:0] cycle;
	wire [11:0] pulse;
	wire [15:0] cmd_finish_code;
	wire outtrig,intrig;
	wire [15:0] outdelay,wavedaly;
	wire [7:0] gaindata;
	wire test;
	
	assign o_da_data = gaindata;
	
	reg [9:0] sinaddr;
	//sindata sin(sinaddr,i_clk50M,o_da_data);
	
	always@(posedge i_clk50M or negedge i_rst_n)
	if(!i_rst_n)
		sinaddr <= 0;
	else
		sinaddr <= sinaddr + 1'd1;
	
	cmdproc cmdproc_inst(
		.i_clk(clk_sys_100M),
		.i_rst_n(i_rst_n),
		.i_cmd_come(cmd_come),
		.i_cmd(cmd),				
		.i_cmd_param(cmd_param),
		.o_run(run),		
		.o_outmode(outmode),
		.o_outnegedge(outnegedge),
		.o_waveRawSize(waveRawSize),
		.o_waveRate(waveRate),
		.o_cycle(cycle),
		.o_pulse(pulse),
		.o_outdelay(outdelay),
		.o_wavedelay(wavedaly),
		.o_gaindata(gaindata),
		.o_test(test),
		.o_finish(cmd_finish),
		.o_finish_code(cmd_finish_code)
	);
	
	
	triger trig_inst(
		.i_clk100M(clk_sys_100M), 
		.rst_n(i_rst_n), 
		.en(run & !outmode),
		.cycle(cycle),	
		.q(intrig)
	);	
	
	outtriger ot(
		.i_clk100M(clk_sys_100M), 
		.i_rst_n(i_rst_n), 
		.i_outtrig(i_trig),
		.i_negedge(outnegedge),
		.i_delay(outdelay),		
		.o_trig_recv(outtrig)
	);

	trigwave tw(
		.i_clk100M(clk_sys_100M), 
		.i_rst_n(i_rst_n), 
		.i_trig(outmode ? outtrig : intrig),
		.i_delay(wavedaly),	
		.i_pulse(pulse),	
		.o_trig(o_trig)
	);
	
	reg [7:0] ii_ad_data;
	wire [15:0] ad_dual_data;
	wire ad_rd_empty;
	
	
	ad_wrapper ad_wrapper_inst (
		 .i_ad_clk(clk_ad_180M),
		 .i_rd_clk(clk_sys_100M),
		 .i_rst_n(i_rst_n),
		 .i_ad_data(test ? ii_ad_data : i_ad_data), 
		 .o_dual_data(ad_dual_data),
		 .i_st(intrig),
		 .i_isout(outmode),
		 .i_stout(outtrig),
		 .o_rd_empty(ad_rd_empty),
		 .o_ad_open(),
		 .i_recv_count(waveRawSize),
		 .o_working()
	);
	
	wire full;
	wire [11:0] nouse;
	wire [31:0] cmd_param;
	wire cmd_come;
	wire [15:0] cmd;
	
	assign o_led = cmd[3:0];
	
	
	usb uu(
		.i_rst_n(i_rst_n),
		.i_clk_sys(clk_sys_100M),
		.i_clk_usb(clk_usb_48M),
		.i_wr(!ad_rd_empty),
		.i_wr_data(ad_dual_data),
		.o_cmd(cmd),
		.o_cmd_come(cmd_come),
		.o_cmd_param(cmd_param),
		.i_cmd_finish(cmd_finish),
		.i_cmd_finish_code(cmd_finish_code),
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
	

	
	reg _trig,__trig;
	
	always@(posedge clk_ad_180M or negedge i_rst_n)
	if(!i_rst_n)
	begin
		ii_ad_data <= 0;
		_trig <= 0;
		__trig <= 0;
	end
	else
	begin
		__trig <= o_trig;
		_trig <= __trig;
		if(!_trig & __trig)
		begin
			ii_ad_data <= 8'd255;
		end
		else
			ii_ad_data <= (ii_ad_data == 8'd99) ? 0 : ii_ad_data + 1'd1;
	end
	
endmodule



