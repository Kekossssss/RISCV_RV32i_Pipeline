//Author : Kevin GUILLOUX
//Last modified : 10/05/2024
//Comment : TestBench of the configurable NOT gate, used in 32 bits mode

`timescale 1ns/1ps

module not_gate_tb ();
	logic [31:0] a_s;
	logic [31:0] s_s;
	//Tested module declaration
	not_gate DUT (
		.a_i(a_s),
		.s_o(s_s)
	);
	//Test
	initial begin
		a_s = 32'h00000000;
		#20;
		a_s = 32'hffffffff;
		#20;
		a_s = 32'h12345678;
	end
endmodule : not_gate_tb
