module RED_RECV
#(
	parameter NEG = 1'b1,
	parameter BOOT = 13350,
	parameter WIDTH0 = 1115,
	parameter WIDTH1 = 2230
)
(
  input i_clk_1us,
  input i_red,
  output [31:0] o_data,
  output reg o_intr
);

	reg red_now,red_last;
	reg [31:0] code;
	
	reg [15:0] ticks;
	reg [5:0] state;
	
	wire chg,rbit,intr_next,newbit;
	wire [5:0] state_next;
	wire [15:0] ticks_next;
	
	initial
	begin
		ticks = 0;
		state = 0;
		o_intr = 0;
	end

	caclstate #(6,16,BOOT,WIDTH0,WIDTH1) i0(
		.chg(chg),
		.ticks(ticks),
		.state_now(state),
		.state_next(state_next),
		.ticks_next(ticks_next),
		.rbit(rbit),
		.o_intr(intr_next),
		.newbit(newbit));

	assign chg = (red_last && !red_now);
	
	always@(posedge i_clk_1us)
	begin
		red_now <= i_red;
		red_last <= red_now;
		code <= newbit ? {code[30:0],rbit} : code;
		state <= state_next;
		ticks <= ticks_next;
		o_intr <= intr_next;
	end
	
	assign o_data = code & 32'b11_1111_0000_0000;
endmodule

module caclstate
#(
	parameter STATE_WIDTH = 6,
	parameter TICKS_WIDTH = 16,
	parameter BOOT = 13350,
	parameter WIDTH0 = 1115,
	parameter WIDTH1 = 2230
)
(
	input chg,
	input [TICKS_WIDTH-1:0] ticks,
	input [STATE_WIDTH-1:0] state_now,
	output reg [STATE_WIDTH-1:0] state_next,
	output [TICKS_WIDTH-1:0] ticks_next,
	output rbit,o_intr,newbit
);
	localparam IDEL = 6'b0;
	localparam BOOTSTART = 6'd1;
	localparam BIT0START = 6'd2;
	localparam BIT30START = 6'd32;
	localparam BIT31START = 6'd33;
	localparam DATAOK = 6'd34;
	
	wire bit0,bit1,bootok;
	reg illegal;
	
	assign rbit = bit1 ? 1'b1 : 1'b0;
	assign bit0 = (ticks - WIDTH0 < 16'd50 || WIDTH0 - ticks < 16'd50);
	assign bit1 = (ticks - WIDTH1 < 16'd50 || WIDTH1 - ticks < 16'd50);
	assign bootok = (ticks - BOOT < 16'd50 || BOOT - ticks < 16'd50);
	assign ticks_next = (state_next == IDEL) ? 1'b0 : (chg ? 1'b0 : ticks + 1'b1);
	assign o_intr = (state_next == DATAOK);
	assign newbit = (state_next != state_now && state_next > BIT0START  && state_next <= DATAOK);
	
	always@(state_now or ticks)
	if(state_now == DATAOK)
		illegal = 1;
	else if(state_now == BOOTSTART && ticks > BOOT + 16'd1000)
		illegal = 1;
	else if(state_now >= BIT0START && state_now <= BIT31START && ticks > WIDTH1 + 16'd1000)
		illegal = 1;
	else
		illegal = 0;	
	
	always@(state_now or ticks or bit0 or bit1 or chg or illegal or bootok)
	if(illegal)
		state_next = IDEL;
	else if(!chg)
		state_next = state_now;
	else if(state_now == IDEL)
	begin
		state_next = BOOTSTART;
	end
	else if(state_now == BOOTSTART)
	begin
		if(bootok)
			state_next = BIT0START;
		else
			state_next = IDEL;
	end
	else if(state_now >= BIT0START && state_now <= BIT31START)
	begin
		if(bit1 || bit0)
			state_next = state_now + 1'b1;
		else
			state_next = IDEL;
	end
	else
		state_next = IDEL;

endmodule
