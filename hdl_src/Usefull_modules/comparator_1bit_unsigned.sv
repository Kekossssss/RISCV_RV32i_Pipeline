//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 10/05/2024
// Design Name: comparator_1bit_unsigned.sv
// Module Name: comparator_1bit_unsigned
// Project Name: RISCV_RV32i_pipeline
// Description: 1 bit comparator for use in a larger scale unsigned comparator
//
// Dependencies: 
// and_gate.sv
// xor_gate.sv
// or_gate.sv
//
// Current revision : 1.0
// Last modification : 10/05/2024
//
// Revision: 1.0
// Additional Comments: Tested and working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module comparator_1bit_unsigned (
	input logic A_i, B_i,
	input logic greater_i, equal_i, lesser_i,
	output logic greater_o, equal_o, lesser_o
);
	//Internal connection declaration
	logic and1_to_or1_s, and2_to_or2_s;
	logic and3_to_or1_s, and4_to_or2_s;
	//Module declaration
	and_gate #(0,1) AND1 (
		.a_i(A_i),
		.b_i(~B_i),
		.s_o(and1_to_or1_s)
	);
	and_gate #(0,1) AND2 (
		.a_i(~A_i),
		.b_i(B_i),
		.s_o(and2_to_or2_s)
	);
	xor_gate #(0,1) XOR (
		.a_i(A_i),
		.b_i(B_i),
		.s_o(xor_out_s)
	);
	and_gate #(0,1) AND3 (
		.a_i(~xor_out_s),
		.b_i(greater_i),
		.s_o(and3_to_or1_s)
	);
	and_gate #(0,1) AND4 (
		.a_i(~xor_out_s),
		.b_i(lesser_i),
		.s_o(and4_to_or2_s)
	);
	and_gate #(0,1) AND5 (
		.a_i(~xor_out_s),
		.b_i(equal_i),
		.s_o(equal_o)
	);
	or_gate #(0,1) OR1 (
		.a_i(and1_to_or1_s),
		.b_i(and3_to_or1_s),
		.s_o(greater_o)
	);
	or_gate #(0,1) OR2 (
		.a_i(and2_to_or2_s),
		.b_i(and4_to_or2_s),
		.s_o(lesser_o)
	);
endmodule : comparator_1bit_unsigned
