module udp
(
	input i_clk,i_rst_n,i_trig,
	input [10:0] i_data_length,
	output [2:0] o_udph_idx,			// connect with header buffer's addr,start with 0
	output [7:0] o_udph_byte,			//write this byte to the header's offset given by o_udph_idx when o_wr_udph_en is 1
	output o_wr_udph_en,
	output o_ready
);
	localparam LENGTH_OFFSET = 3'd4;		//the byte offset of total length in IP header 

	localparam ST_IDEL = 8'd1;
	localparam ST_FILL_UDPH = 8'd2;
	
	reg [7:0] state;
	reg [1:0] ending_cnt;
	reg [15:0] length;
	reg ready,wr_udph_en,trig;
	reg [2:0] udph_idx;
	reg [7:0] udph_byte;
	
	assign o_ready = ready;
	assign o_udph_idx = udph_idx;
	assign o_udph_byte = udph_byte;
	assign o_wr_udph_en = wr_udph_en;
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		state <= ST_IDEL;
		length <= 0;
		ready <= 0;
		ending_cnt <= 0;
		trig <= 0;
	end
	else
	begin
		trig <= i_trig;
		length <= i_data_length + 4'd8;
	
		case(state)
		ST_IDEL:
		begin
			if(i_trig & !trig)
				state <= ST_FILL_UDPH;
			ready <= 0;
			ending_cnt <= 0;
			wr_udph_en <= 0;
			udph_idx <= 0;
			udph_byte <= 0;
		end
		ST_FILL_UDPH:
		begin
			ending_cnt <= ending_cnt + 1'd1;
			if(ending_cnt == 2'd0)
			begin
				udph_idx <= LENGTH_OFFSET;
				udph_byte <= length[15:8];
			end
			else if(ending_cnt == 2'd1)
			begin
				udph_idx <= LENGTH_OFFSET + 1'd1;
				udph_byte <= length[7:0];
			end
			else if(ending_cnt == 2'd2)
			begin
				state <= ST_IDEL;
				ready <= 1'd1;
			end
			
			if(ending_cnt != 2'd2)
				wr_udph_en <= 1'd1;
			else
				wr_udph_en <= 0;
		end
		endcase
	end
	
endmodule
