//Author : Kevin GUILLOUX
//Last modified : 10/05/2024
//Comment : Testbench for the shifter for right arithmetic shifts, here for 32 bits wide data

`timescale 1ns/1ps

module shifter_right_arithmetic_tb ();
	logic [31:0] data_i_s;
	logic [4:0] shift_value_s;
	logic [31:0] data_o_s;
	//Tested module declaration
	shifter_right_arithmetic #(32,5) DUT (
		.data_i(data_i_s),
		.shift_value_i(shift_value_s),
		.data_o(data_o_s)
	);
	//Test
	initial begin
		data_i_s = 32'h00000001;
		shift_value_s = 5'h00;
		#20;
		shift_value_s = 5'h01;
		#20;
		shift_value_s = 5'h04;
		#20;
		shift_value_s = 5'h0a;
		#20;
		data_i_s = 32'hfedcba98;
		shift_value_s = 5'h00;
		#20;
		shift_value_s = 5'h01;
		#20;
		shift_value_s = 5'h04;
		#20;
		shift_value_s = 5'h0a;
		#20;
		shift_value_s = 5'h1e;
		#20;
		shift_value_s = 5'h1f;
	end
endmodule : shifter_right_arithmetic_tb
