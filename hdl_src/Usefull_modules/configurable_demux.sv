//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 11/05/2024
// Design Name: configurable_demux.sv
// Module Name: configurable_demux
// Project Name: RISCV_RV32i_pipeline
// Description: Demultiplexer configurable in order to be used in every configurations
//
// Dependencies: x
//
// Current revision : 1.0
// Last modification : 11/05/2024
//
// Revision: 1.0
// Additional Comments: Tested and working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module configurable_demux #(
	parameter nb_bits_select = 1,
	parameter nb_bits_taille_donnes = 1
)(
	//Input in the form of a single data signal
	input logic [nb_bits_taille_donnes-1:0] data_i,
	//Selection input, to select which input to redirect on the output
	input logic [nb_bits_select-1:0] sel_i,
	//Output is made under a table form
	output logic [2**(nb_bits_select)-1:0][nb_bits_taille_donnes-1:0] data_o
);
    //Internal connection declaration
    logic [2**(nb_bits_select)-1:0] select_decode;
	assign select_decode = (1 << sel_i);
	always_comb begin
        for (int i = 0; i < 2**(nb_bits_select); i++) begin
            if (select_decode[i]) // Sélectionne la sortie appropriée
                data_o[i] = data_i;
            else
                data_o[i] = '0; // Met à zéro les sorties non sélectionnées
        end
    end
endmodule : configurable_demux