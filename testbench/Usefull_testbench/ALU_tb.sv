//Author : Kevin GUILLOUX
//Last modified : 10/05/2024
//Comment : Testbench for the ALU module

`timescale 1ns/1ps

import RISCV32i_Pack::*;

module ALU_tb ();
    //Internal connection declaration
    data_bus op1_s, op2_s;
    logic [3:0] func_s;
    data_bus d_s;
    logic zero_s;
    logic lt_s;
    //Tested module declaration
    ALU DUT (
        .op1_i(op1_s),
        .op2_i(op2_s),
        .func_i(func_s),
        .d_o(d_s),
        .zero_o(zero_s),
        .lt_o(lt_s)
    );
    //Test
    initial begin
        op1_s = 32'h12345678;
        op2_s = 32'hfedcba98;
        func_s = 4'h0;
        #20;
        func_s = 4'h1;   //Adder testing
        #20;
        func_s = 4'h2;   //Substract testing
        #20;
        op2_s = 32'h00000010;
        func_s = 4'h3;   //Left logical shift testing
        #20;
        func_s = 4'h4;   //Right logical shift testing
        #20;
        func_s = 4'h5;   //Right arithmetic shift testing
        #20;
        op2_s = 32'hfedcba98;
        func_s = 4'h6;   //AND gate testing
        #20;
        func_s = 4'h7;   //OR gate testing
        #20;
        func_s = 4'h8;   //XOR gate testing
        #20;
        func_s = 4'h9;   //Signed comparator testing
        #20;
        func_s = 4'ha;   //Unsigned comparator testing
        #20;
        func_s = 4'hb;   //Op1_i hard valor testing
        #20;
        func_s = 4'hc;   //Null valor testing
        #20;
        func_s = 4'hd;   //Null valor testing
        #20;
        func_s = 4'he;   //Null valor testing
        #20;
        func_s = 4'hf;   //Null valor testing
        #20;
    end 
endmodule : ALU_tb
