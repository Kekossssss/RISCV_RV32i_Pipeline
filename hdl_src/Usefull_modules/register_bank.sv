//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 11/05/2024
// Design Name: register_bank.sv
// Module Name: register_bank
// Project Name: RISCV_RV32i_pipeline
// Description: Module allowing to create a bank of registers, configurable to any bit size and any number of registers
//             Defaults to 1 bit and 2 registers (The first one always being equal to zero)
//
// Dependencies: 
// configurable_mux.sv
// configurable_demux.sv
// register_n_bits.sv
//
// Current revision : 1.0
// Last modification : 11/05/2024
//
// Revision: 1.0
// Additional Comments: Tested and working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module register_bank #(
    parameter nb_bits = 1, parameter nb_bits_address = 1, parameter nb_registres = 2
)(
    input logic clk_i,
    input logic rst_i,
    input logic write_enable_i,
    input logic [nb_bits_address-1:0] rs1_add_i, rs2_add_i, rd_add_i,
    input logic [nb_bits-1:0] rd_data_i,
    output logic [nb_bits-1:0] rs1_data_o, rs2_data_o
    );
    //Internal connection declaration
    logic [nb_registres-1:0] mux_we_to_register_s;
    logic [nb_registres-1:0][nb_bits-1:0] register_to_mux_out_s;
    genvar i;
    //Module declaration
    ////Mux's
    configurable_mux #(nb_bits_address,nb_bits) MUX_RS1 (
        .data_i(register_to_mux_out_s),
        .sel_i(rs1_add_i),
        .data_o(rs1_data_o)
    );
    configurable_mux #(nb_bits_address,nb_bits) MUX_RS2 (
        .data_i(register_to_mux_out_s),
        .sel_i(rs2_add_i),
        .data_o(rs2_data_o)
    );
    ////Demux
    configurable_demux #(nb_bits_address,1) DEMUX (
		.data_i(write_enable_i),
		.sel_i(rd_add_i),
		.data_o(mux_we_to_register_s)
	);
    ////Register
    generate
        for (i=1;i<nb_registres;i++) begin : register_generate
            register_n_bits #(nb_bits) INST_REG (
                .clk_i(clk_i),
                .rst_i(rst_i),
                .write_enable_i(mux_we_to_register_s[i]),
                .D_i(rd_data_i),
                .Q_o(register_to_mux_out_s[i])
            );
        end : register_generate
    endgenerate
    //Assignation of signals
    assign register_to_mux_out_s[0] = 0;
endmodule : register_bank
