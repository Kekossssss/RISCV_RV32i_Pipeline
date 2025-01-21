//Author : Kevin GUILLOUX
//Last modified : 15/05/2024
//Comment : TestBench of the Imm generator module, version 1

`timescale 1ns / 1ps

import RISCV32i_Pack::*;

module imm_gen_tb();
    data_bus instruction_s;
    logic [2:0] imm_gen_sel_s;
    data_bus imm_extend_s;
    //Tested module declaration
    imm_gen_v1 DUT (
        .instruction_i(instruction_s),
        .imm_gen_sel_i(imm_gen_sel_s),
        .imm_extend_o(imm_extend_s)
    );
    //Test
    initial begin
        instruction_s = 32'h00A00113;
        imm_gen_sel_s = 3'h1;
        #20;
        instruction_s = 32'h00108093;
        imm_gen_sel_s = 3'h1;
        #20;
        instruction_s = 32'hEEF08093;
        imm_gen_sel_s = 3'h1;
        #20;
        instruction_s = 32'hDEADB0B7;
        imm_gen_sel_s = 3'h2;
    end
endmodule : imm_gen_tb
