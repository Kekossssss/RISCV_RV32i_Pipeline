//Author : Kevin GUILLOUX
//Last modified : 11/05/2024
//Comment : Module allowing to create a bank of registers, configurable to any bit size and any number of registers

`timescale 1ns / 1ps

module register_bank_tb();
    logic clk_s = 1'b0;
    logic rst_s;
    logic write_enable_s;
    logic [4:0] rs1_add_s, rs2_add_s, rd_add_s;
    logic [31:0] rd_data_s;
    logic [31:0] rs1_data_s, rs2_data_s;
    //Tested module declaration
    register_bank #(32,5,32) DUT (
        .clk_i(clk_s),
        .rst_i(rst_s),
        .write_enable_i(write_enable_s),
        .rs1_add_i(rs1_add_s),
        .rs2_add_i(rs2_add_s),
        .rd_add_i(rd_add_s),
        .rd_data_i(rd_data_s),
        .rs1_data_o(rs1_data_s),
        .rs2_data_o(rs2_data_s)
    );
    //Clock generation
    always begin
		assign clk_s = ~clk_s;
     	#10;
   	end
   	//Test
   	initial begin
   	    rst_s = 1'b0;
   	    write_enable_s = 1'b0;
   	    rs1_add_s = 5'h00;
   	    rs2_add_s = 5'h00;
   	    rd_add_s = 5'h00;
   	    rd_data_s = 32'h00000000;
   	    #18;
   	    rst_s = 1'b1;
   	    #20;
   	    write_enable_s = 1'b1;
   	    rd_data_s = 32'h11111111;
   	    #20;
   	    write_enable_s = 1'b1;
   	    rs1_add_s = 5'h01;
   	    rd_add_s = 5'h01;
   	    rd_data_s = 32'h11111111;
   	    #20;
   	    write_enable_s = 1'b1;
   	    rs1_add_s = 5'h01;
   	    rs2_add_s = 5'h04;
   	    rd_add_s = 5'h03;
   	    rd_data_s = 32'h22222222;
   	    #20;
   	    write_enable_s = 1'b1;
   	    rs1_add_s = 5'h03;
   	    rs2_add_s = 5'h04;
   	    rd_add_s = 5'h04;
   	    rd_data_s = 32'h22222222;
   	end
endmodule : register_bank_tb
