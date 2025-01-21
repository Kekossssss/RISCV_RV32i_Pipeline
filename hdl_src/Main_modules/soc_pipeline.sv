//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 08/01/2025
// Design Name: soc_pipeline.sv
// Module Name: soc_pipeline
// Project Name: RISCV_RV32i_pipeline
// Description: Highest level module of the RISCV RV32i processor, containing the logic unit(s if multiple cores),
//            the L2/3 cache if there is any and the main memory (DRAM)
//
// Dependencies:
// logic_unit_pipeline.sv
// dram_emulation_mem.sv
//
// Current revision : 1.2
// Last modification : 11/01/2025
//
// Revision: 1.2
// Additional Comments: Added support for data memory writes from the cache. TBT
//
// Revision: 1.1
// Additional Comments: Completely functionnal for the current spec
//
// Revision: 1.0
// Additional Comments: Completed but not tested to work in a pipelined architecture, with support for data and control
//                     dependencies, bypass and cache for both instructions and data.
// 
// Revision: 0.1
// Additional Comments: Not currently completed, file creation and first additions
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

import RISCV32i_Pack::*;


module soc_pipeline #(
    parameter instruction_file = "",
    parameter data_file = "",
    parameter BYTE_OFF_BITS = 5,
    parameter INDEX_BITS = 5,
    parameter TAG_BITS = 22,
    parameter NB_WAYS = 2,
    parameter SIZE_DRAM = 4096,
    parameter CYCLE_LATENCE_DRAM = 10,
    localparam NB_WORDS_LINE = (2**BYTE_OFF_BITS)/4,
    localparam NB_LINES = 2**INDEX_BITS,
    localparam LINE_SIZE = 32 * NB_WORDS_LINE
)(
    input logic clk_i,rst_i
    );
    //---------------------------------------------------------------------------------------//
	//Internal connections declaration
	//---------------------------------------------------------------------------------------//
    ////Instructions related connections
    logic mem_instr_read_valid_s;
    logic mem_instr_read_enable_s;
    logic [31:0] mem_instr_addr_s;
    logic [LINE_SIZE-1:0] mem_instr_read_data_s;
    ////Data related connections
    logic mem_data_read_valid_s;
    logic mem_data_write_valid_s;
    logic mem_data_read_enable_s;
    logic mem_data_write_enable_s;
    logic [31:0] mem_data_addr_s;
    logic [LINE_SIZE-1:0] mem_data_read_data_s;
    logic [LINE_SIZE-1:0] mem_data_write_data_s;
    //---------------------------------------------------------------------------------------//
	//Core(s) declaration
	//---------------------------------------------------------------------------------------//
    logic_unit_pipeline #(
        .BYTE_OFF_BITS(BYTE_OFF_BITS),
        .INDEX_BITS(INDEX_BITS),
        .TAG_BITS(TAG_BITS),
        .NB_WAYS(NB_WAYS)
    ) CORE_1 (
        //General purpose input ports
        .clk_i(clk_i),
        .rst_i(rst_i),
        //Input ports
        .mem_instr_read_valid_i(mem_instr_read_valid_s),
        .mem_data_read_valid_i(mem_data_read_valid_s),
        .mem_data_write_valid_i(mem_data_write_valid_s),
        .mem_instr_read_data_i(mem_instr_read_data_s),
        .mem_data_read_data_i(mem_data_read_data_s),
        //Output ports
        .mem_instr_read_enable_o(mem_instr_read_enable_s),
        .mem_data_read_enable_o(mem_data_read_enable_s),
        .mem_data_write_enable_o(mem_data_write_enable_s),
        .mem_instr_addr_o(mem_instr_addr_s),
        .mem_data_addr_o(mem_data_addr_s),
        .mem_data_write_data_o(mem_data_write_data_s)
    );
    //---------------------------------------------------------------------------------------//
	//Memory declaration (no memory controler, so DRAM's are separated)
	//---------------------------------------------------------------------------------------//
	////Cache memory
    dram_emulation_mem #(
        .INIT_FILE(instruction_file),
        .ByteOffsetBits(BYTE_OFF_BITS),
        .SIZE(SIZE_DRAM),
        .CYCLE_LATENCE(CYCLE_LATENCE_DRAM)
    ) DRAM_INSTR (
        //General purpose ports
        .clk_i(clk_i),
        .add_i(mem_instr_addr_s),
        //Read ports
        .read_enable_i(mem_instr_read_enable_s),
        .read_valid_o(mem_instr_read_valid_s),
        .data_o(mem_instr_read_data_s)
    );
    ////Data memory
    dram_emulation_mem #(
        .INIT_FILE(data_file),
        .ByteOffsetBits(BYTE_OFF_BITS),
        .SIZE(SIZE_DRAM),
        .CYCLE_LATENCE(CYCLE_LATENCE_DRAM)
    ) DRAM_DATA (
        //General purpose ports
        .clk_i(clk_i),
        .add_i(mem_data_addr_s),
        //Write ports
        .write_enable_i(mem_data_write_enable_s),
        .data_i(mem_data_write_data_s),
        .write_valid_o(mem_data_write_valid_s),
        //Read ports
        .read_enable_i(mem_data_read_enable_s),
        .read_valid_o(mem_data_read_valid_s),
        .data_o(mem_data_read_data_s)
    );
endmodule : soc_pipeline