//100MHZ
module outtriger(
	input i_clk100M, 
	input i_rst_n, 
	input i_outtrig,
	input i_negedge,
	input [15:0] i_delay,		//unit 10ns
	output reg o_trig_recv
);

	localparam ST_IDEL = 8'd1;
	localparam ST_DELAY = 8'd2;
	localparam ST_HILEVEL = 8'd4;
	

	reg outtrig,_outtrig;
	
	always@(posedge i_clk100M or negedge i_rst_n)
	if(!i_rst_n)
	begin
		outtrig <= 1'b1;
		_outtrig <= 1'b1;
	end
	else
	begin
		{outtrig,_outtrig} <= {_outtrig,i_negedge ? ~i_outtrig : i_outtrig};
	end
	
	reg [7:0] state;
	reg [15:0] delay;
	reg [1:0] pulse;
	
	always@(posedge i_clk100M or negedge i_rst_n)
	if(!i_rst_n)
	begin
		state <= ST_IDEL;
		delay <= 0;
		pulse <= 2'd3;
		o_trig_recv <= 0;
	end
	else
	begin
		case(state)
		ST_IDEL:
			if(!outtrig & _outtrig)
			begin
				delay <= i_delay;
				pulse <= 2'd3;
				state <= ST_DELAY;
			end
		ST_DELAY:
		begin
			delay <= delay - 1'd1;
			if(delay == 15'd1 || delay == 0)
			begin
				o_trig_recv <= 1'd1;
				state <= ST_HILEVEL;
			end
		end
		ST_HILEVEL:
		begin
			pulse <= pulse - 1'd1;
			if(pulse == 2'd1)
			begin
				o_trig_recv <= 0;
				state <= ST_IDEL;
			end
		end
		endcase
	end


endmodule
