//Author : Kevin GUILLOUX
//Last modified : 10/05/2024
//Comment : Testbench of the substract module n bits, used on 32 bits

`timescale 1ns/1ps

module substract_tb ();
	logic [31:0] A_s, B_s;
	logic Bin_s;
	logic [31:0] S_s;
	logic Bout_s;
	//Tested module declaration
	substract #(32) DUT (
		.A_i(A_s),
		.B_i(B_s),
		.Bin_i(Bin_s),
		.Bout_o(Bout_s),
		.S_o(S_s)
	);
	//Test
	initial begin
		A_s = 32'h00000000;
		B_s = 32'h00000000;
		Bin_s = 1'b0;
		#20;
		A_s = 32'h00000001;
		B_s = 32'h00000001;
		Bin_s = 1'b0;
		#20;
		A_s = 32'h00000001;
		B_s = 32'h00000001;
		Bin_s = 1'b1;
		#20;
		A_s = 32'h12345678;
		B_s = 32'hfedcba98;
		Bin_s = 1'b0;
		#20;
		A_s = 32'h12345678;
		B_s = 32'hfedcba98;
		Bin_s = 1'b1;
		#20;
		A_s = 32'hfedcba98;
		B_s = 32'h12345678;
		Bin_s = 1'b0;
		#20;
		A_s = 32'hfedcba98;
		B_s = 32'h12345678;
		Bin_s = 1'b1;
		#20;
		A_s = 32'hffffffd6;
		B_s = 32'h00000098;
		Bin_s = 1'b0;
		#20;
		A_s = 32'h00000098;
		B_s = 32'hffffffd6;
		Bin_s = 1'b0;
	end
endmodule : substract_tb
