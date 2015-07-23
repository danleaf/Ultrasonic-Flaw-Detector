module eth
(
	input i_clk,i_rst_n,
	input [7:0] i_mac0,i_mac1,i_mac2,i_mac3,i_mac4,i_mac5,
	input i_set_dst,					// 0:none	1:set src mac, 2:set dst mac
	output [3:0] o_eth_idx,				// connect with header buffer's addr,start with 0
	output [7:0] o_eth_byte,			// write this byte to the header's offset given by o_eth_idx when o_wr_eth_en is 1
	output o_wr_eth_en,
	output o_ready
);
	localparam DSTMAC_OFFSET = 4'd0;

	localparam ST_IDEL = 8'd1;
	localparam ST_SET_SRCMAC = 8'd2;
	localparam ST_SET_DSTMAC = 8'd4;
	localparam ST_END = 8'd8;

	reg [7:0] state,state_next;
	reg [7:0] mac[0:5];
	reg [2:0] ending_cnt;
	reg [3:0] eth_idx,next_eth_idx;	
	reg [7:0] eth_byte;
	reg wr_eth_en,ready,set_dst;
	
	assign o_eth_idx = eth_idx;
	assign o_eth_byte = eth_byte;
	assign o_wr_eth_en = wr_eth_en;
	assign o_ready = ready;
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		state <= ST_IDEL;
		set_dst <= 0;
	end
	else
	begin
		state <= state_next;
		set_dst <= i_set_dst;
	end
	
	always@(*)
	begin
		case(state)
		ST_IDEL:
		if(i_set_dst & !set_dst)
				state_next = ST_SET_DSTMAC;
			else
				state_next = ST_IDEL;
		ST_SET_DSTMAC:
			state_next = ST_END;
		ST_END:
			if(ending_cnt == 3'd6)
				state_next = ST_IDEL;
			else
				state_next = ST_END;
		default:
			state_next = ST_IDEL;
		endcase
	end
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		next_eth_idx <= 0;	
		eth_byte <= 0;
		wr_eth_en <= 0;
		eth_idx <= 0;
	end
	else
	begin
		case(state)
		ST_IDEL:
		begin
			ending_cnt <= 0;
			wr_eth_en <= 0;
			ready <= 0;
			next_eth_idx <= 0;
			eth_idx <= 0;
		end
		ST_SET_DSTMAC:
		begin
			{mac[0],mac[1],mac[2],mac[3],mac[4],mac[5]} <= {i_mac0,i_mac1,i_mac2,i_mac3,i_mac4,i_mac5};
			next_eth_idx <= DSTMAC_OFFSET;
		end
		ST_END:
		begin
			ending_cnt <= ending_cnt + 1'd1;
			
			if(ending_cnt != 3'd6)
				wr_eth_en <= 1'd1;
			else
				wr_eth_en <= 0;	
				
			if(ending_cnt != 3'd6)
			begin
				eth_byte <= mac[ending_cnt];
				next_eth_idx <= next_eth_idx + 1'd1;
				eth_idx <= next_eth_idx;
			end
			
			if(ending_cnt == 3'd6)
				ready <= 1'd1;
		end
		endcase
	end
	
endmodule
