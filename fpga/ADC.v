module AD9260
(
	input clk,en,
	input [7:0] i_data,
	output [7:0] o_data
);
	reg [5:0] ad_data;
	
	initial
	begin
		ad_data = 0;
	end
					
	always@(posedge clk)
	if(en)
		//ad_data <= ad_data + 1'b1;
		ad_data <= i_data[5:0];
		
	assign o_data = {2'b0,ad_data};
	
	
	
endmodule
	
