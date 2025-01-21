//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 10/05/2024
// Design Name: not_gate.sv
// Module Name: not_gate
// Project Name: RISCV_RV32i_pipeline
// Description: Configurable NOT gate configurable, on single bit mode in basic mode
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

module not_gate #(
	parameter delay = 0,
	parameter nb_bits_g = 1
) (

	input logic [nb_bits_g - 1 : 0] a_i,
	output logic [nb_bits_g - 1 : 0] s_o
);
	assign #delay s_o = ~ a_i;
endmodule : not_gate
