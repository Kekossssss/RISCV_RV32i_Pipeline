//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 10/05/2024
// Design Name: substract.sv
// Module Name: substract
// Project Name: RISCV_RV32i_pipeline
// Description: Subtract module working on any number of bits. Input and output values are signed by the 
//             method of the 2's complement
//
// Dependencies: 
// not_gate.sv
// adder.sv
//
// Current revision : 1.0
// Last modification : 10/05/2024
//
// Revision: 1.0
// Additional Comments: Tested and working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module substract #(
	parameter nb_bits = 32
)(
	//Input signed values
	input logic [nb_bits - 1:0] A_i, B_i,
	//Input borrow, indicates if 1 is retired to the final result (If Bin_i==1, the result get substracted by 1)
	input logic Bin_i,
	//Signed result
	output logic [nb_bits - 1:0] S_o,
	//Output borrow, indicate the output value sign (If Bout_o==1, the result is negatif)
	output logic Bout_o
);
	//Internal connections declaration
	logic [nb_bits - 1:0] non_B_s;
	logic [nb_bits - 1:0] carry_s;
	logic non_Bin_s;
	genvar i;
	//Module declaration
	not_gate #(0,32) NOT1 (
		.a_i(B_i),
		.s_o(non_B_s)
	);
	not_gate #(0,1) NOT2 (
		.a_i(Bin_i),
		.s_o(non_Bin_s)
	);
	adder adder0 (
		.A_i(A_i[0]),
		.B_i(non_B_s[0]),
		.Cin_i(non_Bin_s),
		.Cout_o(carry_s[0]),
		.S_o(S_o[0])
	);
	generate
		for (i=1;i<nb_bits;i++) begin : g_label1
			adder adder_inst (
				.A_i(A_i[i]),
				.B_i(non_B_s[i]),
				.Cin_i(carry_s[i-1]),
				.Cout_o(carry_s[i]),
				.S_o(S_o[i])
			);
		end : g_label1
	endgenerate
	//Borrow value, inversed in order to be equal to 1 if the output value is negative
	assign Bout_o = S_o[nb_bits-1];
endmodule : substract
