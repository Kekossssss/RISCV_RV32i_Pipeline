//Author : Kevin GUILLOUX
//Last modified : 11/05/2024
//Comment : Testbench of the configurable demux

`timescale 1ns/1ps

module configurable_demux_tb ();
	logic [31:0] data_i_s;
	logic [1:0] sel_s;
	logic [3:0][31:0] data_o_s;
	//Tested module declaration
	configurable_demux #(2,32) DUT (
		.data_i(data_i_s),
		.sel_i(sel_s),
		.data_o(data_o_s)
	);
	//Test
	initial begin
		data_i_s = 32'h12345678;
		sel_s = 2'h0;
		#20;
		sel_s = 2'h1;
		#20;
		data_i_s = 32'hfedcba98;
		sel_s = 2'h2;
		#20;
		sel_s = 2'h3;
	end
endmodule : configurable_demux_tb
