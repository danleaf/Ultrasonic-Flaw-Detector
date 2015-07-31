//100MHZ
module triger(
	input i_clk100M, 
	input rst_n, 
	input en,
	input [19:0] cycle,		//the unit is 10ns
	output q
);

	localparam pulse = 100;
	
	reg [19:0] cnt;
	reg s;
	
	assign q = s;
	
	
	always@(posedge i_clk100M or negedge rst_n)
	if(!rst_n)
	begin
		cnt <= 1'd1;
		s <= 1'd1;
	end
	else 
	begin
		if(en)
		begin
			if(cnt == pulse || cnt == cycle)
				s <= ~s;
			if(cnt == cycle)
				cnt <= 1'd1;
			else
				cnt <= cnt + 1'd1;
		end
		else
		begin
			cnt <= 1'd1;
			s <= 1'd1;
		end
	end	

endmodule

