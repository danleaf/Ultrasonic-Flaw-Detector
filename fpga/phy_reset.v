module phy_reset (
							input clk,
							input rst,
							
							output reg phy_rst);
							
reg[19:0] rst_cnt;

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		rst_cnt <= 0;
	end
	else begin
		if(rst_cnt < 20'h3)begin
			rst_cnt <= rst_cnt + 1'b1;
		end
	end
end

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		phy_rst <= 1'b0;
	end
	else if(rst_cnt < 20'h3)begin
		phy_rst <= 1'b0;
	end
	else begin
		phy_rst <= 1'b1;
	end
end

endmodule
