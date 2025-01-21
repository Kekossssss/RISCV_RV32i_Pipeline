//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 10/05/2024
// Design Name: configurable_mux.sv
// Module Name: configurable_mux
// Project Name: RISCV_RV32i_pipeline
// Description: Multiplexer configurable in order to be used in every configurations
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

module configurable_mux #(
	parameter nb_bits_select = 1,
	parameter nb_bits_taille_donnes = 1
)(
	//Input is made under a table form
	input logic [2**(nb_bits_select)-1:0][nb_bits_taille_donnes-1:0] data_i,
	//Selection input, to select which input to redirect on the output
	input logic [nb_bits_select-1:0] sel_i,
	//Output in the form of a single data signal
	output logic [nb_bits_taille_donnes-1:0] data_o
);
	assign data_o = data_i[sel_i];
endmodule : configurable_mux
