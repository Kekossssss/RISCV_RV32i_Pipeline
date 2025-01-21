//Author : Kevin GUILLOUX
//Last modified : 10/05/2024
//Comment : Testbench of the comparator signed module n bits, used on 32 bits

`timescale 1ns/1ps

module comparator_signed_tb ();
	logic [31:0] A_s, B_s;
	logic greater_s, equal_s, lesser_s;
	//Tested module declaration
	comparator_signed #(32) DUT (
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
		A_s = 32'h0fedcba9;
		B_s = 32'h01234567;
		#20;
		A_s = 32'h01234567;
		B_s = 32'h0fedcba9;
		#20;
		A_s = 32'h0fedcba9;
		B_s = 32'h0fedcba9;
		#20;
		A_s = 32'h00000098;
		B_s = 32'hffffffd6;
		#20;
		A_s = 32'hffffffd6;
		B_s = 32'h00000098;
		#20;
		A_s = 32'hffffff00;
		B_s = 32'hffffffe5;
		#20;
		A_s = 32'hffffffe5;
		B_s = 32'hffffff00;
		#20;
		A_s = 32'hffffffe5;
		B_s = 32'hffffffe5;
	end
endmodule : comparator_signed_tb
