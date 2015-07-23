module eth_session
(
	input i_clk,i_rst_n,
	input [7:0] i_data,
	input i_wr,i_din,
	output o_full,o_cmd_come,
	output [7:0] o_cmd,
	output [31:0] o_param,
	
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
	localparam PDU_SIZE = 11'd1470; //1500 - 20 - 8 - 2;
	localparam ADDR_WIDTH = 13;
	localparam FRAME_COUNT_WIDTH = 4;
	localparam MEMSIZE = 1<<ADDR_WIDTH;
	localparam FRAME_COUNT = 1<<FRAME_COUNT_WIDTH;
	
	wire [12:0] wr_addr,wr_addrinc,rd_addr;
	wire [10:0] wr_size;
	reg [10:0] pdu_length[0:3],cur_pdu_length;
	reg [16:0] packet_id[0:3],cur_pckid;
	reg [12:0] start_addr,curr_max_addr;
	reg [2:0] rd_idx,wr_idx;
	reg [7:0] packet_idx,packet_ident;

	reg full,empty,storing;
	reg trig_send;
	
	wire [7:0] rd_data;
	wire rd_byte_en;
	wire [2:0] nouse0,nouse1,nouse2;
	wire [4:0] nouse3;
	
	wire send_over;
	wire wren = i_wr & !full & i_din;
	wire wr_one_yet = ((wr_size == PDU_SIZE-1'd1) && wren) || ((!i_wr & storing) && (wr_size != 0));
	wire rd = send_over;
	
	assign o_full = full;
	
	altdualram buffer(i_clk,i_data,rd_addr,wr_addr,wren,rd_data);
	
	counter16 rd_addr_cnt(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_en(rd_byte_en),
		.q({nouse0,rd_addr}));
	
	counter16 wr_addr_cnt(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_en(wren),
		.q({nouse1,wr_addr}));
		
	counter16 #(16'd1) wr_addr_cnt2(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_en(wren),
		.q({nouse2,wr_addrinc}));
	
	eth_commu comu
	(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_data_length(cur_pdu_length),
		.i_pck_ident(cur_pckid[15:8]),
		.i_pck_idx(cur_pckid[7:0]),
		.i_cur_byte(rd_data),
		.o_get_cur_byte(rd_byte_en),
		.i_trig_send(trig_send),
		.o_send_over(send_over),
		.o_cmd(o_cmd),
		.o_param(o_param),
		.o_cmd_come(o_cmd_come),
		.io_eth_mdio(io_eth_mdio),
		.o_eth_mdc(o_eth_mdc),
		.o_eth_txen(o_eth_txen),
		.o_eth_txer(o_eth_txer),
		.o_eth_txd(o_eth_txd),
		.i_eth_rxclk(i_eth_rxclk),
		.i_eth_rxdv(i_eth_rxdv),
		.i_eth_rxer(i_eth_rxer),
		.i_eth_rxd(i_eth_rxd),
		.i_eth_crs(i_eth_crs),
		.i_eth_col(i_eth_col)
	);
		
	counter16Mod #(16'd0,16'd0,PDU_SIZE-1'd1) wr_size_cnt(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_init(!i_wr),
		.i_en(wren),
		.q({nouse3,wr_size}));
		
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		full <= 0;
		empty <= 1'b1;
		wr_idx <= 0;
		rd_idx <= 0;
		storing <= 0;
		packet_ident <= 0;
		packet_idx <= 0;
	end
	else
	begin			
		if(wren)
		begin
			storing <= 1'b1;
			if(wr_size == PDU_SIZE-1'd1)
			begin
				wr_idx <= wr_idx + 1'b1;
				pdu_length[wr_idx[1:0]] <= PDU_SIZE;
				packet_id[wr_idx[1:0]] <= {packet_ident,packet_idx};
				packet_idx <= packet_idx + 1'd1;
				full <= (wr_idx + 1'b1 == {{~rd_idx[2],rd_idx[1:0]}});				
			end
			
		end		
		
		if(!i_wr & storing)
		begin
			storing <= 0;
			if(wr_size != 0)
			begin
				wr_idx <= wr_idx + 1'b1;
				pdu_length[wr_idx[1:0]] <= wr_size;
				packet_id[wr_idx[1:0]] <= {packet_ident,packet_idx};
				packet_ident <= packet_ident + 1'd1;
				packet_idx <= 0;
				full <= (wr_idx + 1'b1 == {{~rd_idx[2],rd_idx[1:0]}});
			end
		end
		
		if(rd)
		begin
			rd_idx <= rd_idx + 1'd1;
			empty <= (rd_idx + 1'd1 == wr_idx);
		end
		
		if(wr_one_yet && !rd)
			empty <= 0;
		else if(!wr_one_yet && rd)
			full <= 0;
	end
	
	
	localparam ST_IDEL = 8'd1;
	localparam ST_TRIGSEND = 8'd2;
	localparam ST_SENDING = 8'd4;
	localparam ST_SENDOVER = 8'd8;
	
	reg [7:0] state,state_next;
	
	
	always@(*)
	case(state)
	ST_IDEL:
		if(!empty)
			state_next = ST_TRIGSEND;
		else
			state_next = ST_IDEL;
	ST_TRIGSEND:
		state_next = ST_SENDING;
	ST_SENDING:
		if(send_over)
			state_next = ST_SENDOVER;
		else
			state_next = ST_SENDING;
	default:
		state_next = ST_IDEL;
	endcase
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
		state <= ST_IDEL;
	else
		state <= state_next;
		
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		trig_send <= 0;
		cur_pdu_length <= 0;
	end
	else
	begin
	case(state)
	ST_TRIGSEND:
	begin
		trig_send <= 1'd1;
		cur_pckid <= packet_id[rd_idx[1:0]];
		cur_pdu_length <= pdu_length[rd_idx[1:0]];
	end
	default:
		trig_send <= 0;
	endcase
	end
	
	
endmodule
















