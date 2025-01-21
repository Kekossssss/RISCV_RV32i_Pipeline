//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 10/05/2024
// Design Name: and_gate.sv
// Module Name: and_gate
// Project Name: RISCV_RV32i_pipeline
// Description: Configurable AND gate configurable, on single bit mode in basic mode
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

module and_gate #(
	parameter delay = 0,
	parameter nb_bits = 1)
(
	input logic [nb_bits-1:0] a_i, b_i,
	output logic [nb_bits-1:0] s_o
);
	assign #delay s_o = a_i & b_i;
endmodule : and_gate
