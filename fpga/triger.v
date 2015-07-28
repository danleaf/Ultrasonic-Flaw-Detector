//100MHZ
module triger(
	input clk, 
	input rst_n, 
	input en,
	input [19:0] cycle,		//the unit is 10ns
	input [11:0] pulse,		//the unit is 10ns
	output q, 
	output q2,
	output reg [3:0] led, 
	output [7:0] dac_data
);

	localparam fclk = 100000000;
	localparam tick = 10;
	localparam f = 5000;		//1000HZ
	localparam th = 1000;		//1000ns
	localparam div = fclk / f;	
	localparam divh = th / tick;
	
	reg [7:0] data;
	reg [7:0] delay;
	reg [19:0] cnt;
	reg [8:0] cnt2;
	reg s;
	
	assign q = s;
	assign q2 = delay[0];
	//assign dac_data = data;
	
	reg [9:0] sinaddr;
	sindata sin(sinaddr,clk,dac_data);
	
	
	always@(posedge clk or negedge rst_n)
	if(!rst_n)
	begin
		cnt <= 1'd1;
		s <= 1'd1;
		data <= 8'd127;
		sinaddr <= 0;
		delay <= 0;
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
			
			data <= 8'd100;
			sinaddr <= sinaddr + 1'd1;
			
			delay <= {delay[6:0],s};
		end
		else
		begin
			cnt <= 1'd1;
			s <= 1'd1;
		end
	end
	
	
	always@(posedge s or negedge rst_n)
	if(!rst_n)
	begin
		cnt2 <= 0;
		led <= 4'd15;
	end
	else
	begin			
		if(led == 4'd15)
			led <= 1'd1;
			
		if(cnt2 == 9'd511)
		begin
			led <= {led[2:0],led[3]};
			cnt2 <= 0;
		end
		else
			cnt2 <= cnt2 + 1'd1;
			
	end
	

endmodule

