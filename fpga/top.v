module top
(
	input i_rst_n,
	input i_clk50M,
	input i_clk48M,
	input i_trig,
	
	output o_eth_rst,
	output o_eth_gtxclk,
	output o_eth_txen,
	output o_eth_txer,
	output [7:0] o_eth_txd,
	input i_eth_rxclk,
	input i_eth_rxdv,
	input i_eth_rxer,
	input [7:0] i_eth_rxd,
	input i_eth_crs,i_eth_col,
	//inout io_eth_mdio,
	output o_eth_mdc
);
	
	wire eth_gtxclk;
	pll125m  plleth(i_clk50M, o_eth_gtxclk, eth_gtxclk);
	
	assign o_eth_rst = 1'bz;
	
	//test --begin
	wire trig;
	reg intrig,_intrig,__intrig,wr;
	reg [7:0] data;
	reg [12:0] cnt;
	
	triger trig_inst(
		.i_clk100M(eth_gtxclk), 
		.rst_n(i_rst_n), 
		.en(1'd1),
		.cycle(20'd200),	
		.q(trig)
	);	
	
	always@(posedge eth_gtxclk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		__intrig <= 1'd1;
		_intrig <= 1'd1;
		intrig <= 1'd1;
		wr <= 0;
		cnt <= 0;
		data <= 1'd1;
	end
	else
	begin
		intrig <= trig;
		_intrig <= intrig;
		__intrig <= _intrig;
		
		if(!wr & _intrig & !__intrig)
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
	
	//test --end
	
	eth_session i(
		.i_clk(eth_gtxclk),
		.i_rst_n(i_rst_n),
		//.i_rst_n(!(trig & !intrig)),
		.i_data(data),
		.i_wr(wr),
		.i_din(1'd1),
		.o_full(),
		.o_cmd_come(),
		.o_cmd(),
		.o_param(),
	
		.o_eth_txen(o_eth_txen),
		.o_eth_txd(o_eth_txd),
		//.io_eth_mdio(io_eth_mdio),
		.o_eth_mdc(o_eth_mdc),
		.o_eth_txer(o_eth_txer),
		
		.i_eth_rxclk(i_eth_rxclk),
		.i_eth_rxdv(i_eth_rxdv),
		.i_eth_rxer(i_eth_rxer),
		.i_eth_rxd(i_eth_rxd),
		.i_eth_crs(i_eth_crs),
		.i_eth_col(i_eth_col)
	);

endmodule



