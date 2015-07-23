module counter
#(
	parameter INIT_VALUE = 16'd0
)
(input clk, input i_rst_n, input i_en, output [15:0] q);

	reg[3:0] cnt0;
	reg[3:0] cnt1;
	reg[3:0] cnt2;
	reg[3:0] cnt3;
	reg c0,c1,c2;
	initial
	begin
		{cnt3,cnt2,cnt1,cnt0} = INIT_VALUE;
		{c0,c1,c2} = 3'b0;
	end
	
	assign q = {cnt3,cnt2,cnt1,cnt0};
	
	always@(posedge clk or negedge i_rst_n)
	if(!i_rst_n)
		{cnt3,cnt2,cnt1,cnt0,c2,c1,c0} <= {INIT_VALUE,3'b0};
	else if(i_en)
	begin
		c0 <= (&cnt0[3:1])&(~cnt0[0]);
		c1 <= &cnt1;
		c2 <= &cnt2;
		
		cnt0 <= cnt0 + 1'b1;
		
		if(c0)
			cnt1 <= cnt1 + 1'b1;
		  
		if(c0 & c1)
			cnt2 <= cnt2 + 1'b1;
		  
		if(c0 & c1 & c2)
			cnt3 <= cnt3 + 1'b1;
	end

endmodule 

module counter24
#(
	parameter INIT_VALUE = 24'd0
)
(input clk, input i_rst_n, input i_en, output [23:0] q);

	reg[3:0] cnt0;
	reg[3:0] cnt1;
	reg[3:0] cnt2;
	reg[3:0] cnt3;
	reg[3:0] cnt4;
	reg[3:0] cnt5;
	reg c0,c1,c2,c3,c4;
	initial
	begin
		{cnt5,cnt4,cnt3,cnt2,cnt1,cnt0} = INIT_VALUE;
		{c0,c1,c2,c3,c4} = 5'b0;
	end
	
	assign q = {cnt5,cnt4,cnt3,cnt2,cnt1,cnt0};
	
	always@(posedge clk or negedge i_rst_n)
	if(!i_rst_n)
		{cnt5,cnt4,cnt3,cnt2,cnt1,cnt0,c4,c3,c2,c1,c0} <= {INIT_VALUE,5'b0};
	else if(i_en)
	begin
		c0 <= (&cnt0[3:1])&(~cnt0[0]);
		c1 <= &cnt1;
		c2 <= &cnt2;
		c3 <= &cnt3;
		c4 <= &cnt4;
		
		cnt0 <= cnt0 + 1'b1;
		
		if(c0)
			cnt1 <= cnt1 + 1'b1;
		  
		if(c0 & c1)
			cnt2 <= cnt2 + 1'b1;
		  
		if(c0 & c1 & c2)
			cnt3 <= cnt3 + 1'b1;
		  
		if(c0 & c1 & c2 & c3)
			cnt4 <= cnt4 + 1'b1;
		  
		if(c0 & c1 & c2 & c3 & c4)
			cnt5 <= cnt5 + 1'b1;
	end

endmodule 

module counter16
#(parameter INIT_VALUE=16'd0)
(input i_clk, input i_rst_n, input i_en, output [15:0] q);

	reg[3:0] cnt0;
	reg[3:0] cnt1;
	reg[3:0] cnt2;
	reg[3:0] cnt3;
	reg c0,c1,c2;
	initial
	begin
		{cnt3,cnt2,cnt1,cnt0} = INIT_VALUE;
		{c0,c1,c2} = 3'b0;
	end
	
	assign q = {cnt3,cnt2,cnt1,cnt0};
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
		{cnt3,cnt2,cnt1,cnt0,c2,c1,c0} <= {INIT_VALUE,3'b0};
	else if(i_en)
	begin	
		c0 <= (&cnt0[3:1])&(~cnt0[0]);
		c1 <= &cnt1;
		c2 <= &cnt2;
		
		cnt0 <= cnt0 + 1'b1;
		
		if(c0)
			cnt1 <= cnt1 + 1'b1;
		  
		if(c0 & c1)
			cnt2 <= cnt2 + 1'b1;
		  
		if(c0 & c1 & c2)
			cnt3 <= cnt3 + 1'b1;
	end

endmodule 

module counter16Mod
#(
	parameter INIT_VALUE = 16'd0,
	parameter MIN_VALUE = 16'd0,
	parameter MAX_VALUE = 16'd65535
)
(input i_clk, input i_rst_n, input i_init, input i_en, output [15:0] q);

	reg[3:0] cnt0;
	reg[3:0] cnt1;
	reg[3:0] cnt2;
	reg[3:0] cnt3;
	reg c0,c1,c2;
	initial
	begin
		{cnt3,cnt2,cnt1,cnt0} = INIT_VALUE;
		{c0,c1,c2} = 3'b0;
	end
	
	assign q = {cnt3,cnt2,cnt1,cnt0};
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
		{cnt3,cnt2,cnt1,cnt0,c2,c1,c0} <= {INIT_VALUE,3'b0};
	else if(i_init)
		{cnt3,cnt2,cnt1,cnt0,c2,c1,c0} <= {INIT_VALUE,3'b0};
	else if(i_en)
	begin	
		if({cnt3,cnt2,cnt1,cnt0} == MAX_VALUE)
			{cnt3,cnt2,cnt1,cnt0,c2,c1,c0} <= {MIN_VALUE,3'b0};
		else
		begin
			c0 <= (&cnt0[3:1])&(~cnt0[0]);
			c1 <= &cnt1;
			c2 <= &cnt2;
			
			cnt0 <= cnt0 + 1'b1;
			
			if(c0)
				cnt1 <= cnt1 + 1'b1;
			  
			if(c0 & c1)
				cnt2 <= cnt2 + 1'b1;
			  
			if(c0 & c1 & c2)
				cnt3 <= cnt3 + 1'b1;
		end
	end

endmodule 

module counter16Mod_d
#(
	parameter INIT_VALUE = 16'd0,
	parameter MIN_VALUE = 16'd0,
	parameter MAX_VALUE_WIDTH = 16
)
(input i_clk, input i_rst_n, input i_en, input [MAX_VALUE_WIDTH-1:0] MAX_VALUE, output [15:0] q);

	reg[3:0] cnt0;
	reg[3:0] cnt1;
	reg[3:0] cnt2;
	reg[3:0] cnt3;
	reg c0,c1,c2;
	initial
	begin
		{cnt3,cnt2,cnt1,cnt0} = INIT_VALUE;
		{c0,c1,c2} = 3'b0;
	end
	
	assign q = {cnt3,cnt2,cnt1,cnt0};
	
	always@(posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
		{cnt3,cnt2,cnt1,cnt0,c2,c1,c0} <= {INIT_VALUE,3'b0};
	else if(i_en)
	begin	
		if({cnt3,cnt2,cnt1,cnt0} == MAX_VALUE)
			{cnt3,cnt2,cnt1,cnt0,c2,c1,c0} <= {MIN_VALUE,3'b0};
		else
		begin
			c0 <= (&cnt0[3:1])&(~cnt0[0]);
			c1 <= &cnt1;
			c2 <= &cnt2;
			
			cnt0 <= cnt0 + 1'b1;
			
			if(c0)
				cnt1 <= cnt1 + 1'b1;
			  
			if(c0 & c1)
				cnt2 <= cnt2 + 1'b1;
			  
			if(c0 & c1 & c2)
				cnt3 <= cnt3 + 1'b1;
		end
	end

endmodule 

module counter12Mod
#(
	parameter SET_VALUE = 12'd0,
	parameter MIN_VALUE = 12'd0,
	parameter MAX_VALUE = 12'd100
)
(input clk, input init, output [11:0] q);

	reg[3:0] cnt0;
	reg[3:0] cnt1;
	reg[3:0] cnt2;
	reg c0,c1;
	initial
	begin
		{cnt2,cnt1,cnt0} = MIN_VALUE;
		{c0,c1} = 2'b0;
	end
	
	assign q = {cnt2,cnt1,cnt0};
	
	always@(posedge clk)
	if(init)
		{cnt2,cnt1,cnt0,c1,c0} <= {SET_VALUE,2'b0};
	else
	begin
		if({cnt2,cnt1,cnt0} == MAX_VALUE)
			{cnt2,cnt1,cnt0,c1,c0} <= {MIN_VALUE,2'b0};
		else
		begin
			c0 <= (&cnt0[3:1])&(~cnt0[0]);
			c1 <= &cnt1;
			
			cnt0 <= cnt0 + 1'b1;
			
			if(c0)
				cnt1 <= cnt1 + 1'b1;
			  
			if(c0 & c1)
				cnt2 <= cnt2 + 1'b1;
		end
	end

endmodule 

module counter12
#(
	parameter SET_VALUE = 12'd0
)
(input clk, input init, input i_en, output [11:0] q);

	reg[3:0] cnt0;
	reg[3:0] cnt1;
	reg[3:0] cnt2;
	reg c0,c1;
	initial
	begin
		{cnt2,cnt1,cnt0} = 12'b0;
		{c0,c1} = 2'b0;
	end
	
	assign q = {cnt2,cnt1,cnt0};
	
	always@(posedge clk)
	if(init)
		{cnt2,cnt1,cnt0,c1,c0} <= {SET_VALUE,2'b0};
	else if(i_en)
	begin
		c0 <= (&cnt0[3:1])&(~cnt0[0]);
		c1 <= &cnt1;
		
		cnt0 <= cnt0 + 1'b1;
		
		if(c0)
			cnt1 <= cnt1 + 1'b1;
		  
		if(c0 & c1)
			cnt2 <= cnt2 + 1'b1;
	end

endmodule 

