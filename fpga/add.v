module add8
(
	input[7:0] A,B,
	input Cin,
	output[7:0] Q,
	output Cout
);
	wire c[6:0];
	
	assign Q[0] = A[0] ^ B[0] ^ Cin;
	assign c[0] = ((A[0] | B[0]) & Cin) | (A[0] & B[0]); 
	
	assign Q[1] = A[1] ^ B[1] ^ c[0];
	assign c[1] = ((A[1] | B[1]) & c[0]) | (A[1] & B[1]); 
	
	assign Q[2] = A[2] ^ B[2] ^ c[1];
	assign c[2] = ((A[2] | B[2]) & c[1]) | (A[2] & B[2]); 
	
	assign Q[3] = A[3] ^ B[3] ^ c[2];
	assign c[3] = ((A[3] | B[3]) & c[2]) | (A[3] & B[3]); 
	
	assign Q[4] = A[4] ^ B[4] ^ c[3];
	assign c[4] = ((A[4] | B[4]) & c[3]) | (A[4] & B[4]); 
	
	assign Q[5] = A[5] ^ B[5] ^ c[4];
	assign c[5] = ((A[5] | B[5]) & c[4]) | (A[5] & B[5]); 
	
	assign Q[6] = A[6] ^ B[6] ^ c[5];
	assign c[6] = ((A[6] | B[6]) & c[5]) | (A[6] & B[6]); 
	
	assign Q[7] = A[7] ^ B[7] ^ c[6];
	assign Cout = ((A[7] | B[7]) & c[6]) | (A[7] & B[7]); 
	
endmodule

module add16
(
	input[15:0] A,B,
	input Cin,
	output[15:0] Q,
	output Cout
);
	wire c[14:0];
	
	assign Q[0] = A[0] ^ B[0] ^ Cin;
	assign c[0] = ((A[0] | B[0]) & Cin) | (A[0] & B[0]); 
	
	assign Q[1] = A[1] ^ B[1] ^ c[0];
	assign c[1] = ((A[1] | B[1]) & c[0]) | (A[1] & B[1]); 
	
	assign Q[2] = A[2] ^ B[2] ^ c[1];
	assign c[2] = ((A[2] | B[2]) & c[1]) | (A[2] & B[2]); 
	
	assign Q[3] = A[3] ^ B[3] ^ c[2];
	assign c[3] = ((A[3] | B[3]) & c[2]) | (A[3] & B[3]); 
	
	assign Q[4] = A[4] ^ B[4] ^ c[3];
	assign c[4] = ((A[4] | B[4]) & c[3]) | (A[4] & B[4]); 
	
	assign Q[5] = A[5] ^ B[5] ^ c[4];
	assign c[5] = ((A[5] | B[5]) & c[4]) | (A[5] & B[5]); 
	
	assign Q[6] = A[6] ^ B[6] ^ c[5];
	assign c[6] = ((A[6] | B[6]) & c[5]) | (A[6] & B[6]); 
	
	assign Q[7] = A[7] ^ B[7] ^ c[6];
	assign c[7] = ((A[7] | B[7]) & c[6]) | (A[7] & B[7]); 
	
	assign Q[8] = A[8] ^ B[8] ^ c[7];
	assign c[8] = ((A[8] | B[8]) & c[7]) | (A[8] & B[8]); 
	
	assign Q[9] = A[9] ^ B[9] ^ c[8];
	assign c[9] = ((A[9] | B[9]) & c[8]) | (A[9] & B[9]); 
	
	assign Q[10] = A[10] ^ B[10] ^ c[9];
	assign c[10] = ((A[10] | B[10]) & c[9]) | (A[10] & B[10]); 
	
	assign Q[11] = A[11] ^ B[11] ^ c[10];
	assign c[11] = ((A[11] | B[11]) & c[10]) | (A[11] & B[11]); 
	
	assign Q[12] = A[12] ^ B[12] ^ c[11];
	assign c[12] = ((A[12] | B[12]) & c[11]) | (A[12] & B[12]); 
	
	assign Q[13] = A[13] ^ B[13] ^ c[12];
	assign c[13] = ((A[13] | B[13]) & c[12]) | (A[13] & B[13]); 
	
	assign Q[14] = A[14] ^ B[14] ^ c[13];
	assign c[14] = ((A[14] | B[14]) & c[13]) | (A[14] & B[14]); 
	
	assign Q[15] = A[15] ^ B[15] ^ c[14];
	assign Cout = ((A[15] | B[15]) & c[14]) | (A[15] & B[15]);
	
	/*wire [16:0] tmp = {1'd0,A} + {1'd0,B} + Cin;
	
	assign Q = tmp[15:0];
	assign Cout = tmp[16];*/
	
endmodule

module inc4(input[3:0] a, input b, output reg[3:0] q, output reg c);

	wire [3:0] tmp,ci;
	
	assign tmp[0] = ~a[0]; 
	assign ci[0] = a[0];
	
	assign tmp[1] = a[0] ^ a[1];
	assign ci[1] = a[1] & a[0];
	
	assign tmp[2] = a[0] & a[1] ^ a[2];
	assign ci[2] = a[0] & a[1] & a[2];
	
	assign tmp[3] = a[0] & a[1] & a[2] ^ a[3];
	assign ci[3] = a[0] & a[1] & a[2] & a[3];

	always@(a or b)
	begin
		if(b)
			{q,c} = {tmp,ci[3]};
		else
			{q,c} = {a,1'd0};
	end

endmodule

module inc8(input[7:0] a, input b, output reg[7:0] q, output reg c);

	wire [7:0] tmp,ci;
	
	assign tmp[0] = ~a[0]; 
	assign ci[0] = a[0];
	
	assign tmp[1] = a[1] ^ ci[0]; 
	assign ci[1] = a[1] & ci[0];
	
	assign tmp[2] = a[2] ^ ci[1]; 
	assign ci[2] = a[2] & ci[1];
	
	assign tmp[3] = a[3] ^ ci[2]; 
	assign ci[3] = a[3] & ci[2];
	
	assign tmp[4] = a[4] ^ ci[3]; 
	assign ci[4] = a[4] & ci[3];
	
	assign tmp[5] = a[5] ^ ci[4]; 
	assign ci[5] = a[5] & ci[4];
	
	assign tmp[6] = a[6] ^ ci[5]; 
	assign ci[6] = a[6] & ci[5];
	
	assign tmp[7] = a[7] ^ ci[6]; 
	assign ci[7] = a[7] & ci[6];
	
	/*assign tmp[1] = a[0] ^ a[1];
	assign ci[1] = a[1] & a[0];
	
	assign tmp[2] = a[0] & a[1] ^ a[2];
	assign ci[2] = a[0] & a[1] & a[2];
	
	assign tmp[3] = a[0] & a[1] & a[2] ^ a[3];
	assign ci[3] = a[0] & a[1] & a[2] & a[3];
	
	assign tmp[4] = a[0] & a[1] & a[2] & a[3] ^ a[4];
	assign ci[4] = a[0] & a[1] & a[2] & a[3] & a[4];
	
	assign tmp[5] = a[0] & a[1] & a[2] & a[3] & a[4] ^ a[5];
	assign ci[5] = a[0] & a[1] & a[2] & a[3] & a[4] & a[5];
	
	assign tmp[6] = a[0] & a[1] & a[2] & a[3] & a[4] & a[5] ^ a[6];
	assign ci[6] = a[0] & a[1] & a[2] & a[3] & a[4] & a[5] & a[6];
	
	assign tmp[7] = a[0] & a[1] & a[2] & a[3] & a[4] & a[5] & a[6] ^ a[7];
	assign ci[7] = a[0] & a[1] & a[2] & a[3] & a[4] & a[5] & a[6] & a[7];*/

	always@(a or b or tmp or ci)
	begin
		if(b)
			{q,c} = {tmp,ci[7]};
		else
			{q,c} = {a,1'd0};
	end

endmodule


module inc16(input[15:0] a, input b, output [15:0] q, output c);

	wire c0;
	
	inc8 i0(a[7:0],b,q[7:0],c0);
	inc8 i1(a[15:8],c0,q[15:8],c);

endmodule


