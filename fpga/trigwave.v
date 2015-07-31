//100MHZ
module trigwave(
	input i_clk100M, 
	input i_rst_n, 
	input i_trig,
	input [7:0] i_delay,		//unit 10ns
	input [11:0] i_pulse,		//10ns
	output reg o_trig
);

	localparam ST_IDEL = 8'd1;
	localparam ST_DELAY = 8'd2;
	localparam ST_HILEVEL = 8'd4;
	

	reg trig;
	
	always@(posedge i_clk100M or negedge i_rst_n)
	if(!i_rst_n)
		trig <= 1'b1;
	else
		trig <= i_trig;
	
	reg [7:0] state;
	reg [7:0] delay;
	reg [11:0] pulse;
	
	always@(posedge i_clk100M or negedge i_rst_n)
	if(!i_rst_n)
	begin
		state <= ST_IDEL;
		delay <= 0;
		pulse <= 0;
		o_trig <= 0;
	end
	else
	begin
		case(state)
		ST_IDEL:
			if(!trig & i_trig)
			begin
				delay <= i_delay;
				pulse <= i_pulse;
				state <= ST_DELAY;
			end
		ST_DELAY:
		begin
			delay <= delay - 1'd1;
			if(delay == 8'd1 || delay == 0)
			begin
				o_trig <= 1'd1;
				state <= ST_HILEVEL;
			end
		end
		ST_HILEVEL:
		begin
			pulse <= pulse - 1'd1;
			if(pulse == 11'd1 || pulse == 0)
			begin
				o_trig <= 0;
				state <= ST_IDEL;
			end
		end
		endcase
	end


endmodule
