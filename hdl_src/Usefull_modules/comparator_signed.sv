//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 10/05/2024
// Design Name: comparator_signed.sv
// Module Name: comparator_signed
// Project Name: RISCV_RV32i_pipeline
// Description: Comparator module for signed values, configurable in input data lengths, default to single bit operations
//
// Dependencies: 
// substract.sv
// comparator_unsigned.sv
// and_gate.sv
//
// Current revision : 1.0
// Last modification : 10/05/2024
//
// Revision: 1.0
// Additional Comments: Tested and working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module comparator_signed #(
	parameter nb_bits = 32
)(
	input logic [nb_bits-1:0] A_i, B_i,
	output logic greater_o, equal_o, lesser_o
);
	//Internal connection declaration
	logic neg_s, equal_s;
	//Module declaration
	substract #(nb_bits) SUB (
		.A_i(A_i),
		.B_i(B_i),
		.Bin_i(0),
		.Bout_o(neg_s)
	);
	comparator_unsigned #(nb_bits) COMP_U (
		.A_i(A_i),
		.B_i(B_i),
		.equal_o(equal_s)
	);
	and_gate #(0,1) AND_GREATER (
		.a_i(~neg_s),
		.b_i(~equal_s),
		.s_o(greater_o)
	);
	and_gate #(0,1) AND_LESSER (
		.a_i(neg_s),
		.b_i(~equal_s),
		.s_o(lesser_o)
	);
	//Output value assignation
	assign equal_o = equal_s;
endmodule : comparator_signed
