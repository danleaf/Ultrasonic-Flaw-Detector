module wave_fifo
(
	input i_clk,i_rst_n,
	input i_wr,i_rd,
	input [11:0] i_wave_size_dec,	//wave size - 1
	input [7:0] i_wave_data,
	output [7:0] o_wave_data,
	output o_rd_effect,			//wave data is reading. when it change to 0 from 1, one wave is read finish
	output o_full,o_empty
);
	//assum one wave 4KB,total 8 waves
	localparam MEMSIZE = 1<<15;	//32k
	reg [7:0] mem[MEMSIZE-1:0];		//32KB
	
	reg [14:0] wr_addr,rd_addr;
	reg [11:0] wr_size,rd_size;
	reg [7:0] wave_data;
	reg [3:0] wr_idx,rd_idx;			//bit3 used for check full
	reg full,empty,rd_effect;
	
	wire rd,wr;
	
	assign o_full = full;
	assign o_empty = empty;
	assign o_wave_data = wave_data;
	assign o_rd_effect = rd_effect;
	assign rd = i_rd & !empty;
	assign wr = i_wr & !full;

	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
	begin
		full <= 0;
		empty <= 1;
		wr_addr <= 0;
		rd_addr <= 0;
		wr_idx <= 0;
		rd_idx <= 0;
		wr_size <= 0;
		rd_size <= 0;
		rd_effect <= 0;
	end
	else
	begin			
		if(wr)
		begin
			wr_addr <= wr_addr + 1'b1;
			mem[wr_addr] <= i_wave_data;
			
			if(wr_size == i_wave_size_dec)
			begin
				wr_size <= 0;
				wr_idx <= wr_idx + 1'b1;
			end
			else
				wr_size <= wr_size + 1'b1;
		end
		
		if(rd)
		begin
			rd_addr <= rd_addr + 1'b1;
			wave_data <= mem[rd_addr];
			rd_effect <= 1'b1;
			
			if(rd_size == i_wave_size_dec)
			begin
				rd_size <= 0;
				rd_idx <= rd_idx + 1'b1;
			end
			else
				rd_size <= rd_size + 1'b1;
		end
		else
			rd_effect <= 0;
		
		if(wr && !rd)
		begin
			if(wr_size == i_wave_size_dec)
			begin
				full <= (wr_idx + 1'b1 == {~rd_idx[3],rd_idx[2:0]});
				empty <= 0;
			end
		end
		else if(!wr && rd)
		begin
			if(rd_size == i_wave_size_dec)
			begin
				empty <= (rd_idx + 1'b1 == wr_idx);
				full <= 0;
			end
		end
		else if(wr && rd)
		begin
			if(wr_size == i_wave_size_dec && rd_size != i_wave_size_dec)
			begin
				full <= (wr_idx + 1'b1 == {~rd_idx[3],rd_idx[2:0]});
				empty <= 0;
			end
			else if(wr_size != i_wave_size_dec && rd_size == i_wave_size_dec)
			begin
				empty <= (rd_idx + 1'b1 == wr_idx);
				full <= 0;
			end
		end
	end

endmodule
