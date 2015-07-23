`timescale 1ns/1ps

module test();
  
	reg clk,rst_n,wr,clkrx;
	reg [15:0] data;
	reg [10:0] cnt;
	reg sig;
	reg [7:0] arp [0:41];
	reg [7:0] setip [0:47];
	reg [7:0] setserver [0:47];
  
	reg [7:0] rxd;
	reg rxdv;
	reg [5:0] rxidx;
  
	wire cmd_come;
	wire [7:0] cmd;
	wire [31:0]  param;
	wire [7:0] d;
	wire o_eth_txen;
	wire [7:0] o_eth_txd;

  
	initial
	begin
		clk = 0;
		clkrx = 1;
		rst_n = 1'd1;
		cnt = 0;
		wr = 0;
		#1 rst_n = 0;
		#8 rst_n = 1'd1;
	end
  
  
	always #4 clk = ~clk;
	always #4 clkrx = ~clkrx;
  
	always@(posedge clk or negedge rst_n)
	if(!rst_n)
		begin
			cnt <= 0;
			data <= 0;
			sig <= 0;
			wr <= 0;
			rxdv <= 0;
			rxidx <= 0;
			
			{arp[0],arp[1],arp[2],arp[3],arp[4],arp[5]} <= 48'h_FF_FF_FF_FF_FF_FF;
			{arp[6],arp[7],arp[8],arp[9],arp[10],arp[11]} <= 48'h_02_03_04_05_04_05;
			{arp[12],arp[13]} <= 16'h0806;
			{arp[14],arp[15]} <= 16'h1;
			{arp[16],arp[17]} <= 16'h0800;
			{arp[18],arp[19]} <= 16'h0604;
			{arp[20],arp[21]} <= 16'h1;
			{arp[22],arp[23],arp[24],arp[25],arp[26],arp[27]} <= 48'h_02_03_04_05_04_05;
			{arp[28],arp[29],arp[30],arp[31]} <= 32'h_C0_A8_01_05;
			{arp[32],arp[33],arp[34],arp[35],arp[36],arp[37]} <= 48'h0;
			{arp[38],arp[39],arp[40],arp[41]} <= 32'h_C0_A8_01_04;
			
			{setip[0],setip[1],setip[2],setip[3],setip[4],setip[5]} <= 48'h_02_00_00_00_00_04;
			{setip[6],setip[7],setip[8],setip[9],setip[10],setip[11]} <= 48'h_02_00_00_00_00_05;
			{setip[12],setip[13]} <= 16'h0800;
			{setip[14],setip[15],setip[16],setip[17]} <= {8'h54,8'd0,8'd0,8'd34};
			{setip[18],setip[19],setip[20],setip[21]} <= 0;
			{setip[22],setip[23],setip[24],setip[25]} <= {8'd255,8'd17,8'hD6,8'h8E};
			{setip[26],setip[27],setip[28],setip[29]} <= 32'h_C0_A8_01_05;
			{setip[30],setip[31],setip[32],setip[33]} <= 32'h_C0_A8_01_04;
			{setip[34],setip[35],setip[36],setip[37]} <= {16'hFEEF,16'hFEEF};
			{setip[38],setip[39],setip[40],setip[41]} <= {8'd0,8'd14,16'd0};
			{setip[42],setip[43],setip[44],setip[45],setip[46],setip[47]} <= {8'd1,8'd254,32'h_C0_A8_01_AA};
			
			{setserver[0],setserver[1],setserver[2],setserver[3],setserver[4],setserver[5]} <= 48'h_02_00_00_00_00_04;
			{setserver[6],setserver[7],setserver[8],setserver[9],setserver[10],setserver[11]} <= 48'h_22_00_00_00_00_55;
			{setserver[12],setserver[13]} <= 16'h0800;
			{setserver[14],setserver[15],setserver[16],setserver[17]} <= {8'h54,8'd0,8'd0,8'd34};
			{setserver[18],setserver[19],setserver[20],setserver[21]} <= 0;
			{setserver[22],setserver[23],setserver[24],setserver[25]} <= {8'd255,8'd17,8'hD6,8'h8E};
			{setserver[26],setserver[27],setserver[28],setserver[29]} <= 32'h_C0_A8_01_BB;
			{setserver[30],setserver[31],setserver[32],setserver[33]} <= 32'h_C0_A8_01_AA;
			{setserver[34],setserver[35],setserver[36],setserver[37]} <= {16'hFEEF,16'hFEEF};
			{setserver[38],setserver[39],setserver[40],setserver[41]} <= {8'd0,8'd14,16'd0};
			{setserver[42],setserver[43],setserver[44],setserver[45],setserver[46],setserver[47]} <= {8'd0,8'd255,32'h0};
		end
	else
	begin
		sig <= ~sig;
		cnt <= (cnt!=11'd2047) ? cnt + 1'd1 : 11'd2047;   
		if(sig) data <= data + 1'd1;    
		if(cnt >= 11'd102 && cnt <= 11'd195)  
			wr <= 1'd1;    
		else    
			wr <= 0;
			
		if(cnt >= 11'd2 && cnt <= 11'd49)
		begin
			rxdv <= 1'd1;
			rxidx <= rxidx + 1'd1;
			rxd <= setip[rxidx];
		end
		else if(cnt >= 11'd51 && cnt <= 11'd98)
		begin
			rxdv <= 1'd1;
			rxidx <= rxidx + 1'd1;
			rxd <= setserver[rxidx];
		end
		else if(cnt >= 11'd100 && cnt <= 11'd141)
		begin
			rxdv <= 1'd1;
			rxidx <= rxidx + 1'd1;
			rxd <= arp[rxidx];
		end
		else
		begin
			rxidx <= 0;
			rxdv <= 0;
		end
	end
	
	assign d = sig ? data[15:8] : data[7:0];
	
	eth_session i
	(
		.i_clk(clk),
		.i_rst_n(rst_n),
		.i_data(d),
		.i_wr(wr),
		.i_din(1'd1),
		.o_full(),
		.o_cmd_come(cmd_come),
		.o_cmd(cmd),
		.o_param(param),
	
		.o_eth_txen(o_eth_txen),
		.o_eth_txd(o_eth_txd),
		.io_eth_mdio(),
		.o_eth_mdc(),
		.o_eth_txer(),
		.i_eth_rxclk(clkrx),
		.i_eth_rxdv(rxdv),
		.i_eth_rxer(),
		.i_eth_rxd(rxd),
		.i_eth_crs(),
		.i_eth_col()
		
		//.io_eth_mdio(io_eth_mdio),
		//.o_eth_mdc(o_eth_mdc),
		//.o_eth_txer(o_eth_txer),
		//.i_eth_rxclk(i_eth_rxclk),
		//.i_eth_rxdv(i_eth_rxdv),
		//.i_eth_rxer(i_eth_rxer),
		//.i_eth_rxd(i_eth_rxd),
		//.i_eth_crs(i_eth_crs),
		//.i_eth_col(i_eth_col)
	);
		
endmodule
