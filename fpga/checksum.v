module checksum
(
	input clk,rst_n,init,
	input [15:0] initsum,
	input en,
	input [7:0] d,
	output [15:0] sum,
	output c
);
	reg [15:0] r;
	reg ci,sig;
	wire [7:0] addSumL,addSumH;
	wire addCL,addCH;
	
	initial
	begin
		r = 0;
		ci = 0;
		sig = 0;
	end
	
	assign sum = r[15:0];
	assign c = ci; 
	
	add8 i0(d,r[7:0],ci,addSumL,addCL);
	add8 i1(d,r[15:8],ci,addSumH,addCH);
	
	always@(posedge clk or negedge rst_n)
	if(!rst_n)
		{r,ci,sig} <= 18'd0;
	else if(init)
		{r,ci,sig} <= {initsum,2'd0};	
	else if(en)
	begin
		sig <= ~sig;
		if(!sig)
			{ci,r[7:0]} <= {addCL,addSumL};
		else
			{ci,r[15:8]} <= {addCH,addSumH};
	end

endmodule