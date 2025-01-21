//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 02/07/2024
// Design Name: imm_gen_v1.sv
// Module Name: imm_gen_v1
// Project Name: RISCV_RV32i_pipeline
// Description: Module allowing to extract the values included in the instructions and to give them out 
//             in a 32 bit format, supports R,I,U,S,J and B Types instructions
//
// Dependencies: 
// configurable_mux.sv
//
// Current revision : 1.1
// Last modification : 09/07/2024
//
// Revision: 1.1
// Additional Comments: Changed the process for I-Type instruction, they now are sign extended, compared 
//                     to zero extend previously
//
// Revision: 1.0
// Additional Comments: Tested and working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

import RISCV32i_Pack::*;

module imm_gen_v1(
    input logic [31:0] instruction_i,
    input logic [2:0] imm_gen_sel_i,
    output logic [31:0] imm_extend_o
    );
    //Internal connection declaration
    logic [31:0] zero_to_mux_s;
    logic [31:0] zero_extend_Itype_to_mux_s;
    logic [31:0] zero_extend_Utype_to_mux_s;
    logic [31:0] zero_extend_Stype_to_mux_s;
    logic [31:0] zero_extend_Jtype_to_mux_s;
    logic [31:0] zero_extend_Itype_jalr_to_mux_s;
    logic [31:0] zero_extend_Btype_to_mux_s;
    //Module declaration
    configurable_mux #(3,32) MUX (
		.data_i({zero_extend_Btype_to_mux_s,
		         zero_extend_Itype_jalr_to_mux_s,
		         zero_extend_Jtype_to_mux_s,
		         zero_extend_Stype_to_mux_s,
		         zero_extend_Utype_to_mux_s,
		         zero_extend_Itype_to_mux_s,
		         zero_to_mux_s}),
		.sel_i(imm_gen_sel_i),
		.data_o(imm_extend_o)
	);
	//Signals assignation
	assign zero_to_mux_s = 32'h00000000;
	////I type instruction (And J/B Type sign extension)
	always_ff @(instruction_i or imm_gen_sel_i) begin : al_IType_JType
	   zero_extend_Itype_to_mux_s[11:0] = instruction_i[31:20];
	   zero_extend_Itype_jalr_to_mux_s[0] = 1'b0;
	   zero_extend_Itype_jalr_to_mux_s[12:1] = instruction_i[31:20];
	   if (instruction_i[31]==1'b1) begin
	       zero_extend_Itype_to_mux_s[31:12] = 20'hfffff;
	       zero_extend_Jtype_to_mux_s[31:21] = 11'h7FF;
	       zero_extend_Itype_jalr_to_mux_s[31:13] = 19'h7ffff;
	       zero_extend_Btype_to_mux_s[31:13] = 19'h7FFFF;
	   end
	   else begin
	       zero_extend_Itype_to_mux_s[31:12] = 20'h00000;
	       zero_extend_Jtype_to_mux_s[31:21] = 11'h000;
	       zero_extend_Itype_jalr_to_mux_s[31:13] = 19'h00000;
	       zero_extend_Btype_to_mux_s[31:13] = 19'h00000;
	   end
	end : al_IType_JType
	////U type instruction
	assign zero_extend_Utype_to_mux_s[31:12] = instruction_i[31:12];
	assign zero_extend_Utype_to_mux_s[11:0] = 12'h000;
	////S type instruction
	assign zero_extend_Stype_to_mux_s[11:5] = instruction_i[31:25];
	assign zero_extend_Stype_to_mux_s[4:0] = instruction_i[11:7];
	assign zero_extend_Stype_to_mux_s[31:12] = 20'h00000;
	////J type instruction
	assign zero_extend_Jtype_to_mux_s[0] = 1'b0;
	assign zero_extend_Jtype_to_mux_s[10:1] = instruction_i[30:21];
	assign zero_extend_Jtype_to_mux_s[11] = instruction_i[20];
	assign zero_extend_Jtype_to_mux_s[19:12] = instruction_i[19:12];
	assign zero_extend_Jtype_to_mux_s[20] = instruction_i[31];
	////B type instruction
	assign zero_extend_Btype_to_mux_s[0] = 1'b0;
	assign zero_extend_Btype_to_mux_s[4:1] = instruction_i[11:8];
	assign zero_extend_Btype_to_mux_s[10:5] = instruction_i[30:25];
	assign zero_extend_Btype_to_mux_s[11] = instruction_i[7];
	assign zero_extend_Btype_to_mux_s[12] = instruction_i[31];
endmodule : imm_gen_v1
