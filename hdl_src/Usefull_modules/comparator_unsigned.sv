//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 10/05/2024
// Design Name: comparator_unsigned.sv
// Module Name: comparator_unsigned
// Project Name: RISCV_RV32i_pipeline
// Description: Comparator module for unsigned values, configurable in input data lengths, default to single bit operations
//
// Dependencies: 
// comparator_1bit_unsigned.sv
//
// Current revision : 1.0
// Last modification : 10/05/2024
//
// Revision: 1.0
// Additional Comments: Tested and working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module comparator_unsigned #(
	parameter nb_bits = 32
)(
	input logic [nb_bits-1:0] A_i, B_i,
	output logic greater_o, equal_o, lesser_o
);
	//Internal connections declaration
	logic [nb_bits-1:0] greater_s, equal_s, lesser_s;
	genvar i;
	//Module declaration
	comparator_1bit_unsigned COMP0 (
		.A_i(A_i[0]),
		.B_i(B_i[0]),
		.greater_i(1'b0),
		.equal_i(1'b1),
		.lesser_i(1'b0),
		.greater_o(greater_s[0]),
		.equal_o(equal_s[0]),
		.lesser_o(lesser_s[0])
	);
	generate
		for (i=1;i<nb_bits;i++) begin : comp
			comparator_1bit_unsigned COMP0 (
				.A_i(A_i[i]),
				.B_i(B_i[i]),
				.greater_i(greater_s[i-1]),
				.equal_i(equal_s[i-1]),
				.lesser_i(lesser_s[i-1]),
				.greater_o(greater_s[i]),
				.equal_o(equal_s[i]),
				.lesser_o(lesser_s[i])
			);
		end : comp
	endgenerate
	//Final value assignation
	assign greater_o = greater_s[nb_bits-1];
	assign equal_o = equal_s[nb_bits-1];
	assign lesser_o = lesser_s[nb_bits-1];
endmodule : comparator_unsigned
