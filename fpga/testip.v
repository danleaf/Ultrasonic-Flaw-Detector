
`timescale 1ns/1ps

module test();
  
  reg eth_gtxclk,rst_n;
  reg intrig;
  
  initial
  begin
    eth_gtxclk = 0;
    rst_n = 1'b1;
    intrig = 0;
    #1 rst_n = 0;
    #7 rst_n = 1'b1;
    #22 intrig = 1'b1;
  end

  always #4 eth_gtxclk = ~eth_gtxclk;

	
	reg _intrig,wr;
	reg [7:0] data;
	reg [12:0] cnt;
	
	always@(posedge eth_gtxclk or negedge rst_n)
	if(!rst_n)
	begin
		_intrig <= 1'd1;
		wr <= 0;
		cnt <= 0;
		data <= 1'd1;
	end
	else
	begin
		_intrig <= intrig;
		
		if(!wr & intrig & !_intrig)
		begin
			wr <= 1'd1;
			cnt <= 0;
			data <= 1'd1;
		end
		else
			data <= data + 1'd1;
		
		if(wr)
		begin
			cnt <= cnt + 1'd1;
			if(cnt == 13'd10 - 1'd1)
				wr <= 0;
		end		
	end
	
	wire o_eth_txen;
	wire [7:0] o_eth_txd;
	
	eth_session i(
		.i_clk(eth_gtxclk),
		.i_rst_n(rst_n),
		.i_data(data),
		.i_wr(wr),
		.i_din(1'd1),
		.o_full(),
		.o_cmd_come(),
		.o_cmd(),
		.o_param(),
	
		.o_eth_txen(o_eth_txen),
		.o_eth_txd(o_eth_txd),
		.o_eth_mdc(),
		.o_eth_txer(),
		
		.i_eth_rxclk(),
		.i_eth_rxdv(),
		.i_eth_rxer(),
		.i_eth_rxd(),
		.i_eth_crs(),
		.i_eth_col()
	);


  /*reg rst_n,clk;
  
  initial
  begin
    clk = 0;
    rst_n = 1'b1;
    #1 rst_n = 0;
    #7 rst_n = 1'b1;
  end
  
  
  always #10 clk = ~clk;
  
  wire gtxc,txen;
  wire [7:0] txd;
  
  top ii(
	 .i_rst_n(rst_n),
	 .i_clk50M(clk),
	 .i_clk48M(0),
	 .i_trig(0),
	
	 .o_eth_rst(),
	 .o_eth_gtxclk(gtxc),
	 .o_eth_txen(txen),
	 .o_eth_txer(),
	 .o_eth_txd(txd),
	 .i_eth_rxclk(0),
	 .i_eth_rxdv(0),
	 .i_eth_rxer(0),
	 .i_eth_rxd(0),
	 .i_eth_crs(0),
	 .i_eth_col(0),
	 .o_eth_mdc()
);*/

endmodule

