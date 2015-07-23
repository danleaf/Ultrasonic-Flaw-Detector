module syncfifo
#(
	parameter UNIT_SIZE_DEC = 13'd8191,		//UnitSize - 1
	parameter UNIT_SIZE_WIDTH = 13,
	parameter UNIT_COUNT_WIDTH = 3,
	parameter DATA_WIDTH = 8
)
(
	input i_clk,i_rst_n,
	input i_wr,i_rd,
	input [DATA_WIDTH-1:0] i_data,
	output [DATA_WIDTH-1:0] o_data,
	output o_rd_effect,
	output o_full,o_empty
);
	localparam TOTAL_SIZE = (UNIT_SIZE_DEC+1)*(1<<UNIT_COUNT_WIDTH);
	reg [DATA_WIDTH-1:0] mem[TOTAL_SIZE-1:0];		
	
	wire [UNIT_SIZE_WIDTH+UNIT_COUNT_WIDTH-1:0] wr_addr,rd_addr;
	wire [UNIT_SIZE_WIDTH-1:0] wr_size,rd_size;
	reg [DATA_WIDTH-1:0] wave_data;
	reg [UNIT_COUNT_WIDTH:0] wr_idx,rd_idx;		
	reg full,empty,rd_effect;
	
	wire rd,wr;
	
	assign o_full = full;
	assign o_empty = empty;
	assign o_data = wave_data;
	assign o_rd_effect = rd_effect;
	assign rd = i_rd & !empty;
	assign wr = i_wr & !full;
	
	counter16Mod #(16'd0,16'd0,TOTAL_SIZE-1) wr_addr_cnt(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_en(wr),
		.q(wr_addr));
	
	counter16Mod #(16'd0,16'd0,TOTAL_SIZE-1) rd_addr_cnt(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_en(rd),
		.q(rd_addr));
		
	counter16Mod #(16'd0,16'd0,UNIT_SIZE_DEC) wr_size_cnt(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_en(wr),
		.q(wr_size));
		
	counter16Mod #(16'd0,16'd0,UNIT_SIZE_DEC) rd_size_cnt(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_en(rd),
		.q(rd_size));

	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		full <= 0;
		empty <= 1;
		wr_idx <= 0;
		rd_idx <= 0;
		rd_effect <= 0;
	end
	else
	begin			
		if(wr)
		begin
			mem[wr_addr] <= i_data;
			
			if(wr_size == UNIT_SIZE_DEC)
				wr_idx <= wr_idx + 1'b1;
		end
		
		if(rd)
		begin
			wave_data <= mem[rd_addr];
			rd_effect <= 1'b1;
			
			if(rd_size == UNIT_SIZE_DEC)
				rd_idx <= rd_idx + 1'b1;
		end
		else
			rd_effect <= 0;
		
		if(wr && !rd)
		begin
			if(wr_size == UNIT_SIZE_DEC)
			begin
				full <= (wr_idx + 1'b1 == {~rd_idx[3],rd_idx[2:0]});
				empty <= 0;
			end
		end
		else if(!wr && rd)
		begin
			if(rd_size == UNIT_SIZE_DEC)
			begin
				empty <= (rd_idx + 1'b1 == wr_idx);
				full <= 0;
			end
		end
		else if(wr && rd)
		begin
			if(wr_size == UNIT_SIZE_DEC && rd_size != UNIT_SIZE_DEC)
			begin
				full <= (wr_idx + 1'b1 == {~rd_idx[3],rd_idx[2:0]});
				empty <= 0;
			end
			else if(wr_size != UNIT_SIZE_DEC && rd_size == UNIT_SIZE_DEC)
			begin
				empty <= (rd_idx + 1'b1 == wr_idx);
				full <= 0;
			end
		end
	end
endmodule
	
module syncfifo_d
#(
	parameter TOTAL_SIZE = 65536,
	parameter UNIT_SIZE_WIDTH = 13,
	parameter DATA_WIDTH = 8,
	parameter UNIT_COUNT_WIDTH = 3
)
(
	input i_clk,i_rst_n,
	input i_wr,i_rd,
	input [DATA_WIDTH-1:0] i_data,
	input [UNIT_SIZE_WIDTH-1:0] UNIT_SIZE_DEC,		//GroupSize - 1
	output [DATA_WIDTH-1:0] o_data,
	output o_rd_effect,
	output o_full,o_empty
);
	reg [DATA_WIDTH-1:0] mem[TOTAL_SIZE-1:0];		//32KB
	
	wire [UNIT_SIZE_WIDTH+UNIT_COUNT_WIDTH-1:0] wr_addr,rd_addr;
	wire [UNIT_SIZE_WIDTH-1:0] wr_size,rd_size;
	reg [DATA_WIDTH-1:0] wave_data;
	reg [UNIT_COUNT_WIDTH:0] wr_idx,rd_idx;		
	reg full,empty,rd_effect;
	
	wire rd,wr;
	
	assign o_full = full;
	assign o_empty = empty;
	assign o_data = wave_data;
	assign o_rd_effect = rd_effect;
	assign rd = i_rd & !empty;
	assign wr = i_wr & !full;
	
	counter16Mod_d #(16'd0,16'd0,UNIT_SIZE_WIDTH+UNIT_COUNT_WIDTH) wr_addr_cnt(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_en(wr),
		.MAX_VALUE(TOTAL_SIZE-1),
		.q(wr_addr));
	
	counter16Mod_d #(16'd0,16'd0,UNIT_SIZE_WIDTH+UNIT_COUNT_WIDTH) rd_addr_cnt(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_en(rd),
		.MAX_VALUE(TOTAL_SIZE-1),
		.q(rd_addr));
		
	counter16Mod_d #(16'd0,16'd0,UNIT_SIZE_WIDTH) wr_size_cnt(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_en(wr),
		.MAX_VALUE(UNIT_SIZE_DEC),
		.q(wr_size));
		
	counter16Mod_d #(16'd0,16'd0,UNIT_SIZE_WIDTH) rd_size_cnt(
		.i_clk(i_clk),
		.i_rst_n(i_rst_n),
		.i_en(rd),
		.MAX_VALUE(UNIT_SIZE_DEC),
		.q(rd_size));

	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		full <= 0;
		empty <= 1;
		wr_idx <= 0;
		rd_idx <= 0;
		rd_effect <= 0;
	end
	else
	begin			
		if(wr)
		begin
			mem[wr_addr] <= i_data;
			
			if(wr_size == UNIT_SIZE_DEC)
				wr_idx <= wr_idx + 1'b1;
		end
		
		if(rd)
		begin
			wave_data <= mem[rd_addr];
			rd_effect <= 1'b1;
			
			if(rd_size == UNIT_SIZE_DEC)
				rd_idx <= rd_idx + 1'b1;
		end
		else
			rd_effect <= 0;
		
		if(wr && !rd)
		begin
			if(wr_size == UNIT_SIZE_DEC)
			begin
				full <= (wr_idx + 1'b1 == {~rd_idx[3],rd_idx[2:0]});
				empty <= 0;
			end
		end
		else if(!wr && rd)
		begin
			if(rd_size == UNIT_SIZE_DEC)
			begin
				empty <= (rd_idx + 1'b1 == wr_idx);
				full <= 0;
			end
		end
		else if(wr && rd)
		begin
			if(wr_size == UNIT_SIZE_DEC && rd_size != UNIT_SIZE_DEC)
			begin
				full <= (wr_idx + 1'b1 == {~rd_idx[3],rd_idx[2:0]});
				empty <= 0;
			end
			else if(wr_size != UNIT_SIZE_DEC && rd_size == UNIT_SIZE_DEC)
			begin
				empty <= (rd_idx + 1'b1 == wr_idx);
				full <= 0;
			end
		end
	end

endmodule
