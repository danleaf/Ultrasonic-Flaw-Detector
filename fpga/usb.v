module usb
(
	input i_rst_n,
	input i_clk_sys,
	input i_clk_usb,
	input i_wr,
	input i_cmd_finish,					//async
	input [15:0] i_cmd_finish_code,
	input [15:0] i_wr_data,
	output o_full,
	output reg o_cmd_come,
	output reg [15:0] o_cmd,
	output reg [31:0] o_cmd_param,
	
	//connect with USB chip
	input i_flagb,i_flagc,
	inout [15:0] io_data,
	output o_addr0,
	output reg o_addr1,
	output o_slcs,
	output reg o_sloe,
	output reg o_slrd,
	output o_slwr,
	output reg o_slpked
);

	localparam ST_IDEL = 10'd1;
	localparam ST_RD_BUF = 10'd2;
	localparam ST_WRITE = 10'd4;
	localparam ST_FULL_WAIT = 10'd8;
	localparam ST_FULL_END = 10'd16;
	localparam ST_WRITE_END = 10'd32;
	localparam ST_PREP_RX = 10'd64;
	localparam ST_PREP_CMD = 10'd128;
	localparam ST_RSP_CMD = 10'd256;
	localparam ST_RSP_CMD_END = 10'd512;
	
	wire empty;
	wire [15:0] buf_out;
	
	reg rd,slwr;
	reg [9:0] state;
	reg [3:0] empcnt;
	reg [15:0] cmdcache[0:3];
	reg [15:0] cmdrspcache[0:1];
	reg [15:0] cmd_rsp;
	reg [2:0] ccidx;
	reg wait_cmd_finish;
	reg cmd_finish,_cmd_finish,__cmd_finish;
	reg cmdrsp_idx;
	
	assign o_slcs  = 1'b0;
	assign o_addr0 = 1'b0;
	
	assign o_slwr = !(!slwr & i_flagb);
	
	fifo #(13,16) buffer(
		.wclk(i_clk_sys),
		.rclk(i_clk_usb),
		.rst(i_rst_n),
		.rreq(rd & i_flagb),
		.wreq(i_wr),    
		.wdata(i_wr_data),   
		.rdata(buf_out),
		.full(o_full), 
		.empty(empty));
	
	
	assign io_data = (state == ST_RSP_CMD) ? cmd_rsp : ((state != ST_PREP_RX) ? buf_out : {16{1'bz}});
	
	
	always @(posedge i_clk_usb or negedge i_rst_n)
	if(!i_rst_n)
		{_cmd_finish,__cmd_finish} <= 0;
	else
		{_cmd_finish,__cmd_finish} <= {__cmd_finish, i_cmd_finish};
	
	
	always @(posedge i_clk_usb or negedge i_rst_n)
	if(!i_rst_n)
	begin
		slwr <= 1'b1;
		rd <= 0;
		state <= ST_IDEL;
		o_slpked <= 1'd1;
		empcnt <= 0;
		o_addr1 <= 1'b1;
		o_sloe <= 'b1;
		o_slrd <= 1'b1;
		ccidx <= 0;
		o_cmd_come <= 0;
		o_cmd <= 0;
		o_cmd_param <= 0;
		cmdcache[0] <= 0;
		cmdcache[1] <= 0;
		cmdcache[2] <= 0;
		cmdcache[3] <= 0;
		wait_cmd_finish <= 0;
		cmdrsp_idx <= 0;
		cmd_finish <= 0;
	end
	else
	begin		
		if(!_cmd_finish & __cmd_finish)
			cmd_finish <= 1'd1;
			
		case(state)
		ST_IDEL:
		if(wait_cmd_finish & cmd_finish & i_flagb)
		begin
			cmd_finish <= 0;
			state <= ST_RSP_CMD;
			cmdrspcache[0] <= o_cmd;
			cmdrspcache[1] <= i_cmd_finish_code;
		end
		else if(!wait_cmd_finish & 
					i_flagc)
		begin
			o_addr1 <= 0;
			o_sloe <= 0;
			o_slrd <= 0;
			state <= ST_PREP_RX;
		end
		else
		begin			
			if(!empty & i_flagb)
			begin
				rd <= 1'd1;
				state <= ST_RD_BUF;
			end
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
			state <= ST_WRITE_END;
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
			state <= ST_WRITE_END;
		end
		
		ST_WRITE_END:
		begin
			empcnt <= empcnt + 1'd1;
			
			if(empcnt == 4'd14)
			begin
				o_slpked <= 0;
				empcnt <= 4'd15;
			end
			else if(empcnt == 4'd15)
			begin
				o_slpked <= 1'd1;
				state <= ST_IDEL;
				empcnt <= 0;
			end
			else if(!empty)
			begin
				if(i_flagb)
				begin
					rd <= 1'd1;
					state <= ST_RD_BUF;
					empcnt <= 0;
				end
				else
				begin
					state <= ST_IDEL;
					empcnt <= 0;
				end
			end
			else
				empcnt <= empcnt + 1'd1;
		end
		
		ST_PREP_RX:
		if(!i_flagc)
		begin
			o_addr1 <= 1'b1;
			o_sloe <= 1'b1;
			o_slrd <= 1'b1;
			ccidx <= 0;
			state <= ST_PREP_CMD;
		end
		else
		begin
			o_cmd_come <= 0;
			ccidx <= (ccidx == 3'd4) ? 3'd4 : ccidx + 1'd1;
			
			if(ccidx != 3'd4)
				cmdcache[ccidx] <= io_data;
		end
		
		ST_PREP_CMD:
		begin
			if(cmdcache[0] == ~cmdcache[1])
			begin
				o_cmd_come <= 1'd1;
				o_cmd <= cmdcache[0];
				o_cmd_param <= {cmdcache[3],cmdcache[2]};
			end
			state <= ST_IDEL;
			wait_cmd_finish <= 1'd1;
		end
		
		ST_RSP_CMD:
		begin
			slwr <= 0;
			if(i_flagb)
			begin
				cmdrsp_idx <= ~cmdrsp_idx;
				cmd_rsp <= cmdrspcache[cmdrsp_idx];
				if(cmdrsp_idx)
					state <= ST_RSP_CMD_END;
			end
		end
		
		ST_RSP_CMD_END:
		begin
			slwr <= 1'b1;
			wait_cmd_finish <= 0;
			cmdrsp_idx <= ~cmdrsp_idx;
			if(!cmdrsp_idx)
				o_slpked <= 1'd0;
			else
			begin
				o_slpked <= 1'd1;
				state <= ST_IDEL;
			end
		end
		
		default:
			state <= ST_IDEL;
		endcase
	end
	/*always @(posedge i_clk_usb or negedge i_rst_n)
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
	end*/
	
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
	assign io_data = i_wr_data;//{8'd0,i_ad_data};
	
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
