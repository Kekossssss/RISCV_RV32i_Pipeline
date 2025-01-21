//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 10/05/2024
// Design Name: half_adder.sv
// Module Name: half_adder
// Project Name: RISCV_RV32i_pipeline
// Description: Adder module that doesn't take carry flags in input
//
// Dependencies: x
//
// Current revision : 1.0
// Last modification : 10/05/2024
//
// Revision: 1.0
// Additional Comments: Tested and working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module half_adder (
	input logic a_i, b_i,
	output logic s_o, c_o
);
	assign s_o = (a_i ^ b_i);
	assign c_o = (a_i & b_i);
endmodule : half_adder
