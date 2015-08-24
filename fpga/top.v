module top
(
	input i_rst_n,
	input i_clk50M,
	input i_clk48M,
	input i_trig,
	output o_trig,
	
	input [7:0] i_ad_data,
	
	output o_eth_rst,
	output o_eth_gtxclk,
	output o_eth_txen,
	output [7:0] o_eth_txd,
	input i_eth_rxclk,
	input i_eth_rxdv,
	input [7:0] i_eth_rxd
);
	
	wire eth_gtxclk;
	wire clk_ad_180M = i_clk50M;
	wire clk_sys_100M = i_clk50M;
	reg clk_100K;
	
	pll125m  plleth(i_clk50M, o_eth_gtxclk, eth_gtxclk);
	
	reg [8:0] cnt100K;
	always@(posedge i_clk50M or negedge i_rst_n)
	if(!i_rst_n)
	begin
		clk_100K <= 1'd1;
		cnt100K <= 0;
	end
	else
	begin
		cnt100K <= (cnt100K == 9'd499) ? 0 :cnt100K + 1'd1;
		if(cnt100K == 0)
			clk_100K <= 1'd0;
		if(cnt100K == 9'd250)
			clk_100K <= 1'd1;
	end	
	
	phy_reset phyrst(
	.clk(eth_gtxclk),
	.rst(i_rst_n),
	.phy_rst(o_eth_rst));
	
	
	wire [31:0] cmd_param;
	wire cmd_come,cmd_finish;
	wire [15:0] cmd,cmd_finish_code;
	
	wire run,outmode,outnegedge;
	wire [15:0] waveRawSize;
	wire [2:0] waveRate;
	wire [19:0] cycle;
	wire [11:0] pulse;
	wire outtrig,intrig;
	wire [15:0] outdelay,wavedaly;
	wire [7:0] gaindata;
	wire test;
	
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
		.i_clk100M(clk_100K), 
		.rst_n(i_rst_n), 
		.en(run & !outmode),
		.cycle(20'd200000),	
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
	wire working;
	
	
	ad_wrapper ad_wrapper_inst (
		 .i_ad_clk(clk_ad_180M),
		 .i_rd_clk(eth_gtxclk),
		 .i_rst_n(i_rst_n),
		 .i_ad_data(test ? ii_ad_data : i_ad_data), 
		 .o_dual_data(ad_dual_data),
		 .i_st(intrig),
		 .i_isout(outmode),
		 .i_stout(outtrig),
		 .o_rd_empty(ad_rd_empty),
		 .o_ad_open(),
		 .i_recv_count(waveRawSize),
		 .o_working(working)
	);
	
	reg ethwr,st,_st;
	reg [15:0] ethwrcnt;
	always@(posedge eth_gtxclk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		ethwr <= 0;
		ethwrcnt <= 0;
		st <= 1'd1;
		_st <= 1'd1;
	end
	else
	begin
		{st,_st} <= {_st,outmode?outtrig:intrig};
		if(!ethwr & !st & _st)
		begin
			ethwr <= 1'd1;
			ethwrcnt <= 0;
		end
		else if(ethwr & !ad_rd_empty)
			ethwrcnt <= ethwrcnt + 2'd2;
			
		if(ethwr & ethwrcnt == waveRawSize)
			ethwr <= 0;
	end
	
	eth_session i(
		.i_clk(eth_gtxclk),
		.i_rst_n(i_rst_n),
		.i_data(ad_dual_data[7:0]),
		.i_wr(ethwr),
		.i_din(!ad_rd_empty),
		.o_full(),
		.o_cmd_come(cmd_come),
		.o_cmd(cmd),
		.o_param(cmd_param),
		.i_cmd_finish(cmd_finish),
		.i_cmd_finish_code(cmd_finish_code),
	
		.o_eth_txen(o_eth_txen),
		.o_eth_txd(o_eth_txd),
		.i_eth_rxclk(i_eth_rxclk),
		.i_eth_rxdv(i_eth_rxdv),
		.i_eth_rxd(i_eth_rxd)
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
			ii_ad_data <= 0;
		end
		else
			ii_ad_data <= (ii_ad_data == 8'd199) ? 0 : ii_ad_data + 1'd1;
	end

endmodule



