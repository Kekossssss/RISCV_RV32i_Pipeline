//Author : Kevin GUILLOUX
//Last modified : 10/05/2024
//Comment : Testbench of the comparator unsigned module n bits, used on 32 bits

`timescale 1ns/1ps

module comparator_unsigned_tb ();
	logic [31:0] A_s, B_s;
	logic greater_s, equal_s, lesser_s;
	//Tested module declaration
	comparator_unsigned #(32) DUT (
		.A_i(A_s),
		.B_i(B_s),
		.greater_o(greater_s),
		.equal_o(equal_s),
		.lesser_o(lesser_s)
	);
	//Test
	initial begin
		A_s = 32'h00000000;
		B_s = 32'h00000000;
		#20;
		A_s = 32'h00000001;
		B_s = 32'h00000000;
		#20;
		A_s = 32'hfedcba98;
		B_s = 32'h12345678;
		#20;
		A_s = 32'h12345678;
		B_s = 32'hfedcba98;
		#20;
		A_s = 32'hfedcba98;
		B_s = 32'hfedcba98;
	end
endmodule : comparator_unsigned_tb
