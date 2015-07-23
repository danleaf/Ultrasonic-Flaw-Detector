module usb
(
	input i_rst_n,
	input i_clk_sys,
	input i_clk_usb,
	input i_wr,
	input [15:0] i_data,
	output o_full,
	
	//connect with USB chip
	input i_flagb,
	output [15:0] o_data,
	output o_addr0,
	output o_addr1,
	output o_slcs,
	output o_sloe,
	output o_slrd,
	output o_slwr,
	output reg o_slpked
);

	localparam ST_IDEL = 'H1;
	localparam ST_RD_BUF = 'H2;
	localparam ST_WRITE = 'H4;
	localparam ST_FULL_WAIT = 'H8;
	localparam ST_FULL_END = 'H16;
	
	wire empty;
	reg rd,slwr,slpked;
	
	assign o_slcs  = 1'b0;
	assign o_addr0 = 1'b0;
	assign o_addr1 = 1'b1;
	assign o_slrd = 'b1;
	assign o_sloe = 'b1;
	
	assign o_slwr = !(!slwr & i_flagb);
	
	fifo #(13,16) buffer(
		.wclk(i_clk_sys),
		.rclk(i_clk_usb),
		.rst(i_rst_n),
		.rreq(rd & i_flagb),
		.wreq(i_wr),    
		.wdata(i_data),   
		.rdata(o_data),
		.full(o_full), 
		.empty(empty));
		
	
	reg [7:0] state;
	always @(posedge i_clk_usb or negedge i_rst_n)
	begin
	if(!i_rst_n)
		begin
		slwr <= 'b1;
		rd <= 0;
		state <= ST_IDEL;
		end
	else
		case(state)
		ST_IDEL:
		if(!empty & i_flagb)
		begin
			rd <= 1'd1;
			state <= ST_RD_BUF;
		end
		
		ST_RD_BUF:
		begin
			slwr <= 'b0;
			state <= ST_WRITE;
		end		
		
		ST_WRITE:
		if(!i_flagb)
		begin
			rd <= 1'd0;
			slwr <= 'b1;
			state <= ST_FULL_WAIT;
		end
		else if(empty)
		begin
			rd <= 1'd0;
			slwr <= 1'd1;
			state <= ST_IDEL;
		end
		
		ST_FULL_WAIT:
		begin
			if(i_flagb)
			begin
				if(empty)
				begin
					slwr <= 1'd0;
					state <= ST_FULL_END;
				end
				else
				begin
					slwr <= 1'd0;
					rd <= 1'd1;
					state <= ST_WRITE;
				end
			end
		end
		
		ST_FULL_END:
		begin
			rd <= 1'd0;
			slwr <= 1'd1;
			state <= ST_IDEL;
		end
		
		default:
			state <= ST_IDEL;
		endcase
	end
	
	reg [3:0] empcnt;
	
	always @(posedge i_clk_usb or negedge i_rst_n)
	if(!i_rst_n)
	begin
		o_slpked <= 'd1;
		empcnt <= 'd15;
	end
	else
	begin
		if(empty)
			empcnt <= (empcnt == 'd15) ? 'd15 : empcnt + 'd1;
		else
			empcnt <= 0;
			
		if(empcnt == 'd12)
			o_slpked <= 'd0;
		else if(empcnt == 'd14 || empcnt == 0)
			o_slpked <= 'd1;
	end
	
	/*reg	[1:0]	STATE;

	parameter  	IDLE='H0,
			WRITE_READY='H1,
			WRITE='H2;
	
	assign o_slcs  = 1'b0;
	assign o_addr0 = 1'b0;
	assign o_addr1 = 1'b1;
	assign o_slrd = 1'b1;
	assign o_sloe = 1'b1;
	assign o_slpked = slpked;
	assign o_slwr = u_slwr;
	assign o_data = i_data;//{8'd0,i_ad_data};
	
	reg     u_slwr;
	
	always @(posedge i_clk_usb or negedge i_rst_n)
	begin
	if(!i_rst_n)
		begin
		u_slwr<='b1;
		STATE<=IDLE;
		end
	else
		begin	
		case(STATE)
		IDLE:
			begin
			STATE<=WRITE;
			end
		WRITE:
			begin
			if(i_flagb)
				begin
				u_slwr <= empty ? 'b0 : 'b0;
				STATE <= WRITE;
				end
			else
				begin
				u_slwr<='b1;
				STATE<=IDLE;
				end
			end
		default:
			STATE<=IDLE;
		endcase
		end
	end*/

endmodule
