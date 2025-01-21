//Author : Kevin GUILLOUX
//Last modified : 04/07/2024
//Comment : Shifter for right arithmetic shifts, fixed in shifting value(passed in parameter), configurable for data lenght, default : 32 bits for data and 1 for shifting value
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 10/05/2024
// Design Name: fixed_shifter_right_arithmetic.sv
// Module Name: fixed_shifter_right_arithmetic
// Project Name: RISCV_RV32i_pipeline
// Description: Shifter for right arithmetic shifts, fixed in shifting value(passed in parameter), configurable for 
//             data lenght, default : 32 bits for data and 1 for shifting value
//
// Dependencies: 
// configurable_mux.sv
//
// Current revision : 1.1
// Last modification : 04/07/2024
//
// Revision: 1.1
// Additional Comments: Bug corrected.
//
// Revision: 1.0
// Additional Comments: Tested and working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module fixed_shifter_right_arithmetic #(
	parameter nb_bits_data = 32,
	parameter shift_value = 1
)(
	input logic [nb_bits_data-1:0] data_i,
	input logic enable_i,
	output logic [nb_bits_data-1:0] data_o
);
	//Internal connections declaration
	logic [nb_bits_data-1:0] data_s;
	integer i;
	//Mux declaration
	configurable_mux #(1,nb_bits_data) MUX (
		.data_i({data_s,
			data_i}),
		.sel_i(enable_i),
		.data_o(data_o)
	);
	//Shift of the bits by the fixed value
	always_ff @(data_i or enable_i) begin : al_process
	   if (data_i[nb_bits_data-1]==1'b1) begin
	       for (i=0;i<shift_value;i++) begin : fr_boucle_neg
	           data_s[nb_bits_data-i-1] <= 1'b1;
	       end : fr_boucle_neg
	   end
	   else begin
	       for (i=0;i<shift_value;i++) begin : fr_boucle_pos
	           data_s[nb_bits_data-i-1] <= 1'b0;
	       end : fr_boucle_pos
	   end
	   data_s[nb_bits_data-shift_value-1:0] <= data_i[nb_bits_data-1:shift_value];
	end : al_process		
endmodule : fixed_shifter_right_arithmetic
