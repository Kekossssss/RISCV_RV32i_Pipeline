//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 10/05/2024
// Design Name: shifter_right_logical.sv
// Module Name: shifter_right_logical
// Project Name: RISCV_RV32i_pipeline
// Description: Shifter for right logical shifts, configurable, default : 32 bits for data and 5 bits for shifting value
//
// Dependencies: 
// fixed_shifter_right_logical.sv
//
// Current revision : 1.0
// Last modification : 10/05/2024
//
// Revision: 1.0
// Additional Comments: Tested and working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module shifter_right_logical #(
	parameter nb_bits_data = 32,
	parameter nb_bits_shift = 5
)(
	input logic [nb_bits_data-1:0] data_i,
	input logic [nb_bits_shift-1:0] shift_value_i,
	output logic [nb_bits_data-1:0] data_o
);
	//Internal connections description
	logic [nb_bits_shift:0][nb_bits_data-1:0] inter_fixed_shifter_connect_s;
	genvar i;
	//Assignation of values
	generate
		for (i=0;i<nb_bits_shift;i++) begin : g_label1
			fixed_shifter_right_logical #(nb_bits_data,2**i) SHIFTER (
				.data_i(inter_fixed_shifter_connect_s[i]),
				.enable_i(shift_value_i[i]),
				.data_o(inter_fixed_shifter_connect_s[i+1])
			);
		end : g_label1
	endgenerate
	assign inter_fixed_shifter_connect_s[0] = data_i;
	assign data_o = inter_fixed_shifter_connect_s[nb_bits_shift];
endmodule : shifter_right_logical
