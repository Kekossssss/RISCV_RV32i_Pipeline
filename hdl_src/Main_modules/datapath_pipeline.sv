//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 07/01/2025
// Design Name: datapath_pipeline.sv
// Module Name: datapath_pipeline
// Project Name: RISCV_RV32i_pipeline
// Description: Data path for the RISCV RV32i architecture pipelined, making calculations on data and making the moves around the chip
// 
// Dependencies:
// ALU.sv
// register_bank.sv
// register_n_bits.sv
// adder_n_bits.sv
// imm_gen_v1.sv
// configurable_mux.sv
// 
// Current revision : 1.4
// Last modification : 15/01/2025
//
// Revision: 1.4
// Additional Comments: Added full support for the bypass accross all stages of the circuit for better performance
//                     at a low cost in transistor space. Corrected the implementation of the JALR instruction that
//                     wasn't working correctly.
//
// Revision: 1.3
// Additional Comments: Added the logic to be able to still do the bypass for rs2 in case of a
//                     store instruction. (10% better performance in the best case scenario)
//
// Revision: 1.2
// Additional Comments: Corrected multiple bugs that caused "memcpy.S" not working correctly :
//                          - Forgotten register wall between rs2 in the DEC stage and EXEC
//                          - Changed the default value for the memory writes and reads
//
// Revision: 1.1
// Additional Comments: Completely functionnal for the current spec
//
// Revision: 1.0
// Additional Comments: Completed but not tested to work in a pipelined architecture, with support for data and control
//                     dependencies, bypass and cache for both instructions and data.
//
// Revision: 0.1
// Additional Comments: Not currently completed, file creation and first additions (currently still in monocycle mode)
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

import RISCV32i_Pack::*;


module datapath_pipeline (
    //General purpose input ports
    input logic clk_i, rst_i,
    //Inputs
    input logic stall_i,
    input logic fetch_jump_i,
    input logic fetch_branch_i,
    input logic reg_write_enable_i,
    input logic mem_zero_extend_i,
    input logic rd_bypass_exe_i,
    input logic [1:0] rd_bypass_mem_i,
    input logic [1:0] mem_data_select_i,
    input logic [1:0] pc_select_i,
    input logic [1:0] write_back_select_i,
    input logic [2:0] alu_src_1_i, 
    input logic [2:0] alu_src_2_i,
    input logic [2:0] imm_gen_sel_i,
    input logic [3:0] alu_function_i,
    input logic [3:0] mem_data_mask_i,
    input logic [4:0] rd_addr_i,
    //Outputs
    output logic zero_o, lt_o,
    output logic [31:0] instruction_o,
    //Cache specific inputs
    input logic instr_cache_read_valid_i,
    input logic data_cache_validity_i,
    input logic [31:0] instr_cache_data_i,
    input logic [31:0] data_cache_read_data_i,
    //Cache specific outputs
    output logic [31:0] instr_cache_add_o,
    output logic [31:0] data_cache_add_o,
    output logic [31:0] data_cache_write_data_o,
    output logic [3:0] data_cache_ble_o
    );
    //---------------------------------------------------------------------------------------//
	//Internal connections declaration
	//---------------------------------------------------------------------------------------//
    logic [31:0] rs1_data_s, rs2_data_s, rs2_data_dec_s, rs2_data_exe_s, rs2_data_mem_s;
    logic [31:0] rd_data_exe_s, rd_data_mem_s, rd_data_wb_s;
    logic [31:0] alu_op1_dec_s, alu_op2_dec_s;
    logic [31:0] alu_op1_exe_s, alu_op2_exe_s;
    logic [31:0] alu_data_out_s, alu_data_out_mem_s, alu_data_out_wb_s;
    logic [31:0] pc_to_mux_alu_s;
    logic [31:0] mux_rd_to_rd_data_s;
    logic [11:0] alu_to_data_mem_addr_s;
    logic [31:0] data_mem_to_mux_rd_s;
    logic [31:0] imm_gen_data_s;
    logic [31:0] address_adder_to_rd_mux_s;
    logic [31:0] cache_write_data_s;
    logic [31:0] cache_read_data_mem_s, cache_read_data_wb_s;
    logic [31:0] data_mask_mem_s;
    //Instruction signals
    logic [31:0] instr_fetch_s;
    logic [31:0] instr_decode_s;
    //PC connections
    logic [31:0] pc_plus4_s, pc_plus4_dec_s, pc_plus4_exe_s, pc_plus4_mem_s, pc_plus4_wb_s;
    logic [31:0] pc_rs1_imm_s;
    logic [31:0] pc_add_imm_j_s, pc_add_imm_br_s;
    logic [31:0] next_pc_addr_s;
    logic [31:0] pc_addr_s, pc_addr_dec_s, pc_addr_exe_s, pc_addr_mem_s, pc_addr_wb_s;
    logic [31:0] imm_gen_to_pc_imm_adder_s;
    //---------------------------------------------------------------------------------------//
	////Instruction Fetch stage
	//---------------------------------------------------------------------------------------//
	////Calculate the next "normal" adress for the PC counter
	adder_n_bits #(32) PC_ADDER (
		.A_i(pc_addr_s),
		.B_i(32'h00000004),
		.Cin_i(0),
		.S_o(pc_plus4_s)
	);
	////Choose the next value for the PC counter
	configurable_mux #(2,32) MUX_PC_REG (
		.data_i({pc_add_imm_br_s,
		         alu_data_out_s,
		         pc_add_imm_j_s,
		         pc_plus4_s}),
		.sel_i(pc_select_i),
		.data_o(next_pc_addr_s)
	);
	////Store the current adress of the PC counter
	register_n_bits #(32) ADDR_REG (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i((stall_i == 1'b0) && instr_cache_read_valid_i && data_cache_validity_i),
        .D_i(next_pc_addr_s),
        .Q_o(pc_addr_s)
    );
    //Cache assignation
    assign instr_cache_add_o = {pc_addr_s[31:2],2'b00};
    assign instr_fetch_s = (fetch_jump_i == 1'b1) ? 32'h00000013 : instr_cache_data_i;
    
    //Registers wall FETCH ---> DEC
    register_n_bits #(32) DEC_REG (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i((stall_i == 1'b0) && instr_cache_read_valid_i && data_cache_validity_i),
        .D_i(instr_fetch_s),
        .Q_o(instr_decode_s)
    );
    assign instruction_o = instr_decode_s;  //Instruction sent to control path
    
    register_n_bits #(32) PC_DEC_REG (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i((stall_i == 1'b0) && instr_cache_read_valid_i && data_cache_validity_i),
        .D_i(pc_addr_s),
        .Q_o(pc_addr_dec_s)
    );
    //---------------------------------------------------------------------------------------//
	//Instruction Decode stage
	//---------------------------------------------------------------------------------------//
	register_bank #(32,5,32) REG_BANK (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i(reg_write_enable_i),
        .rs1_add_i(instr_decode_s[19:15]),
        .rs2_add_i(instr_decode_s[24:20]),
        .rd_add_i(rd_addr_i),   //Because we take the adress in the writeback stage
        .rd_data_i(rd_data_wb_s),
        .rs1_data_o(rs1_data_s),
        .rs2_data_o(rs2_data_s)
    );
    ////Immediate value generator, reassort the immediate number extracted from the instruction based on its type
    imm_gen_v1 IMM_GEN (
        .instruction_i(instr_decode_s),
        .imm_gen_sel_i(imm_gen_sel_i),
        .imm_extend_o(imm_gen_data_s)
    );
    ////Calculate the value of the jump in the PC counter for jumps and branch instructions
    adder_n_bits #(32) PC_IMM_ADDER (
		.A_i(pc_addr_dec_s),
		.B_i(imm_gen_data_s),
		.Cin_i(0),
		.S_o(pc_add_imm_j_s)
	);
	////Compute the value of the PC+4 for the writing in the RD register (mainly for jump instructions)
	adder_n_bits #(32) PC_PLUS_4_DEC (
		.A_i(pc_addr_dec_s),
		.B_i(32'h00000004),
		.Cin_i(0),
		.S_o(pc_plus4_dec_s)
	);
	////Choose the RD that is taken from the EXE stage for the bypass
	configurable_mux #(1,32) MUX_BYPASS_RD_EXE (
		.data_i({pc_plus4_exe_s,
		         alu_data_out_s}),
		.sel_i(rd_bypass_exe_i),
		.data_o(rd_data_exe_s)
	);
	////Choose the RD that is taken from the MEM stage for the bypass
	configurable_mux #(2,32) MUX_BYPASS_RD_MEM (
		.data_i({cache_read_data_mem_s,
		         pc_plus4_mem_s,
		         alu_data_out_mem_s}),
		.sel_i(rd_bypass_mem_i),
		.data_o(rd_data_mem_s)
	);
	////Choose the OP1 of the ALU
    configurable_mux #(3,32) MUX_ALU_SRC1 (
		.data_i({rd_data_wb_s,
		         rd_data_mem_s,
		         rd_data_exe_s,
		         pc_addr_s,
		         imm_gen_data_s,
		         rs1_data_s}),
		.sel_i(alu_src_1_i),
		.data_o(alu_op1_dec_s)
	);
	////Choose the OP2 of the ALU
	configurable_mux #(3,32) MUX_ALU_SRC2 (
		.data_i({rd_data_wb_s,
		         rd_data_mem_s,
		         rd_data_exe_s,
		         imm_gen_data_s,
		         rs2_data_s}),
		.sel_i(alu_src_2_i),
		.data_o(alu_op2_dec_s)
	);
	////Choose the value to be written in memory
	configurable_mux #(2,32) MUX_REG_RS2 (
		.data_i({rd_data_wb_s,
		         rd_data_mem_s,
		         rd_data_exe_s,
		         rs2_data_s}),
		.sel_i(mem_data_select_i),
		.data_o(rs2_data_dec_s)
	);
	//Registers wall DEC ---> EXE
    always_ff @(posedge clk_i or negedge rst_i) begin : EXE_REG
      if (rst_i == 1'b0) begin
          alu_op1_exe_s <= 32'h00000000;
          alu_op2_exe_s <= 32'h00000000;
          rs2_data_exe_s <= 32'h00000000;
          //func3_exec_r <=0;
          pc_add_imm_br_s <= 32'h00000000;
          pc_plus4_exe_s <= 32'h00000000;
      end
      else if (instr_cache_read_valid_i && data_cache_validity_i) begin
         if (fetch_branch_i || stall_i) begin
              alu_op1_exe_s <= 32'h00000000;
              alu_op2_exe_s <= 32'h00000000;
              rs2_data_exe_s <= 32'h00000000;
              //func3_exec_r <= 3'b000;
              pc_add_imm_br_s <= pc_add_imm_j_s;
              pc_plus4_exe_s <= pc_plus4_dec_s;
         end
         else begin
          alu_op1_exe_s <= alu_op1_dec_s;
          alu_op2_exe_s <= alu_op2_dec_s;
          rs2_data_exe_s <= rs2_data_dec_s;
          //func3_exec_r <= func3_dec_r;
          pc_add_imm_br_s <= pc_add_imm_j_s;
          pc_plus4_exe_s <= pc_plus4_dec_s;
         end
       end
    end : EXE_REG
    //---------------------------------------------------------------------------------------//
	//Execute stage
	//---------------------------------------------------------------------------------------//
	ALU ALU (
        .op1_i(alu_op1_exe_s),
        .op2_i(alu_op2_exe_s),
        .func_i(alu_function_i),
        .d_o(alu_data_out_s),
        .zero_o(zero_o),
        .lt_o(lt_o)
    );
	//Registers wall EXE ---> MEM
	register_n_bits #(32) MEM_PC_REG (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i(instr_cache_read_valid_i && data_cache_validity_i),
        .D_i(pc_plus4_exe_s),
        .Q_o(pc_plus4_mem_s)
    );
    register_n_bits #(32) MEM_RD_REG (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i(instr_cache_read_valid_i && data_cache_validity_i),
        .D_i(alu_data_out_s),
        .Q_o(alu_data_out_mem_s)
    );
    register_n_bits #(32) MEM_RS2_REG (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i(instr_cache_read_valid_i && data_cache_validity_i),
        .D_i(rs2_data_exe_s),
        .Q_o(rs2_data_mem_s)
    );
	//---------------------------------------------------------------------------------------//
	//Memorize stage
	//---------------------------------------------------------------------------------------//
	//Logic of the "mask" for the data written to memory
	always_comb begin : cache_write_shifter_comb
        case (mem_data_mask_i)
          4'b0001: cache_write_data_s = {24'b0, rs2_data_mem_s[7:0]};
          4'b0011: cache_write_data_s = {16'b0, rs2_data_mem_s[15:0]};
          4'b1111: cache_write_data_s = rs2_data_mem_s;
          default: cache_write_data_s = 32'b0;
        endcase
    end : cache_write_shifter_comb
    
    //Logic of the "mask" for the data read from memory
	always_comb begin : cache_read_shifter_comb
        case (mem_data_mask_i)
          4'b0001: begin
            if (mem_zero_extend_i == 1'b1) cache_read_data_mem_s = {{24{1'b0}}, data_cache_read_data_i[7:0]};
            else cache_read_data_mem_s = {{24{data_cache_read_data_i[7]}}, data_cache_read_data_i[7:0]};
          end
          4'b0011: begin
            if (mem_zero_extend_i == 1'b1) cache_read_data_mem_s = {{16{1'b0}}, data_cache_read_data_i[15:0]};
            else cache_read_data_mem_s = {{16{data_cache_read_data_i[15]}}, data_cache_read_data_i[15:0]};
          end
          4'b1111: cache_read_data_mem_s = data_cache_read_data_i;
          default: cache_read_data_mem_s = 32'b0;
        endcase
    end : cache_read_shifter_comb
    
    //Assignation of outputs to the memory
    assign data_cache_add_o = alu_data_out_mem_s;
	assign data_cache_write_data_o = cache_write_data_s;
	assign data_cache_ble_o = mem_data_mask_i;
	
	//Registers wall MEM ---> WB
	register_n_bits #(32) WB_PC_REG (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i(instr_cache_read_valid_i && data_cache_validity_i),
        .D_i(pc_plus4_mem_s),
        .Q_o(pc_plus4_wb_s)
    );
	register_n_bits #(32) WB_RD_REG (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i(instr_cache_read_valid_i && data_cache_validity_i),
        .D_i(alu_data_out_mem_s),
        .Q_o(alu_data_out_wb_s)
    );
    register_n_bits #(32) WB_CD_REG (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i(instr_cache_read_valid_i && data_cache_validity_i),
        .D_i(cache_read_data_mem_s),
        .Q_o(cache_read_data_wb_s)
    );
	//---------------------------------------------------------------------------------------//
	//Writeback stage
	//---------------------------------------------------------------------------------------//
	configurable_mux #(2,32) MUX_RD (
		.data_i({pc_plus4_wb_s,
		         alu_data_out_wb_s,
		         cache_read_data_wb_s}),
		.sel_i(write_back_select_i),
		.data_o(rd_data_wb_s)
	);
endmodule : datapath_pipeline
