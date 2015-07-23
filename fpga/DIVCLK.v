module DIVCLK
#(parameter DIVCOUNT = 2)
(
  input clk,
  output reg outclk
);
	reg [31:0] counter;
	
	initial
	begin
		counter = 0;
		outclk = 0;
	end
	
	always@(posedge clk)
	begin
		if(counter == DIVCOUNT - 1)
			counter <= 0;
		else
			counter <= counter + 1;
			
		outclk <= (counter < DIVCOUNT/2) ? 1'b1 : 1'b0;
	end

endmodule
