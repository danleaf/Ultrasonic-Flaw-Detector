module phy_reset (
							input clk,
							input rst,
							
							output reg phy_rst);
							
reg[2:0] rst_cnt;

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		rst_cnt <= 3'd0;
	end
	else begin
		if(rst_cnt < 3'd7)begin
			rst_cnt <= rst_cnt + 1'b1;
		end
	end
end

always@(posedge clk or negedge rst)begin
	if(!rst)begin
		phy_rst <= 1'b0;
	end
	else if(rst_cnt < 3'd7)begin
		phy_rst <= 1'b0;
	end
	else begin
		phy_rst <= 1'b1;
	end
end

endmodule
