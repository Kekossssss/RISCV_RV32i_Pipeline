//Author : Kevin GUILLOUX
//Last modified : 10/05/2024
//Comment : TestBench of the configurable AND gate, used in 32 bits mode

`timescale 1ns/1ps

module and_gate_tb ();
	logic [31:0] a_s, b_s;
	logic [31:0] s_s;
	//Tested module declaration
	and_gate DUT (
		.a_i(a_s),
		.b_i(b_s),
		.s_o(s_s)
	);
	//Test
	initial begin
		a_s = 32'h00000000;
		b_s = 32'h00000000;
		#20;
		a_s = 32'hffffffff;
		#20;
		b_s = 32'hffff0000;
		#20;
		a_s = 32'h12345678;
		#20;
		b_s = 32'hfedcba98;
	end
endmodule : and_gate_tb
