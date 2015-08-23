module eth_session
(
	input i_clk,i_rst_n,
	input [7:0] i_data,
	input i_wr,i_din,
	output o_full,o_cmd_come,
	output [15:0] o_cmd,
	output [31:0] o_param,
	input i_cmd_finish,
	input [15:0 ]i_cmd_finish_code,
	
	output o_eth_txen,
	output [7:0] o_eth_txd,
	
	input i_eth_rxclk,
	input i_eth_rxdv,
	input [7:0] i_eth_rxd
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
	reg is_rsp;
	
	wire [7:0] rd_data;
	wire rd_byte_en;
	wire [2:0] nouse0,nouse1,nouse2;
	wire [4:0] nouse3;
	
	wire send_over;
	wire wren = i_wr & !full & i_din;
	wire wr_one_yet = ((wr_size == PDU_SIZE-1'd1) && wren) || ((!i_wr & storing) && (wr_size != 0));
	wire rd = (!empty) & send_over;
	
	assign o_full = full;
		
		
	//缓存待发送数据
	dualram_rdreg #(13,8) buffer(
		.clock(i_clk),
		.data(i_data),
		.rdaddress(rd_byte_en ? rd_addr + 1'd1 : rd_addr),
		.wraddress(wr_addr),
		.wren(wren),
		.q(rd_data));
		
	//缓存RSP数据
	reg [7:0] rspdata[0:5];
	
	
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
		
	reg cmd_finish,_cmd_finish;
	reg [2:0] rspidx;
	reg [15:0] curcmd;
	
	wire feed_next_byte;
	wire [7:0] cur_byte = is_rsp ? rspdata[rspidx] : rd_data;
	
	assign rd_byte_en = feed_next_byte & (!is_rsp);
	
	eth_commu comu
	(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_data_length(cur_pdu_length),
		.i_pck_ident(cur_pckid[15:8]),
		.i_pck_idx(cur_pckid[7:0]),
		.i_cur_byte(cur_byte),
		.o_feed_next_byte(feed_next_byte),
		.i_trig_send(trig_send),
		.o_send_over(send_over),
		.o_cmd(o_cmd),
		.o_param(o_param),
		.o_cmd_come(o_cmd_come),
		.i_cmd_finish(i_cmd_finish),
		.i_cmd_finish_code(i_cmd_finish_code),
		
		.o_eth_txen(o_eth_txen),
		.o_eth_txd(o_eth_txd),
		.i_eth_rxclk(i_eth_rxclk),
		.i_eth_rxdv(i_eth_rxdv),
		.i_eth_rxd(i_eth_rxd)
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
	
		
	
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		cmd_finish <= 1'd1;
		_cmd_finish <= 1'd1;
		curcmd <= 0;
	end
	else
	begin
		{cmd_finish,_cmd_finish} <= {_cmd_finish, i_cmd_finish};
		curcmd <= o_cmd;
	end
	
	localparam ST_IDEL = 8'd1;
	localparam ST_TRIGSEND = 8'd2;
	localparam ST_SENDING = 8'd4;
	localparam ST_SENDOVER = 8'd8;
	localparam ST_PREPRSP = 8'd16;
	localparam ST_TRIGRSP = 8'd32;
	
	reg [7:0] state,state_next;
	
	always@(*)
	case(state)
	ST_IDEL:
		if(!empty)
			state_next = ST_TRIGSEND;
		else if(_cmd_finish & !cmd_finish)
			state_next = ST_PREPRSP;
		else
			state_next = ST_IDEL;
			
	ST_TRIGSEND:
		state_next = ST_SENDING;
		
	ST_SENDING:
		if(send_over)
			state_next = ST_SENDOVER;
		else
			state_next = ST_SENDING;
			
	ST_PREPRSP:
		state_next = ST_TRIGRSP;
			
	ST_TRIGRSP:
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
	ST_PREPRSP:
	begin
		rspidx <= 0;
		{rspdata[0],rspdata[1]} <= curcmd;
		{rspdata[2],rspdata[3]} <= ~curcmd;
		{rspdata[4],rspdata[5]} <= i_cmd_finish_code;
	end
	
	ST_TRIGSEND:
	begin
		is_rsp <= 1'd0;
		trig_send <= 1'd1;
		cur_pckid <= packet_id[rd_idx[1:0]];
		cur_pdu_length <= pdu_length[rd_idx[1:0]];
	end
	
	ST_TRIGRSP:
	begin
		is_rsp <= 1'd1;
		trig_send <= 1'd1;
		cur_pckid <= 16'hFFFF;
		cur_pdu_length <= 11'd6;
	end		
	
	ST_SENDING:
	if(is_rsp)
	begin
		if(feed_next_byte)
			rspidx <= rspidx + 1'd1;
	end
	
	default:
		trig_send <= 0;
	endcase
	end
	
	
endmodule
















