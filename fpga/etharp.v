//just send ARP response,with eth
module etharp
(
	input i_clk,i_rst_n,
	input i_trig,						// prepare destination address
	input [7:0] i_ip0,i_ip1,i_ip2,i_ip3,
	input [7:0] i_mac0,i_mac1,i_mac2,i_mac3,i_mac4,i_mac5,
	input i_set_local,					// set local IP
	output [5:0] o_hdr_idx,				// connect with header buffer's address,start with 0
	output [7:0] o_hdr_byte,			// write this byte to the header's offset given by o_hdr_idx when o_wr_hdr_en is 1
	output o_wr_hdr_en,
	output o_ready
);
	localparam DSTMAC_OFFSET = 6'd0;
	localparam SRCMAC_OFFSET = 6'd6;
	localparam SENDERIP_OFFSET = 6'd14 + 6'd14;
	localparam TARGETADDR_OFFSET = 6'd18 + 6'd14;

	localparam ST_IDEL = 8'd1;
	localparam ST_SET_SRCIP = 8'd2;
	localparam ST_SET_DSTADDR = 8'd4;
	localparam ST_WR_SRCIP = 8'd8;
	localparam ST_WR_DSTADDR = 8'd16;
	localparam ST_END = 8'd32;

	reg [7:0] state,state_next;
	reg [7:0] addr[0:9];			//0~5 is MAC, 6~9 is IP
	reg [3:0] wr_cnt,addr_idx;
	reg [5:0] hdr_idx,next_hdr_idx;	
	reg [7:0] hdr_byte;
	reg wr_hdr_en,ready,trig,set_local;
	
	assign o_hdr_idx = hdr_idx;
	assign o_hdr_byte = hdr_byte;
	assign o_wr_hdr_en = wr_hdr_en;
	assign o_ready = ready;
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		state <= ST_IDEL;
		trig <= 0;
		set_local <= 0;
	end
	else
	begin
		state <= state_next;
		trig <= i_trig;
		set_local <= i_set_local;
	end
	
	always@(*)
	begin
		case(state)
		ST_IDEL:
			if(i_set_local & !set_local)
				state_next = ST_SET_SRCIP;
			else if(i_trig & !trig)
				state_next = ST_SET_DSTADDR;
			else
				state_next = ST_IDEL;
		ST_SET_SRCIP:
			state_next = ST_WR_SRCIP;
		ST_SET_DSTADDR:
			state_next = ST_WR_DSTADDR;
		ST_WR_SRCIP:
			if(wr_cnt == 4'd3)
				state_next = ST_END;
			else
				state_next = ST_WR_SRCIP;
		ST_WR_DSTADDR:
			if(wr_cnt == 4'd15)
				state_next = ST_END;
			else
				state_next = ST_WR_DSTADDR;
		ST_END:
			state_next = ST_IDEL;
		default:
			state_next = ST_IDEL;
		endcase
	end
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		hdr_idx <= 0;
		next_hdr_idx <= 0;	
		hdr_byte <= 0;
		wr_hdr_en <= 0;
		addr_idx <= 0;
	end
	else
	begin
		case(state)
		ST_IDEL:
		begin
			wr_cnt <= 0;
			wr_hdr_en <= 0;
			ready <= 0;
			next_hdr_idx <= 0;
			addr_idx <= 0;
		end
		ST_SET_SRCIP:
		begin
			{addr[0],addr[1],addr[2],addr[3]} <= {i_ip0,i_ip1,i_ip2,i_ip3};
			next_hdr_idx <= SENDERIP_OFFSET;
		end
		ST_SET_DSTADDR:
		begin
			{addr[0],addr[1],addr[2],addr[3],addr[4],addr[5]} <= {i_mac0,i_mac1,i_mac2,i_mac3,i_mac4,i_mac5};
			{addr[6],addr[7],addr[8],addr[9]} <= {i_ip0,i_ip1,i_ip2,i_ip3};
			next_hdr_idx <= DSTMAC_OFFSET;
		end
		ST_WR_SRCIP:
		begin
			wr_cnt <= wr_cnt + 1'd1;
			wr_hdr_en <= 1'd1;
			hdr_byte <= addr[addr_idx];
			hdr_idx <= next_hdr_idx;
			
			if(wr_cnt != 4'd3)
			begin
				next_hdr_idx <= next_hdr_idx + 1'd1;
				addr_idx <= addr_idx + 1'd1;
			end
		end
		ST_WR_DSTADDR:
		begin
			wr_cnt <= wr_cnt + 1'd1;
			wr_hdr_en <= 1'd1;
			hdr_byte <= addr[addr_idx];
			hdr_idx <= next_hdr_idx;
			
			if(wr_cnt != 4'd5)
			begin
				next_hdr_idx <= next_hdr_idx + 1'd1;
				addr_idx <= addr_idx + 1'd1;
			end
			else
			begin
				next_hdr_idx <= TARGETADDR_OFFSET;
				addr_idx <= 0;
			end
		end
		ST_END:
			ready <= 1'd1;
		endcase
	end
	
endmodule
