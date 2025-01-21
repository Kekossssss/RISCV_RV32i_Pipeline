//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 07/01/2025
// Design Name: controlpath_pipeline.sv
// Module Name: controlpath_pipeline
// Project Name: RISCV_RV32i_pipeline
// Description: Control path for the RISCV RV32i architecture pipelined, generating control signals for the other modules
// 
// Dependencies:
// register_n_bits.sv
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
// Additional Comments: Corrected multiple bugs regarding the generation of the bypass/stall logic signals :
//                         - No bypass possible when the next instruction is a load
//                         - No bypass possible for rs2 when the dec instruction is a store
//
// Revision: 1.1
// Additional Comments: Completely functionnal for the current spec
//
// Revision: 1.0
// Additional Comments: Completed but not tested to work in a pipelined architecture, with support for data and control
//                     dependencies, bypass and cache for both instructions and data.
// Revision: 0.1
// Additional Comments: Not currently completed, file creation and first additions
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

import RISCV32i_Pack::*;


module controlpath_pipeline(
    //General purpose input ports
    input logic clk_i, rst_i,
    //Input ports
    input logic zero_i, lt_i,
    input logic [31:0] instruction_i,
    //Output ports
    output logic stall_o,
    output logic fetch_jump_o,
    output logic fetch_branch_o,
    output logic reg_write_enable_o,
    output logic mem_write_enable_o,
    output logic mem_read_enable_o,
    output logic mem_zero_extend_o,
    output logic rd_bypass_exe_o,
    output logic [1:0] rd_bypass_mem_o,
    output logic [1:0] mem_data_select_o,
    output logic [1:0] pc_select_o,
    output logic [1:0] write_back_select_o,
    output logic [2:0] alu_src_1_o, 
    output logic [2:0] alu_src_2_o,
    output logic [2:0] imm_gen_sel_o,
    output logic [3:0] alu_function_o,
    output logic [3:0] mem_data_mask_o,
    output logic [4:0] rd_addr_o,
    //Cache specific inputs
    input logic instr_cache_read_valid_i,
    input logic data_cache_validity_i
    );
    //---------------------------------------------------------------------------------------//
	//Functions
	//---------------------------------------------------------------------------------------//
    //Function to initialise the values of the LRU cache
    function logic rd_used(input logic [6:0] opcode);
        case(opcode)
            RV32I_OPCODE_R, RV32I_OPCODE_I_JALR, RV32I_OPCODE_I_LOAD, RV32I_OPCODE_I_OPER, RV32I_OPCODE_J, RV32I_OPCODE_U_LUI, RV32I_OPCODE_U_AUIPC :  rd_used = 1'b1;
            default : rd_used = 1'b0;
        endcase
    endfunction 
    //---------------------------------------------------------------------------------------//
	//Internal connections declaration
	//---------------------------------------------------------------------------------------//
    //Instructions related propagation connections
    logic [31:0] instr_dec_s, instr_exe_s, instr_mem_s, instr_wb_s;
    logic [6:0] opcode_dec_s, opcode_exe_s, opcode_mem_s, opcode_wb_s;
    logic [4:0] rs1_addr_dec_s, rs2_addr_dec_s;
    logic [4:0] rd_addr_dec_s, rd_addr_exe_s, rd_addr_mem_s, rd_addr_wb_s;
    logic [2:0] funct3_exe_s, funct3_mem_s;
    logic [6:0] funct7_exe_s;
    //Dependencies related connections
    logic branch_taken_s;
    logic stall_rs1_s, stall_rs2_s;
    logic stall_s;
    logic fetch_jump_dec_s, fetch_jump_exe_s;
    logic fetch_branch_s;
    logic fetch_jump_s;
    logic fetch_jalr_s;
    logic rd_usage_exe_s, rd_usage_mem_s, rd_usage_wb_s;
    logic rs1_bypass_exe_s, rs1_bypass_mem_s, rs1_bypass_wb_s;
    logic rs2_bypass_exe_s, rs2_bypass_mem_s, rs2_bypass_wb_s;
    //---------------------------------------------------------------------------------------//
	//Instruction Decode Stage
	//---------------------------------------------------------------------------------------//
	assign opcode_dec_s = instruction_i[6:0];
	assign rd_addr_dec_s = instruction_i[11:7];
	assign rs1_addr_dec_s = instruction_i[19:15];
    assign rs2_addr_dec_s = instruction_i[24:20];
    
	assign instr_dec_s =(stall_s == 1'b1 || fetch_branch_s == 1'b1) ? 32'h00000013 : instruction_i;
	
	//Mux controling the PC counter next value
	always_comb begin : pc_next_sel_comb
        if (branch_taken_s == 1'b1) pc_select_o = SEL_PC_BRANCH;
        else if (fetch_jalr_s == 1'b1) pc_select_o = SEL_PC_JALR;
        else begin
          case (opcode_dec_s)
            RV32I_OPCODE_J: pc_select_o = SEL_PC_JAL;
            default: pc_select_o = SEL_PC_PLUS_4;
          endcase
        end
    end
    
    //Mux controling the entry operand 1 of the ALU
    always_comb begin : alu_src1_comb
        if (rs1_bypass_exe_s) alu_src_1_o = MUX_SEL_OP1_BYPASS_EXE;
        else if (rs1_bypass_mem_s) alu_src_1_o = MUX_SEL_OP1_BYPASS_MEM;
        else if (rs1_bypass_wb_s) alu_src_1_o = MUX_SEL_OP1_BYPASS_WB;
        else begin
            case (opcode_dec_s)
                RV32I_OPCODE_U_LUI: alu_src_1_o = MUX_SEL_OP1_IMM;
                RV32I_OPCODE_U_AUIPC: alu_src_1_o = MUX_SEL_OP1_PC;
                default: alu_src_1_o = MUX_SEL_OP1_RS1;
            endcase
         end
    end : alu_src1_comb
    
    //Mux controling the entry operand 2 of the ALU
    always_comb begin : alu_src2_comb
        if (rs2_bypass_exe_s && (opcode_dec_s != RV32I_OPCODE_S)) alu_src_2_o = MUX_SEL_OP2_BYPASS_EXE;
        else if (rs2_bypass_mem_s && (opcode_dec_s != RV32I_OPCODE_S)) alu_src_2_o = MUX_SEL_OP2_BYPASS_MEM;
        else if (rs2_bypass_wb_s && (opcode_dec_s != RV32I_OPCODE_S)) alu_src_2_o = MUX_SEL_OP2_BYPASS_WB;
        else begin
            case (opcode_dec_s)
                RV32I_OPCODE_I_JALR, RV32I_OPCODE_I_OPER : alu_src_2_o = MUX_SEL_OP2_IMM;
                RV32I_OPCODE_U_AUIPC, RV32I_OPCODE_I_LOAD: alu_src_2_o = MUX_SEL_OP2_IMM;
                RV32I_OPCODE_S: alu_src_2_o = MUX_SEL_OP2_IMM;
                default: alu_src_2_o = MUX_SEL_OP2_RS2;
            endcase
         end
    end : alu_src2_comb
    
    //Mux controling the Immediate value generator
    always_comb begin : imm_gen_sel_comb
        case (opcode_dec_s)
            RV32I_OPCODE_I_OPER, RV32I_OPCODE_I_LOAD : imm_gen_sel_o = IMM_12BITS_SGN_I;
            RV32I_OPCODE_U_LUI, RV32I_OPCODE_U_AUIPC : imm_gen_sel_o = IMM_20BITS_SHIFT_L_U;
            RV32I_OPCODE_S : imm_gen_sel_o = IMM_12BITS_UNSGN_S;
            RV32I_OPCODE_J : imm_gen_sel_o = IMM_20BITS_SGN_J;
            RV32I_OPCODE_I_JALR : imm_gen_sel_o = IMM_12BITS_SGN_I_JALR;
            RV32I_OPCODE_B : imm_gen_sel_o = IMM_12BITS_SGN_B;
            default : imm_gen_sel_o = IMM_ZERO;
        endcase
    end : imm_gen_sel_comb
    
	//Registers wall DEC ---> EXE
	register_n_bits #(32) EXE_INSTR_REG (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i(instr_cache_read_valid_i && data_cache_validity_i),
        .D_i(instr_dec_s),
        .Q_o(instr_exe_s)
    );
	//---------------------------------------------------------------------------------------//
	//Execute Stage
	//---------------------------------------------------------------------------------------//
	assign opcode_exe_s = instr_exe_s[6:0];
    assign rd_addr_exe_s = instr_exe_s[11:7];
    assign funct3_exe_s  = instr_exe_s[14:12];
    assign funct7_exe_s = instr_exe_s[31:25];
    
    //Mux controling the alu function to be used
    always_comb begin : alu_control_comb
        case(opcode_exe_s)
            RV32I_OPCODE_R, RV32I_OPCODE_I_OPER : begin
                case(funct3_exe_s)
                    RV32I_FUNCT3_R_ADD_SUB : begin
                        if (opcode_exe_s==RV32I_OPCODE_R) alu_function_o = ALU_SEL_ADD + funct7_exe_s[5];
                        else alu_function_o = ALU_SEL_ADD;
                    end
                    RV32I_FUNCT3_R_XOR : alu_function_o = ALU_SEL_XOR;
                    RV32I_FUNCT3_R_OR : alu_function_o = ALU_SEL_OR;
                    RV32I_FUNCT3_R_AND : alu_function_o = ALU_SEL_AND;
                    RV32I_FUNCT3_R_SLL : alu_function_o = ALU_SEL_SLL;
                    RV32I_FUNCT3_R_SRL_SRA : alu_function_o = ALU_SEL_SRL + funct7_exe_s[5];
                    RV32I_FUNCT3_R_SLT : alu_function_o = ALU_SEL_COMP;
                    RV32I_FUNCT3_R_SLTU : alu_function_o = ALU_SEL_COMP_UNSGN;
                    default : alu_function_o = ALU_SEL_ZERO;
                endcase
            end
            RV32I_OPCODE_I_JALR, RV32I_OPCODE_I_LOAD, RV32I_OPCODE_S, RV32I_OPCODE_U_AUIPC : alu_function_o = ALU_SEL_ADD;
            RV32I_OPCODE_B : begin
                case(funct3_exe_s)
                    RV32I_FUNCT3_BEQ, RV32I_FUNCT3_BNE : alu_function_o = ALU_SEL_SUB;
                    RV32I_FUNCT3_BLT, RV32I_FUNCT3_BGE : alu_function_o = ALU_SEL_COMP;
                    RV32I_FUNCT3_BLTU, RV32I_FUNCT3_BGEU : alu_function_o = ALU_SEL_COMP_UNSGN;
                    default : alu_function_o = ALU_SEL_COMP;
                endcase
            end
            RV32I_OPCODE_U_LUI : alu_function_o = ALU_SEL_OP1;
            default : alu_function_o = ALU_SEL_ZERO;
        endcase
    end : alu_control_comb
    
    //Mux checking if the branching need to be done or not
    always_comb begin : branch_taken_comb
        if (opcode_exe_s==RV32I_OPCODE_B) begin
            fetch_jalr_s = 1'b0;
            case(funct3_exe_s)
                RV32I_FUNCT3_BEQ, RV32I_FUNCT3_BGE, RV32I_FUNCT3_BGEU : branch_taken_s = zero_i;
                RV32I_FUNCT3_BNE, RV32I_FUNCT3_BLT, RV32I_FUNCT3_BLTU : branch_taken_s = ~zero_i;
                default : branch_taken_s = 1'b0;
            endcase
        end
        else if (opcode_exe_s==RV32I_OPCODE_B) begin
            branch_taken_s = 1'b0;
            fetch_jalr_s = 1'b1;
        end
        else begin 
            branch_taken_s = 1'b0;
            fetch_jalr_s = 1'b0;
        end
    end : branch_taken_comb
    
    //Registers wall EXE ---> MEM
    register_n_bits #(32) MEM_INSTR_REG (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i(instr_cache_read_valid_i && data_cache_validity_i),
        .D_i(instr_exe_s),
        .Q_o(instr_mem_s)
    );
    //---------------------------------------------------------------------------------------//
	//Memorize Stage
	//---------------------------------------------------------------------------------------//
	assign opcode_mem_s = instr_mem_s[6:0];
	assign rd_addr_mem_s = instr_mem_s[11:7];
	assign funct3_mem_s  = instr_mem_s[14:12];
    
    //Mux deciding if we need to write in memory
	always_comb begin : mem_write_enable_comb
	   case(opcode_mem_s)
	       RV32I_OPCODE_S : mem_write_enable_o = 1'b1;
	       default : mem_write_enable_o = 1'b0;
	   endcase
	end : mem_write_enable_comb
	
	//Mux deciding if we need to read in memory
	always_comb begin : mem_read_enable_comb
	   case(opcode_mem_s)
	       RV32I_OPCODE_I_LOAD : mem_read_enable_o = 1'b1;
	       default : mem_read_enable_o = 1'b0;
	   endcase
	end : mem_read_enable_comb
	
	//Mux generating the mask for memory writes and read if needed, for reads, also check if the word is signed or not
	always_comb begin : mem_mask_comb
	   case(opcode_mem_s)
	       RV32I_OPCODE_I_LOAD : begin
	           case(funct3_mem_s)
	               RV32I_FUNCT3_LOAD_8, RV32I_FUNCT3_LOAD_8_UNSGN : begin
	                   mem_data_mask_o = 4'b0001;
	                   mem_zero_extend_o = funct3_mem_s[2];
	               end
	               RV32I_FUNCT3_LOAD_16, RV32I_FUNCT3_LOAD_16_UNSGN : begin
	                   mem_data_mask_o = 4'b0011;
	                   mem_zero_extend_o = funct3_mem_s[2];
	               end
	               RV32I_FUNCT3_LOAD_32 : begin
	                   mem_data_mask_o = 4'b1111;
	                   mem_zero_extend_o = 1'b0;
	               end
	               default : begin
	                   mem_data_mask_o = 4'b0000;
	                   mem_zero_extend_o = 1'b0;
	               end
	           endcase
	       end
	       RV32I_OPCODE_S : begin
	           mem_zero_extend_o = 1'b0;
	           case(funct3_mem_s)
	               RV32I_FUNCT3_S_8 : mem_data_mask_o = 4'b0001;
	               RV32I_FUNCT3_S_16 : mem_data_mask_o = 4'b0011;
	               RV32I_FUNCT3_S_32 : mem_data_mask_o = 4'b1111;
	               default : mem_data_mask_o = 4'b0000;
	           endcase
	       end
	       default : begin
	           mem_data_mask_o = 4'b0000;
	           mem_zero_extend_o = 1'b0;
	       end
	   endcase
	end : mem_mask_comb
	
	//Registers wall MEM ---> WB
	register_n_bits #(32) WB_INSTR_REG (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .write_enable_i(instr_cache_read_valid_i && data_cache_validity_i),
        .D_i(instr_mem_s),
        .Q_o(instr_wb_s)
    );
	//---------------------------------------------------------------------------------------//
	//WriteBack Stage
	//---------------------------------------------------------------------------------------//
	assign opcode_wb_s = instr_wb_s[6:0];
    assign rd_addr_wb_s = instr_wb_s[11:7];
    
    //Mux controling if we can write in the register bank or not
    always_comb begin : reg_write_enable_comb
        case(opcode_wb_s)
            RV32I_OPCODE_I_ENVCSR, RV32I_OPCODE_S, RV32I_OPCODE_B : reg_write_enable_o = 1'b0;
            default : reg_write_enable_o = 1'b1;
        endcase
    end : reg_write_enable_comb
    
    //Mux controling which data need to be written in the register bank
    always_comb begin : write_back_select_comb
        case(opcode_wb_s)
            RV32I_OPCODE_I_JALR, RV32I_OPCODE_J : write_back_select_o = MUX_SEL_WB_PC_PLUS4;
            RV32I_OPCODE_I_LOAD : write_back_select_o = MUX_SEL_WB_MEM;
            default : write_back_select_o = MUX_SEL_WB_ALU;
        endcase
    end : write_back_select_comb
    
    //Sending the register bank writting adress back to the data_path (avoids propagating it through registers in the data_path)
    assign rd_addr_o = rd_addr_wb_s;
    //---------------------------------------------------------------------------------------//
	//Dependencies related logic 
	//---------------------------------------------------------------------------------------//
	////Logic being used to know which rd to select in the EXE stage for the bypass
	always_comb begin : rd_bypass_exe_select_comb
	   case (opcode_exe_s)
	       RV32I_OPCODE_I_JALR, RV32I_OPCODE_J : rd_bypass_exe_o = RD_EXE_BYPASS_PC_PLUS_4;
	       default : rd_bypass_exe_o = RD_EXE_BYPASS_ALU;
	   endcase 
	end : rd_bypass_exe_select_comb
	
	////Logic being used to know which rd to select in the MEM stage for the bypass
    always_comb begin : rd_bypass_mem_select_comb
        case (opcode_mem_s)
	       RV32I_OPCODE_I_JALR, RV32I_OPCODE_J : rd_bypass_mem_o = RD_MEM_BYPASS_PC_PLUS_4;
	       RV32I_OPCODE_I_LOAD : rd_bypass_mem_o = RD_MEM_BYPASS_MEM_DATA;
	       default : rd_bypass_mem_o = RD_MEM_BYPASS_ALU;
	   endcase 
    end : rd_bypass_mem_select_comb
	
	////Logic being used to generate the dependency related signals (stall, nop and bypass)
    always_comb begin : dependency_comb
        rd_usage_exe_s = rd_used(opcode_exe_s);
        rd_usage_mem_s = rd_used(opcode_mem_s);
        rd_usage_wb_s = rd_used(opcode_wb_s);
        case (opcode_dec_s)
            RV32I_OPCODE_R, RV32I_OPCODE_S, RV32I_OPCODE_B : begin
                fetch_jump_dec_s = 1'b0;
                ////Checking for dependency between RS1 and RD
                if (rs1_addr_dec_s==5'h00) begin
                    stall_rs1_s = 1'b0;
                    rs1_bypass_exe_s = 1'b0;
                    rs1_bypass_mem_s = 1'b0;
                    rs1_bypass_wb_s = 1'b0;
                end
                else if (opcode_exe_s == RV32I_OPCODE_I_LOAD) begin
                    stall_rs1_s = (~|(rs1_addr_dec_s ^ rd_addr_exe_s)) && rd_usage_exe_s;
                    rs1_bypass_exe_s = 1'b0;
                    rs1_bypass_mem_s = (~|(rs1_addr_dec_s ^ rd_addr_mem_s)) && rd_usage_mem_s;
                    rs1_bypass_wb_s = (~|(rs1_addr_dec_s ^ rd_addr_wb_s)) && rd_usage_wb_s;
                end
                else begin
                    stall_rs1_s = 1'b0;
                    rs1_bypass_exe_s = (~|(rs1_addr_dec_s ^ rd_addr_exe_s)) && rd_usage_exe_s;
                    rs1_bypass_mem_s = (~|(rs1_addr_dec_s ^ rd_addr_mem_s)) && rd_usage_mem_s;
                    rs1_bypass_wb_s = (~|(rs1_addr_dec_s ^ rd_addr_wb_s)) && rd_usage_wb_s;
                end 
                ////Checking for dependency between RS2 and RD
                if (rs2_addr_dec_s==5'h00) begin
                    stall_rs2_s = 1'b0;
                    rs2_bypass_exe_s = 1'b0;
                    rs2_bypass_mem_s = 1'b0;
                    rs2_bypass_wb_s = 1'b0;
                end
                else if (opcode_exe_s == RV32I_OPCODE_I_LOAD) begin
                    stall_rs2_s = (~|(rs2_addr_dec_s ^ rd_addr_exe_s)) && rd_usage_exe_s;
                    rs2_bypass_exe_s = 1'b0;
                    rs2_bypass_mem_s = (~|(rs2_addr_dec_s ^ rd_addr_mem_s)) && rd_usage_mem_s;
                    rs2_bypass_wb_s = (~|(rs2_addr_dec_s ^ rd_addr_wb_s)) && rd_usage_wb_s;
                end
                else begin
                    stall_rs2_s = 1'b0;
                    rs2_bypass_exe_s = (~|(rs2_addr_dec_s ^ rd_addr_exe_s)) && rd_usage_exe_s;
                    rs2_bypass_mem_s = (~|(rs2_addr_dec_s ^ rd_addr_mem_s)) && rd_usage_mem_s;
                    rs2_bypass_wb_s = (~|(rs2_addr_dec_s ^ rd_addr_wb_s)) && rd_usage_wb_s;
                end
                stall_s = stall_rs1_s | stall_rs2_s;
            end
            RV32I_OPCODE_I_JALR, RV32I_OPCODE_I_LOAD, RV32I_OPCODE_I_OPER, RV32I_OPCODE_I_ENVCSR : begin
                fetch_jump_dec_s = 1'b0;
                rs2_bypass_exe_s = 1'b0;
                rs2_bypass_mem_s = 1'b0;
                rs2_bypass_wb_s = 1'b0;
                ////Checking for dependency between RS1 and RD
                if (rs1_addr_dec_s==5'h00) begin
                    stall_s = 1'b0;
                    rs1_bypass_exe_s = 1'b0;
                    rs1_bypass_mem_s = 1'b0;
                    rs1_bypass_wb_s = 1'b0;
                end
                else if (opcode_exe_s == RV32I_OPCODE_I_LOAD) begin
                    stall_s = (~|(rs1_addr_dec_s ^ rd_addr_exe_s)) && rd_usage_exe_s;
                    rs1_bypass_exe_s = 1'b0;
                    rs1_bypass_mem_s = (~|(rs1_addr_dec_s ^ rd_addr_mem_s)) && rd_usage_mem_s;
                    rs1_bypass_wb_s = (~|(rs1_addr_dec_s ^ rd_addr_wb_s)) && rd_usage_wb_s;
                end
                else begin
                    stall_s = 1'b0;
                    rs1_bypass_exe_s = (~|(rs1_addr_dec_s ^ rd_addr_exe_s)) && rd_usage_exe_s;
                    rs1_bypass_mem_s = (~|(rs1_addr_dec_s ^ rd_addr_mem_s)) && rd_usage_mem_s;
                    rs1_bypass_wb_s = (~|(rs1_addr_dec_s ^ rd_addr_wb_s)) && rd_usage_wb_s;
                end 
            end
            RV32I_OPCODE_J : begin
                stall_s = 1'b0;
                fetch_jump_dec_s = 1'b1;
                rs1_bypass_exe_s = 1'b0;
                rs1_bypass_mem_s = 1'b0;
                rs1_bypass_wb_s = 1'b0;
                rs2_bypass_exe_s = 1'b0;
                rs2_bypass_mem_s = 1'b0;
                rs2_bypass_wb_s = 1'b0;
            end
            default : begin
                stall_s = 1'b0;
                fetch_jump_dec_s = 1'b0;
                rs1_bypass_exe_s = 1'b0;
                rs1_bypass_mem_s = 1'b0;
                rs1_bypass_wb_s = 1'b0;
                rs2_bypass_exe_s = 1'b0;
                rs2_bypass_mem_s = 1'b0;
                rs2_bypass_wb_s = 1'b0;
            end
        endcase
        fetch_branch_s = branch_taken_s || fetch_jalr_s;
        fetch_jump_exe_s = branch_taken_s || fetch_jalr_s;
        fetch_jump_s = fetch_jump_dec_s | fetch_jump_exe_s;
    end : dependency_comb
    
    ////Assignation of the output signal for the bypass for S type instructions
    always_comb begin : bypass_S_type_comb
        if (rs2_bypass_exe_s) mem_data_select_o = RS2_BYPASS_EXE;
        else if (rs2_bypass_mem_s) mem_data_select_o = RS2_BYPASS_MEM;
        else if (rs2_bypass_wb_s) mem_data_select_o = RS2_BYPASS_WB;
        else mem_data_select_o = RS2_BYPASS_REG_BANK;
    end : bypass_S_type_comb
  
    assign stall_o = stall_s;
    assign fetch_jump_o = fetch_jump_s;
    assign fetch_branch_o = fetch_branch_s;
endmodule : controlpath_pipeline