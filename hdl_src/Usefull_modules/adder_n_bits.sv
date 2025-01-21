//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 10/05/2024
// Design Name: adder_n_bits.sv
// Module Name: adder_n_bits
// Project Name: RISCV_RV32i_pipeline
// Description: N bits complete adder, with carry flag on input and output. Configured for 32 bits by default
//
// Dependencies: 
// adder.sv
//
// Current revision : 1.0
// Last modification : 10/05/2024
//
// Revision: 1.0
// Additional Comments: Tested and working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module adder_n_bits #(
	parameter nb_bits = 32
)(
	input logic [nb_bits - 1:0] A_i, B_i,
	input logic Cin_i,
	output logic [nb_bits - 1:0] S_o,
	output logic Cout_o
);
	//Internal connections declaration
	logic [nb_bits - 1:0] carry_s;
	genvar i;
	//Modules declaration
	adder adder0 (
		.A_i(A_i[0]),
		.B_i(B_i[0]),
		.Cin_i(Cin_i),
		.Cout_o(carry_s[0]),
		.S_o(S_o[0])
	);
	generate
		for (i=1;i<nb_bits;i++) begin : g_label1
			adder adder_inst (
				.A_i(A_i[i]),
				.B_i(B_i[i]),
				.Cin_i(carry_s[i-1]),
				.Cout_o(carry_s[i]),
				.S_o(S_o[i])
			);
		end : g_label1
	endgenerate
	assign Cout_o = carry_s[nb_bits-1];
endmodule : adder_n_bits
