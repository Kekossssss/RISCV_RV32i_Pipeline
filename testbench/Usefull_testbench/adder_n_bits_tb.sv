//Author : Kevin GUILLOUX
//Last modified : 09/05/2024
//Comment : Testbench of the n bits adder, used in 32 bits mode for the testing

`timescale 1ns/1ps

module adder_n_bits_tb ();
	logic [31:0] A_s, B_s;
	logic Cin_s;
	logic [31:0] S_s;
	logic Cout_s;
	//Tested module declaration
	adder_n_bits #(32) DUT (
		.A_i(A_s),
		.B_i(B_s),
		.Cin_i(Cin_s),
		.Cout_o(Cout_s),
		.S_o(S_s)
	);
	//Test
	initial begin
		A_s = 32'h00000000;
		B_s = 32'h00000000;
		Cin_s = 1'b0;
		#20;
		A_s = 32'h00000001;
		B_s = 32'h00000001;
		Cin_s = 1'b0;
		#20;
		A_s = 32'h00000001;
		B_s = 32'h00000001;
		Cin_s = 1'b1;
		#20;
		A_s = 32'h12345678;
		B_s = 32'hfedcba98;
		Cin_s = 1'b0;
		#20;
		A_s = 32'h12345678;
		B_s = 32'hfedcba98;
		Cin_s = 1'b1;
	end
endmodule : adder_n_bits_tb
