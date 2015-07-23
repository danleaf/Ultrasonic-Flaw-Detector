module inc8b
(
	input n,
	output n1
);

endmodule


module inc8br
#(
	parameter MAX = 8'd255,
	parameter MIN = 8'd0
)
(
	input	[7:0] n,
	output	[7:0] n1
);

endmodule
