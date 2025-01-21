//Author : Kevin GUILLOUX
//Last modified : 11/05/2024
//Comment : Testbench of the configurable register, with WriteEnable input, tested for 32 bits data

`timescale 1ns / 1ps

module register_n_bits_tb();
    //Internal connection declaration
    logic clk_s = 1'b0;
    logic rst_s, write_enable_s;
    logic [31:0] D_s, Q_s;
    //Tested module declaration
    register_n_bits #(32) DUT (
        .clk_i(clk_s),
        .rst_i(rst_s),
        .write_enable_i(write_enable_s),
        .D_i(D_s),
        .Q_o(Q_s)
    );
    //Clock generation
    always begin
		assign  clk_s = ~clk_s;
     	#10;
   	end
    //Test
    initial begin
        rst_s = 1'b0;
        write_enable_s = 1'b0;
        D_s = 32'h12345678;
        #20;
        rst_s = 1'b1;
        write_enable_s = 1'b0;
        D_s = 32'h12345678;
        #20;
        rst_s = 1'b1;
        write_enable_s = 1'b1;
        D_s = 32'h12345678;
        #20;
        rst_s = 1'b1;
        write_enable_s = 1'b0;
        D_s = 32'h11111111;
        #20;
        rst_s = 1'b1;
        write_enable_s = 1'b1;
        D_s = 32'h11111111;
        #20;
        rst_s = 1'b0;
        write_enable_s = 1'b1;
        D_s = 32'h11111111;
        #20;
        rst_s = 1'b0;
        write_enable_s = 1'b1;
        D_s = 32'hfedcba98;
        #20;
        rst_s = 1'b1;
        write_enable_s = 1'b1;
        D_s = 32'hfedcba98;
        #20;
        rst_s = 1'b1;
        write_enable_s = 1'b0;
        D_s = 32'h01010101;
        #20;
        rst_s = 1'b1;
        write_enable_s = 1'b1;
        D_s = 32'h01010101;
    end  
endmodule : register_n_bits_tb
