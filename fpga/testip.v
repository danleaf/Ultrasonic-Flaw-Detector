
`timescale 1ns/1ps

module test();
  reg clk,rst_n;
  reg trig;
  wire ready,wren;
  wire [4:0] iph_idx;
  wire [7:0] byte;
  
  reg  [7:0] iph [19:0];
  reg [1:0] cmd;
  
  initial
  begin
    clk = 0;
    rst_n = 1'b1;
    trig = 0;
    cmd  = 0;
    #1 rst_n = 0;
    #7 rst_n = 1'b1;
    #2 trig =  1'd1;
    #8 trig = 0;
    #160 cmd = 2;
    #8  cmd = 0;
    #160 trig  = 1;
    #8  trig =  0;
    #160 cmd = 1;
    #8  cmd = 0;
    #160 trig  = 1;
    #8  trig =  0;
  end

  always #4 clk = ~clk;
  
  always@(posedge clk)
  begin
    if(wren)
      iph[iph_idx] <= byte;
  end
  
  
ip i0
(
	.i_clk(clk),
	.i_rst_n(rst_n),
	.i_trig(trig),
	.i_data_length(16'd800),
	.i_ip0(8'd192),
	.i_ip1(8'd168),
	.i_ip2(8'd1),
	.i_ip3(8'd253),
	.i_cmd(cmd),					
	.o_iph_idx(iph_idx),
	.o_iph_byte(byte),	
	.o_wr_iph_en(wren),
	.o_ready(ready)
);

endmodule

