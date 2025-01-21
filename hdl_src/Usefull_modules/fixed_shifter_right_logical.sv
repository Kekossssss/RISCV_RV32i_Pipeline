//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 10/05/2024
// Design Name: fixed_shifter_right_logical.sv
// Module Name: fixed_shifter_right_logical
// Project Name: RISCV_RV32i_pipeline
// Description: Shifter for right logical shifts, fixed in shifting value(passed in parameter), configurable for 
//             data lenght, default : 32 bits for data and 1 for shifting value
//
// Dependencies: 
// configurable_mux.sv
//
// Current revision : 1.0
// Last modification : 10/05/2024
//
// Revision: 1.0
// Additional Comments: Tested and working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module fixed_shifter_right_logical #(
	parameter nb_bits_data = 32,
	parameter shift_value = 1
)(
	input logic [nb_bits_data-1:0] data_i,
	input logic enable_i,
	output logic [nb_bits_data-1:0] data_o
);
	//Internal connections declaration
	logic [nb_bits_data-1:0] data_s;
	//Mux declaration
	configurable_mux #(1,nb_bits_data) MUX (
		.data_i({data_s,
			data_i}),
		.sel_i(enable_i),
		.data_o(data_o)
	);
	//Shift of the bits by the fixed value
	assign data_s[nb_bits_data - shift_value-1:0] = data_i[nb_bits_data-1:shift_value];
	assign data_s[nb_bits_data-1:nb_bits_data - shift_value] = 0;
endmodule : fixed_shifter_right_logical
