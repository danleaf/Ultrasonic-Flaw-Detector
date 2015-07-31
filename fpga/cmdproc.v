module cmdproc
(
	input i_clk,i_rst_n,
	input i_cmd_come,		//async
	input [15:0] i_cmd,				
	input [31:0] i_cmd_param,	
	output reg o_run,o_outmode,o_outnegedge,
	output reg [15:0] o_waveRawSize,
	output reg [2:0] o_waveRate,
	output reg [19:0] o_cycle,			//the unit is 10ns
	output reg [11:0] o_pulse,			//the unit is 10ns
	output reg [15:0] o_outdelay,		//the unit is 10ns
	output reg [15:0] o_wavedelay,	//the unit is 10ns
	output reg [7:0] o_gaindata,
	output reg o_test,
	output reg o_finish,
	output [15:0] o_finish_code
);

	assign o_finish_code = 0;

	localparam ST_IDEL = 8'd1;
	localparam ST_PROC = 8'd2;
	localparam ST_END = 8'd4;
	
	localparam CMD_START_RUN = 16'd1;
	localparam CMD_STOP_RUN = 16'd2;
	localparam CMD_SET_TRIG_MODE = 16'd3;
	localparam CMD_SET_TRIG_EDGE = 16'd4;
	localparam CMD_SET_TRIG_FREQU = 16'd5;
	localparam CMD_SET_WAVE_SIZE = 16'd6;
	localparam CMD_SET_OUTTRIG_DELAY = 16'd7;
	localparam CMD_SET_TRIGWAVE_DELAY = 16'd8;
	localparam CMD_SET_TEST = 16'd9;
	localparam CMD_SET_GAIN = 16'd10;
	
	reg cmd_come, _cmd_come;
	reg [15:0] cmd;
	reg [31:0] param;
	
	always @(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		_cmd_come <= 1'b1;
		cmd_come <= 1'b1;
	end
	else
	begin
		{cmd_come,_cmd_come} <= {_cmd_come,i_cmd_come};
	end
	
	always @(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		o_run <= 0;
		o_outmode <= 0;
		o_outnegedge <= 0;
		o_waveRawSize <= 16'd128;
		o_waveRate <= 3'd1;
		o_cycle <= 20'd1000000;
		o_pulse <= 12'd100;
		o_outdelay <= 0;
		o_wavedelay <= 0;
		o_test <= 0;
		o_gaindata <= 8'd100;
		//o_finish_code <= 0;
	end
	else
	case(state)			
		ST_PROC:
		begin
			case(cmd)
			CMD_START_RUN:
				o_run <= 1'd1;
			CMD_STOP_RUN:
				o_run <= 0;
			CMD_SET_TRIG_MODE:
				o_outmode <= param[0];
			CMD_SET_TRIG_EDGE:
				o_outnegedge <= param[0];
			CMD_SET_WAVE_SIZE:
				{o_waveRate,o_waveRawSize} <= param[18:0];
			CMD_SET_TRIG_FREQU:
			begin
				if(|param[31:16])
					o_pulse <= param[31:16] / 10;
				o_cycle <= 100000000	/ param[15:0];	
			end
			CMD_SET_OUTTRIG_DELAY:
				o_outdelay <= param[15:0];
			CMD_SET_TRIGWAVE_DELAY:
				o_wavedelay <= param[15:0];
			CMD_SET_GAIN:
				o_gaindata <= param[7:0];
			CMD_SET_TEST:
				o_test <= param[0];
			endcase
		end
			
	endcase
	
	
	reg [7:0] state;
	reg [1:0] cnt;
	
	always @(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		cnt <= 0;
		o_finish <= 0;
		state <= ST_IDEL;
	end
	else
		case(state)
		ST_IDEL:
		if(!cmd_come & _cmd_come) 
		begin
			state <= ST_PROC;
			cmd <= i_cmd;
			param <= i_cmd_param;
		end
			
		ST_PROC:
		begin
			o_finish <= 0;
			cnt <= cnt + 1'd1;
			if(cnt == 2'd3)
				state <= ST_END;
		end
		
		ST_END:
		begin
			o_finish <= 1'd1;
			state <= ST_IDEL;
			cnt <= 0;
		end
		
		default:
			state <= ST_IDEL;
			
		endcase

endmodule
