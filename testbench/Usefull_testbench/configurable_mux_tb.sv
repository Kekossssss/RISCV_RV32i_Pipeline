//Author : Kevin GUILLOUX
//Last modified : 10/05/2024
//Comment : Testbench of the configurable mux

`timescale 1ns/1ps

module configurable_mux_tb ();
	logic [3:0][31:0] data_i_s;
	logic [1:0] sel_s;
	logic [31:0] data_o_s;
	//Tested module declaration
	configurable_mux #(2,32) DUT (
		.data_i(data_i_s),
		.sel_i(sel_s),
		.data_o(data_o_s)
	);
	//Test
	initial begin
		data_i_s[0] = 32'h12345678;
		data_i_s[1] = 32'hfedcba98;
		data_i_s[2] = 32'h00000000;
		data_i_s[3] = 32'hffffffff;
		sel_s = 2'h0;
		#20;
		sel_s = 2'h1;
		#20;
		sel_s = 2'h2;
		#20;
		sel_s = 2'h3;
	end
endmodule : configurable_mux_tb
