module mac		
(
	input i_clk,i_rst_n,
	input i_tx_trig,i_last_data,
	input [7:0] i_data,	//the first data on i_data should given one clock after i_tx_trig turn UP from LOW
	output o_tx_over,
	output [7:0] o_data,
	output reg o_rx,		//o_rx = 1 means data is on o_data
	
	inout io_eth_mdio,
	output o_eth_mdc,
	
	output o_eth_txen,
	output o_eth_txer,
	output [7:0] o_eth_txd,
	
	input i_eth_rxclk,
	input i_eth_rxdv,
	input i_eth_rxer,
	input [7:0] i_eth_rxd,
	input i_eth_crs,i_eth_col
);	
	localparam ST_IDEL = 8'd1;
	localparam ST_SEND_PDU = 8'd2;
	localparam ST_SEND_PRE_FCS = 8'd4;
	localparam ST_SEND_FCS = 8'd8;
	localparam ST_SEND_OVER = 8'd16;
	
	reg [7:0] tx_state,tx_state_next;
	
	reg eth_txen,txen,rxdv,tx_trig,tx_over;
	reg [7:0] eth_txd,txd,indata,rxd;
	reg [1:0] crc_idx;
	reg calcCrc;
	
	wire [7:0] crc0,crc1,crc2,crc3,rddata;
	
	assign o_eth_txen = eth_txen;
	assign o_eth_txer = 1'bz;
	assign o_eth_txd = eth_txd;
	assign o_tx_over = tx_over;
	assign o_eth_mdc = 1'bz;
	assign io_eth_mdio = 1'bz;
	
	wire lastPdu = i_last_data;
	wire lastFcs = (crc_idx == 2'd3);
	
	always@(*)
	case(tx_state)
	ST_IDEL:
		if(i_tx_trig & !tx_trig)
			tx_state_next = ST_SEND_PDU;
		else
			tx_state_next = ST_IDEL;
	ST_SEND_PDU:
		if(lastPdu)
			tx_state_next = ST_SEND_PRE_FCS;
		else
			tx_state_next = ST_SEND_PDU;
	ST_SEND_PRE_FCS:
		tx_state_next = ST_SEND_FCS;
	ST_SEND_FCS:
		if(lastFcs)
			tx_state_next = ST_SEND_OVER;
		else
			tx_state_next = ST_SEND_FCS;
	default:
		tx_state_next = ST_IDEL;
	endcase
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		tx_state <= ST_IDEL;
		tx_trig <= 0;
	end
	else
	begin
		tx_state <= tx_state_next;
		tx_trig <= i_tx_trig;
	end
		
		
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		eth_txen <= 0;
		eth_txd <= 0;
		txen <= 0;
		txd <= 0;
		calcCrc <= 0;
	end
	else
	begin		
		case(tx_state)
		ST_IDEL:
			tx_over <= 0;
		ST_SEND_PDU:
		begin
			{eth_txd,txd} <= {txd,i_data};
			{eth_txen,txen} <= {txen,1'b1};
			calcCrc <= 1'd1;
		end
		ST_SEND_PRE_FCS:
		begin
			eth_txd <= txd;
			calcCrc <= 0;
		end
		ST_SEND_FCS:
		begin
			case(crc_idx)
			2'd0:eth_txd <= crc0;
			2'd1:eth_txd <= crc1;
			2'd2:eth_txd <= crc2;
			2'd3:eth_txd <= crc3;
			endcase
			crc_idx <= crc_idx + 1'b1;
		end
		ST_SEND_OVER:
		begin
			eth_txen <= 0;
			txen <= 0;
			tx_over <= 1'd1;
		end
		endcase
		
		if(tx_state != ST_SEND_FCS)
			crc_idx <= 0;
	end
	
	crc crc_inst
	(
		.clk(i_clk),
		.rst_n(i_rst_n&tx_state!=ST_SEND_OVER),
		.en(calcCrc),
		.d(txd),
		.crc({crc0,crc1,crc2,crc3})
	);
	
	wire fifo_empty;
	
	always@(posedge i_eth_rxclk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		rxdv <= 0;
		rxd <= 0;
	end
	else
	begin
		if(i_eth_rxdv)
			rxd <= i_eth_rxd;
			
		rxdv <= i_eth_rxdv;
	end
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
		o_rx <= 0;
	else
		o_rx <= !fifo_empty;
	
	fifo #(4,8) rx_fifo
	(
		.wclk(i_eth_rxclk),
		.rclk(i_clk),
		.rst(i_rst_n),
		.rreq(1'd1),
		.wreq(rxdv),    
		.wdata(rxd),   
		.rdata(o_data),
		.full(),
		.empty(fifo_empty)
	);
	
endmodule







