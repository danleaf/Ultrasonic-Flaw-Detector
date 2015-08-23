module mac		
(
	input i_clk,i_rst_n,
	input i_tx_trig,i_last_data,
	input [7:0] i_data,	//the first data on i_data should given one clock after i_tx_trig turn UP from LOW
	output o_tx_over,
	
	output o_eth_txen,
	output [7:0] o_eth_txd
);	
	localparam ST_IDEL = 8'd1;
	localparam ST_SEND_PDU = 8'd2;
	localparam ST_SEND_PRE_FCS = 8'd4;
	localparam ST_SEND_FCS = 8'd8;
	localparam ST_SEND_OVER = 8'd16;
	localparam ST_SEND_FRONT = 8'd32;
	
	reg [7:0] tx_state,tx_state_next;
	
	reg eth_txen,txen,rxdv,tx_trig,tx_over;
	reg [7:0] eth_txd,txd,rxd;
	reg [1:0] crc_idx;
	reg [2:0] frt_cnt;		//前导符计数器，发送 0x55 0x55 0x55 0x55 0x55 0x55 0x55 0xd5
	reg calcCrc;
	
	wire [7:0] crc0,crc1,crc2,crc3,rddata;
	
	assign o_eth_txen = eth_txen;
	assign o_eth_txd = eth_txd;
	assign o_tx_over = tx_over;
	
	reg [7:0] indata[0:6];
	reg [6:0] last_data;
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		last_data <= 0;
	end
	else
	begin
		indata[0] <= i_data;
		indata[1] <= indata[0];
		indata[2] <= indata[1];
		indata[3] <= indata[2];
		indata[4] <= indata[3];
		indata[5] <= indata[4];
		indata[6] <= indata[5];
		
		last_data <= {last_data[5:0],i_last_data};
	end
	
	wire lastPdu = last_data[6];
	wire lastFcs = (crc_idx == 2'd3);
	
	always@(*)
	case(tx_state)
	ST_IDEL:
		if(i_tx_trig & !tx_trig)
			tx_state_next = ST_SEND_FRONT;
		else
			tx_state_next = ST_IDEL;
	ST_SEND_FRONT:
		if(frt_cnt == 3'd7)
			tx_state_next = ST_SEND_PDU;
		else
			tx_state_next = ST_SEND_FRONT;
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
		frt_cnt <= 0;
	end
	else
	begin		
		case(tx_state)
		ST_IDEL:
			tx_over <= 0;
		ST_SEND_FRONT:
		begin
			frt_cnt <= frt_cnt + 1'd1;
			eth_txen <= 1'b1;
			if(frt_cnt != 3'd7)
				eth_txd <= 8'h55;
			else
			begin
				eth_txd <= 8'hd5;
				txd <= indata[6];
				calcCrc <= 1'd1;
			end
		end
		ST_SEND_PDU:
		begin
			{eth_txd,txd} <= {txd,indata[6]};
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
		.crc({crc3,crc2,crc1,crc0})
	);
	
endmodule







