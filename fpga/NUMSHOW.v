module NUMSHOW
(
	input clk, 
	input[31:0]num, 
	output reg[6:0] one, 
	output reg[7:0] sel
);

	
	parameter NA = ~8'b0;
	parameter N7 = ~8'b10000000;
	parameter N6 = ~8'b1000000;
	parameter N5 = ~8'b100000;
	parameter N4 = ~8'b10000;
	parameter N3 = ~8'b1000;
	parameter N2 = ~8'b100;
	parameter N1 = ~8'b10;
	parameter N0 = ~8'b1;
	parameter S7 = 10000000;
	parameter S6 = 1000000;
	parameter S5 = 100000;
	parameter S4 = 10000;
	parameter S3 = 1000;
	parameter S2 = 100;
	parameter S1 = 10;
	
	
	wire [31:0]i7,i6,i5,i4,i3,i2,i1,i0;
	wire [6:0]o7,o6,o5,o4,o3,o2,o1,o0;
	
	encode e7(i7[3:0], o7);
	encode e6(i6[3:0], o6);
	encode e5(i5[3:0], o5);
	encode e4(i4[3:0], o4);
	encode e3(i3[3:0], o3);
	encode e2(i2[3:0], o2);
	encode e1(i1[3:0], o1);
	encode e0(i0[3:0], o0);
	
	assign i7 = num / S7;
	assign i6 = num % S7 / S6;
	assign i5 = num % S6 / S5;
	assign i4 = num % S5 / S4;
	assign i3 = num % S4 / S3;
	assign i2 = num % S3 / S2;
	assign i1 = num % S2 / S1;
	assign i0 = num % S1;
	
	always@(posedge clk)
	case(sel)
	NA: {sel,one} <= {N0,o0};
	N0: {sel,one} <= {N1,o1};
	N1: {sel,one} <= {N2,o2};
	N2: {sel,one} <= {N3,o3};
	N3: {sel,one} <= {N4,o4};
	N4: {sel,one} <= {N5,o5};
	N5: {sel,one} <= {N6,o6};
	N6: {sel,one} <= {N7,o7};
	N7: {sel,one} <= {N0,o0};
	default: {sel,one} <= {NA,7'b1111111};
	endcase

endmodule

module encode(raw, code);
	input [3:0] raw;
	output reg [6:0] code;
  /*
	0xc0,0xf9,0xa4,0xb0,//0~3
	0x99,0x92,0x82,0xf8,//4~7
	0x80,0x90,0x88,0x83,//8~b
	0xc6,0xa1,0x86,0x8e //c~f
*/
	always@(raw)
	begin
		case(raw)
			4'd0: code = 7'h40;
			4'd1: code = 7'h79;
			4'd2: code = 7'h24;
			4'd3: code = 7'h30;
			4'd4: code = 7'h19;
			4'd5: code = 7'h12;
			4'd6: code = 7'h02;
			4'd7: code = 7'h78;
			4'd8: code = 7'h00;
			4'd9: code = 7'h10;
			default: code = 7'b1111111;
		endcase
	end

endmodule

