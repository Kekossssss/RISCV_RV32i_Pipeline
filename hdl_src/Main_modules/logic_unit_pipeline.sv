//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 08/01/2025
// Design Name: logic_unit_pipeline.sv
// Module Name: logic_unit_pipeline
// Project Name: RISCV_RV32i_pipeline
// Description: Module assembling the logic units of the RV32i architecture (data and control paths),
// and the low level caches. It reprensent a CORE of the SOC
//
// Dependencies:
// controlpath_pipeline.sv
// datapath_pipeline.sv
// multi_way_cache.sv
// write_through_cache.sv
//
// Current revision : 1.4
// Last modification : 15/01/2025
//
// Revision: 1.4
// Additional Comments: Added connection to support the full bypass, and modified existing ones to be able to accept
//                     the added connection lengths.
//
// Revision: 1.3
// Additional Comments: Added the logic to be able to still do the bypass for rs2 in case of a
//                     store instruction. (10% better performance in the best case scenario)
//
// Revision: 1.2
// Additional Comments: Added the "write_through_cache" and the logic for it to work with the processor. TBT
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

module logic_unit_pipeline #(
    parameter BYTE_OFF_BITS = 5,
    parameter INDEX_BITS = 5,
    parameter TAG_BITS = 22,
    parameter NB_WAYS = 2,
    localparam NB_WORDS_LINE = (2**BYTE_OFF_BITS)/4,
    localparam NB_LINES = 2**INDEX_BITS,
    localparam LINE_SIZE = 32 * NB_WORDS_LINE,
    //Size of the L1 caches in Bytes
    localparam L1_SIZE = NB_LINES * LINE_SIZE /8,
    //Parameters for the instruction cache adress size and adressing
    localparam IMEM_BASE_ADDR = 32'h0000_0000,
    localparam IMEM_SIZE = L1_SIZE,
    //Parameters for the data cache adress size and adressing
    localparam DMEM_BASE_ADDR = 32'h0001_0000,
    localparam DMEM_SIZE = L1_SIZE
)(
    //General purpose input ports
    input logic clk_i, rst_i,
    //Input ports
    input logic mem_instr_read_valid_i,
    input logic mem_data_read_valid_i,
    input logic mem_data_write_valid_i,
    input logic [LINE_SIZE-1:0] mem_instr_read_data_i,
    input logic [LINE_SIZE-1:0] mem_data_read_data_i,
    //Output ports
    output logic mem_instr_read_enable_o,
    output logic mem_data_read_enable_o,
    output logic mem_data_write_enable_o,
    output logic [31:0] mem_instr_addr_o,
    output logic [31:0] mem_data_addr_o,
    output logic [LINE_SIZE-1:0] mem_data_write_data_o
    );
    //---------------------------------------------------------------------------------------//
	//Internal connections declaration
	//---------------------------------------------------------------------------------------//
    ////Cache related connections
    logic instr_cache_read_valid_s;
    logic data_cache_read_valid_s;
    logic data_cache_write_valid_s;
    logic data_cache_validity_s;
    logic instr_cache_read_enable_s;
    logic data_cache_write_enable_s;
    logic data_cache_read_enable_s;
    logic [3:0] data_cache_ble_s;       //Not currently supported by the cache
    logic [31:0] instr_cache_add_s;
    logic [31:0] data_cache_add_s;
    logic [31:0] instr_cache_data_s;
    logic [31:0] data_cache_read_data_s;
    logic [31:0] data_cache_write_data_s;
    ////Datapath to controlpath connections
    logic zero_s;
    logic lt_s;
    logic [31:0] instruction_s;
    ////Controlpath to datapath connections
    logic stall_s;
    logic fetch_jump_s;
    logic fetch_branch_s;
    logic reg_write_enable_s;
    logic mem_zero_extend_s;
    logic rd_bypass_exe_s;
    logic [1:0] rd_bypass_mem_s;
    logic [1:0] mem_data_select_s;
    logic [1:0] pc_select_s;
    logic [1:0] write_back_select_s;
    logic [2:0] alu_src_1_s; 
    logic [2:0] alu_src_2_s;
    logic [2:0] imm_gen_sel_s;
    logic [3:0] alu_function_s;
    logic [3:0] mem_data_mask_s;
    logic [4:0] rd_addr_s;
    //---------------------------------------------------------------------------------------//
	//Data path, to process the informations
	//---------------------------------------------------------------------------------------//
    datapath_pipeline DATA_UNIT (
        //General purpose input ports
        .clk_i(clk_i), 
        .rst_i(rst_i),
        //Inputs
        .stall_i(stall_s),
        .fetch_jump_i(fetch_jump_s),
        .fetch_branch_i(fetch_branch_s),
        .reg_write_enable_i(reg_write_enable_s),
        .mem_zero_extend_i(mem_zero_extend_s),
        .rd_bypass_exe_i(rd_bypass_exe_s),
        .rd_bypass_mem_i(rd_bypass_mem_s),
        .mem_data_select_i(mem_data_select_s),
        .alu_src_1_i(alu_src_1_s), 
        .alu_src_2_i(alu_src_2_s),
        .pc_select_i(pc_select_s),
        .write_back_select_i(write_back_select_s),
        .imm_gen_sel_i(imm_gen_sel_s),
        .alu_function_i(alu_function_s),
        .mem_data_mask_i(mem_data_mask_s),
        .rd_addr_i(rd_addr_s),
        //Outputs
        .zero_o(zero_s), 
        .lt_o(lt_s),
        .instruction_o(instruction_s),
        //Cache specific inputs
        .instr_cache_read_valid_i(instr_cache_read_valid_s),
        .data_cache_validity_i(data_cache_validity_s),
        .instr_cache_data_i(instr_cache_data_s),
        .data_cache_read_data_i(data_cache_read_data_s),
        //Cache specific outputs
        .instr_cache_add_o(instr_cache_add_s),
        .data_cache_add_o(data_cache_add_s),
        .data_cache_write_data_o(data_cache_write_data_s),
        .data_cache_ble_o(data_cache_ble_s)                   //Not currently connected/supported
    );
    //---------------------------------------------------------------------------------------//
	//Control path, to generate the control signals
	//---------------------------------------------------------------------------------------//
    controlpath_pipeline CONTROL_UNIT (
        //General purpose input ports
        .clk_i(clk_i),
        .rst_i(rst_i),
        //Inputs
        .zero_i(zero_s), 
        .lt_i(lt_s),
        .instruction_i(instruction_s),
        //Output ports
        .stall_o(stall_s),
        .fetch_jump_o(fetch_jump_s),
        .fetch_branch_o(fetch_branch_s),
        .reg_write_enable_o(reg_write_enable_s),
        .mem_write_enable_o(data_cache_write_enable_s),
        .mem_read_enable_o(data_cache_read_enable_s),
        .mem_zero_extend_o(mem_zero_extend_s),
        .rd_bypass_exe_o(rd_bypass_exe_s),
        .rd_bypass_mem_o(rd_bypass_mem_s),
        .mem_data_select_o(mem_data_select_s),
        .alu_src_1_o(alu_src_1_s), 
        .alu_src_2_o(alu_src_2_s),
        .pc_select_o(pc_select_s),
        .write_back_select_o(write_back_select_s),
        .imm_gen_sel_o(imm_gen_sel_s),
        .alu_function_o(alu_function_s),
        .mem_data_mask_o(mem_data_mask_s),
        .rd_addr_o(rd_addr_s),
        //Cache specific inputs
        .instr_cache_read_valid_i(instr_cache_read_valid_s),
        .data_cache_validity_i(data_cache_validity_s)
    );
    //---------------------------------------------------------------------------------------//
	//Instruction cache, for fast interactions with memory
	//---------------------------------------------------------------------------------------//
    assign instr_cache_read_enable_s = (instr_cache_add_s >= IMEM_BASE_ADDR) && (instr_cache_add_s < (IMEM_BASE_ADDR + IMEM_SIZE));
    
    multi_way_cache #(
        .ByteOffsetBits(BYTE_OFF_BITS),
        .IndexBits(INDEX_BITS),
        .TagBits(TAG_BITS),
        .NB_WAYS(NB_WAYS)
    ) L1_CACHE_INSTR (
        //General purpose input ports
        .clk_i(clk_i),
        .rstn_i(rst_i),
        .addr_i(instr_cache_add_s),
        //Read port
        .read_en_i(instr_cache_read_enable_s),
        .read_valid_o(instr_cache_read_valid_s),
        .read_word_o(instr_cache_data_s),
        //Memory port
        .mem_addr_o(mem_instr_addr_o),
        .mem_read_valid_i(mem_instr_read_valid_i),
        .mem_read_data_i(mem_instr_read_data_i),
        .mem_read_en_o(mem_instr_read_enable_o)
    );
    //---------------------------------------------------------------------------------------//
	//Data cache, for fast interactions with memory
	//---------------------------------------------------------------------------------------//
    ////Logic that generates the validity signal at destination to the processor control and data path
    always_comb begin : data_cache_validity_comb
        data_cache_validity_s = (((data_cache_read_enable_s == 1'b0) && (data_cache_write_enable_s == 1'b0))
                                || (data_cache_read_enable_s && data_cache_read_valid_s) 
                                || (data_cache_write_enable_s && data_cache_write_valid_s));
    end : data_cache_validity_comb
    
    ////Data cache module, with the write through logic for writes, and multiple parametrable ways support
    write_back_cache #(
        .ByteOffsetBits(BYTE_OFF_BITS),
        .IndexBits(INDEX_BITS),
        .TagBits(TAG_BITS),
        .NB_WAYS(NB_WAYS)
    ) L1_CACHE_DATA (
        //General purpose input ports
        .clk_i(clk_i),
        .rstn_i(rst_i),
        .addr_i(data_cache_add_s),
        //Read port
        .read_en_i(data_cache_read_enable_s),
        .read_valid_o(data_cache_read_valid_s),
        .read_word_o(data_cache_read_data_s),
        //Write ports
        .write_en_i(data_cache_write_enable_s),
        .write_word_i(data_cache_write_data_s),
        .write_valid_o(data_cache_write_valid_s),
        //Memory general ports
        .mem_addr_o(mem_data_addr_o),
        //Memory read ports
        .mem_read_valid_i(mem_data_read_valid_i),
        .mem_read_data_i(mem_data_read_data_i),
        .mem_read_en_o(mem_data_read_enable_o),
        //Memory write ports
        .mem_write_en_o(mem_data_write_enable_o),           //Not currently connected
        .mem_write_data_o(mem_data_write_data_o),       //Not currently connected
        .mem_write_valid_i(mem_data_write_valid_i)      //Not currently connected
    ); 
endmodule : logic_unit_pipeline
