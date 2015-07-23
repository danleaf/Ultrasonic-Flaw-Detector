module ip
(
	input i_clk,i_rst_n,i_trig,
	input [15:0] i_data_length,
	input [7:0] i_ip0,i_ip1,i_ip2,i_ip3,
	input i_set_local,i_set_dest,					// set ip
	output [4:0] o_iph_idx,				// connect with header buffer's addr,start with 0
	output [7:0] o_iph_byte,			// write this byte to the header's offset given by o_iph_idx when o_wr_iph_en is 1
	output o_wr_iph_en,
	output o_ready
);

	localparam LENGTH_OFFSET = 5'd2;		//the byte offset of total length in IP header 
	localparam SRCIP_OFFSET = 5'd12;
	localparam DSTIP_OFFSET = 5'd16;
	localparam CHECKSUM_OFFSET = 5'd10;
	localparam IP_HEADER_LENGTH = 5'd20;
	localparam INIT_CHECKSUM = 16'hD66C;
	localparam INIT_CHECKSUM_WITHOUT_IP = 16'h5312;
	localparam CMD_SET_SRCIP = 2'd1;
	localparam CMD_SET_DSTIP = 2'd2;
	localparam INIT_SRCIP = 32'h_C0_A8_01_04;
	localparam INIT_DSTIP = 32'h_C0_A8_01_05;
	

	localparam ST_IDEL = 8'd1;
	localparam ST_COMPUTE_LENGTH = 8'd2;
	localparam ST_COMPUT_CHECKSUM = 8'd4;
	localparam ST_END = 8'd8;
	localparam ST_SET_SRCIP = 8'd16;
	localparam ST_SET_DSTIP = 8'd32;
	localparam ST_COMPUT_INIT_CHECKSUM = 8'd64;
	localparam ST_COMPUT_CHECKSUM_LAST = 8'd128;
	
	reg [7:0] state,state_next,state_last,chks_din;
	reg calc_length_cnt;
	reg [1:0] ending_cnt;
	reg [15:0] length,checksum,initsum;
	reg [7:0] sip0,sip1,sip2,sip3,dip0,dip1,dip2,dip3;
	reg ready,calc_chks_sig,chksCout;
	reg [2:0] calc_init_chks_cnt;
	reg [1:0] cur_cmd;
	reg [4:0] iph_idx;	
	reg [7:0] iph_byte;
	reg wr_iph_en,trig,set_local,set_dest;
	
	wire [15:0] chks_net,chks_real;
	wire chks_c;
	
	assign o_iph_idx = iph_idx;
	assign o_iph_byte = iph_byte;
	assign o_wr_iph_en = wr_iph_en;
	assign o_ready = ready;
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		state <= ST_IDEL;
		state_last <= ST_IDEL;
		trig <= 0;
		set_local <= 0;
		set_dest <= 0;
	end
	else
	begin
		state <= state_next;
		state_last <= state;
		trig <= i_trig;
		set_local <= i_set_local;
		set_dest <= i_set_dest;
	end
	
	always@(*)
	begin
		case(state)
		ST_IDEL:
			if(i_trig & !trig)
				state_next = ST_COMPUTE_LENGTH;
			else if(i_set_local & !set_local)
				state_next = ST_SET_SRCIP;
			else if(i_set_dest & !set_dest)
				state_next = ST_SET_DSTIP;
			else
				state_next = ST_IDEL;
		ST_COMPUTE_LENGTH:
			if(calc_length_cnt == 1'd1)
				state_next = ST_COMPUT_CHECKSUM;
			else
				state_next = ST_COMPUTE_LENGTH;
		ST_COMPUT_CHECKSUM:
			if(calc_chks_sig)
				state_next = ST_COMPUT_CHECKSUM_LAST;
			else
				state_next = ST_COMPUT_CHECKSUM;
		ST_SET_SRCIP:
			state_next = ST_COMPUT_INIT_CHECKSUM;
		ST_SET_DSTIP:
			state_next = ST_COMPUT_INIT_CHECKSUM;
		ST_COMPUT_INIT_CHECKSUM:
			if(calc_init_chks_cnt == 3'd7)
				state_next = ST_COMPUT_CHECKSUM_LAST;
			else
				state_next = ST_COMPUT_INIT_CHECKSUM;
		ST_COMPUT_CHECKSUM_LAST:
			state_next = ST_END;
		ST_END:
			if(ending_cnt == 2'd3)
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
		chks_din <= 0;
		checksum <= 0;
		initsum <= INIT_CHECKSUM;
		iph_idx <= 0;	
		iph_byte <= 0;
		wr_iph_en <= 0;
		{sip0,sip1,sip2,sip3} <= INIT_SRCIP;
		{dip0,dip1,dip2,dip3} <= INIT_DSTIP;
	end
	else
	begin
		case(state)
		ST_IDEL:
		begin
			cur_cmd <= 0;
			ending_cnt <= 0;
			calc_length_cnt <= 0;
			calc_chks_sig <= 0;
			calc_init_chks_cnt <= 0;
			wr_iph_en <= 0;
			ready <= 0;
		end
		ST_COMPUTE_LENGTH:
		begin
			calc_length_cnt <= calc_length_cnt + 1'd1;
			length <= i_data_length + IP_HEADER_LENGTH;
		end
		ST_SET_SRCIP:
		begin
			{sip0,sip1,sip2,sip3} <= {i_ip0,i_ip1,i_ip2,i_ip3};
			cur_cmd <= CMD_SET_SRCIP;
		end
		ST_SET_DSTIP:
		begin
			{dip0,dip1,dip2,dip3} <= {i_ip0,i_ip1,i_ip2,i_ip3};
			cur_cmd <= CMD_SET_DSTIP;
		end
		ST_COMPUT_CHECKSUM:
		begin
			calc_chks_sig <= ~calc_chks_sig;
			wr_iph_en <= 1'd1;
			if(calc_chks_sig == 0)
			begin
				chks_din <= length[7:0];
				iph_byte <= length[15:8];
				iph_idx <= LENGTH_OFFSET;
			end
			else
			begin
				chks_din <= length[15:8];
				iph_byte <= length[7:0];
				iph_idx <= LENGTH_OFFSET + 1'd1;
			end
		end
		ST_COMPUT_INIT_CHECKSUM:
		begin
			calc_init_chks_cnt <= calc_init_chks_cnt + 1'd1;
			wr_iph_en <= 1'd1;
			case(calc_init_chks_cnt)
			3'd0:
			begin
				chks_din <= sip1;
				iph_byte <= sip0;
				iph_idx <= SRCIP_OFFSET;
			end
			3'd1:
			begin
				chks_din <= sip0;
				iph_byte <= sip1;
				iph_idx <= SRCIP_OFFSET + 2'd1;
			end
			3'd2:
			begin
				chks_din <= sip3;
				iph_byte <= sip2;
				iph_idx <= SRCIP_OFFSET + 2'd2;
			end
			3'd3:
			begin
				chks_din <= sip2;
				iph_byte <= sip3;
				iph_idx <= SRCIP_OFFSET + 2'd3;
			end
			3'd4:
			begin
				chks_din <= dip1;
				iph_byte <= dip0;
				iph_idx <= DSTIP_OFFSET;
			end
			3'd5:
			begin
				chks_din <= dip0;
				iph_byte <= dip1;
				iph_idx <= DSTIP_OFFSET + 2'd1;
			end
			3'd6:
			begin
				chks_din <= dip3;
				iph_byte <= dip2;
				iph_idx <= DSTIP_OFFSET + 2'd2;
			end
			3'd7:
			begin
				chks_din <= dip2;
				iph_byte <= dip3;
				iph_idx <= DSTIP_OFFSET + 2'd3;
			end
			endcase
		end
		ST_COMPUT_CHECKSUM_LAST:
			wr_iph_en <= 0;
		ST_END:
		begin
			ending_cnt <= ending_cnt + 1'd1;
			if(ending_cnt == 2'd0)
			begin
				if(cur_cmd == CMD_SET_DSTIP || cur_cmd == CMD_SET_SRCIP)
					initsum <= chks_real;
				else
					checksum <= chks_real;
			end
			else if(!(cur_cmd == CMD_SET_DSTIP || cur_cmd == CMD_SET_SRCIP))
			begin
				if(ending_cnt == 2'd1)
				begin
					iph_byte <= checksum[15:8];
					iph_idx <= CHECKSUM_OFFSET;
				end
				else if(ending_cnt == 2'd2)
				begin
					iph_byte <= checksum[7:0];
					iph_idx <= CHECKSUM_OFFSET + 1'd1;
				end
				
				if(ending_cnt != 2'd3)
					wr_iph_en <= 1'd1;
				else
					wr_iph_en <= 0;					
			end
			
			if(ending_cnt == 2'd3)
				ready <= 1'd1;
		end
		endcase
	end
	
	wire en_check = (state_last == ST_COMPUT_CHECKSUM | state_last == ST_COMPUT_INIT_CHECKSUM);
	wire init_check = (state == ST_SET_SRCIP || state == ST_SET_DSTIP || state == ST_IDEL);
	wire [15:0] the_sum = (state == ST_SET_SRCIP || state == ST_SET_DSTIP) ? INIT_CHECKSUM_WITHOUT_IP : initsum;
	
	checksum inst_chks
	(	
		.clk(i_clk),
		.rst_n(i_rst_n),
		.init(init_check),
		.initsum(the_sum),
		.en(en_check),
		.d(chks_din),
		.sum(chks_net),
		.c(chks_c)
	);
	
	inc16 inst_inc16
	(	
		.a(chks_net),
		.b(chks_c),
		.q(chks_real),
		.c()
	);

endmodule
