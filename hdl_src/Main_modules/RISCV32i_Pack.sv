//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 07/01/2025
// Design Name: RISCV32i_Pack.sv
// Module Name: RISCV32i_Pack
// Project Name: RISCV_RV32i_pipeline
// Description: Package for the RV32i architecture, based on personnal and external documents and packages (by michel agoyan)
// 
// Dependencies: x
//
// Current revision : 1.1
// Last modification : 15/01/2025
//
// Revision: 1.1
// Additional Comments: Added constant for the bypass.
//
// Revision: 1.0
// Additional Comments: Completed for the current implementation
// 
// Revision: 0.1
// Additional Comments: Not currently completed, file creation and first additions
// 
//////////////////////////////////////////////////////////////////////////////////

package RISCV32i_Pack;
	//---------------------------------------------------------------------------------------//
	//Format for different opcodes
	//---------------------------------------------------------------------------------------//
	////R Type 
	const logic [6 : 0] RV32I_OPCODE_R = 7'b0110011;   //7'h;
	////I Type 
	const logic [6 : 0] RV32I_OPCODE_I_JALR = 7'b1100111;
    const logic [6 : 0] RV32I_OPCODE_I_LOAD = 7'b0000011;
    const logic [6 : 0] RV32I_OPCODE_I_OPER = 7'b0010011;
    const logic [6 : 0] RV32I_OPCODE_I_ENVCSR = 7'b1110011;
    ////S Type 
    const logic [6 : 0] RV32I_OPCODE_S = 7'b0100011;
    ////B Type 
    const logic [6 : 0] RV32I_OPCODE_B = 7'b1100011;
    ////J Type 
    const logic [6 : 0] RV32I_OPCODE_J = 7'b1101111;
    ////U Type 
    const logic [6 : 0] RV32I_OPCODE_U_LUI = 7'b0110111;
    const logic [6 : 0] RV32I_OPCODE_U_AUIPC = 7'b0010111;
    //---------------------------------------------------------------------------------------//
	//Format for different Func3 codes
	//---------------------------------------------------------------------------------------//
	////R Type 
	const logic [2 : 0] RV32I_FUNCT3_R_ADD_SUB = 3'b000;
	const logic [2 : 0] RV32I_FUNCT3_R_XOR = 3'b100;
	const logic [2 : 0] RV32I_FUNCT3_R_OR = 3'b110;
	const logic [2 : 0] RV32I_FUNCT3_R_AND = 3'b111;
	const logic [2 : 0] RV32I_FUNCT3_R_SLL = 3'b001;
	const logic [2 : 0] RV32I_FUNCT3_R_SRL_SRA = 3'b101;
	const logic [2 : 0] RV32I_FUNCT3_R_SLT = 3'b010;
	const logic [2 : 0] RV32I_FUNCT3_R_SLTU = 3'b011;
	////I Type 
	const logic [2 : 0] RV32I_FUNCT3_I_ADDI = 3'b000;
	const logic [2 : 0] RV32I_FUNCT3_I_XORI = 3'b100;
	const logic [2 : 0] RV32I_FUNCT3_I_ORI = 3'b110;
	const logic [2 : 0] RV32I_FUNCT3_I_ANDI = 3'b111;
	const logic [2 : 0] RV32I_FUNCT3_I_SLLI = 3'b001;
	const logic [2 : 0] RV32I_FUNCT3_I_SRLI_SRAI = 3'b101;
	const logic [2 : 0] RV32I_FUNCT3_I_SLTI = 3'b010;
	const logic [2 : 0] RV32I_FUNCT3_I_SLTIU = 3'b011;
	////Load Type
	const logic [2 : 0] RV32I_FUNCT3_LOAD_8 = 3'b000;
	const logic [2 : 0] RV32I_FUNCT3_LOAD_16 = 3'b001;
	const logic [2 : 0] RV32I_FUNCT3_LOAD_32 = 3'b010;
	const logic [2 : 0] RV32I_FUNCT3_LOAD_8_UNSGN = 3'b100;
	const logic [2 : 0] RV32I_FUNCT3_LOAD_16_UNSGN = 3'b101;
	////S Type
	const logic [2 : 0] RV32I_FUNCT3_S_8 = 3'b000;
	const logic [2 : 0] RV32I_FUNCT3_S_16 = 3'b001;
	const logic [2 : 0] RV32I_FUNCT3_S_32 = 3'b010;
	////B Type 
	const logic [2 : 0] RV32I_FUNCT3_BEQ = 3'b000;
    const logic [2 : 0] RV32I_FUNCT3_BNE = 3'b001;
    const logic [2 : 0] RV32I_FUNCT3_BLT = 3'b100;
    const logic [2 : 0] RV32I_FUNCT3_BGE = 3'b101;
    const logic [2 : 0] RV32I_FUNCT3_BLTU = 3'b110;
    const logic [2 : 0] RV32I_FUNCT3_BGEU = 3'b111;
    //---------------------------------------------------------------------------------------//
	//PC related 
	//---------------------------------------------------------------------------------------//
	const logic [2 : 0] SEL_PC_PLUS_4 = 3'b000;     // PC += 4
    const logic [2 : 0] SEL_PC_JAL = 3'b001;        // PC += IMM
    const logic [2 : 0] SEL_PC_JALR = 3'b010;       // PC += RS1 + IMM ~ !0x1 (JALR instruction)
    const logic [2 : 0] SEL_PC_BRANCH = 3'b011;     // PC += IMM
    const logic [2 : 0] SEL_PC_EXCEPTION = 3'b111;  // PC =  0x1C090000
    //---------------------------------------------------------------------------------------//
	//RD related 
	//---------------------------------------------------------------------------------------//
	////For the EXE stage
	const logic RD_EXE_BYPASS_ALU = 1'b0;
	const logic RD_EXE_BYPASS_PC_PLUS_4 = 1'b1;
	////For the MEM stage
	const logic [1 : 0] RD_MEM_BYPASS_ALU = 2'b00;
	const logic [1 : 0] RD_MEM_BYPASS_PC_PLUS_4 = 2'b01;
	const logic [1 : 0] RD_MEM_BYPASS_MEM_DATA = 2'b10;
	const logic [1 : 0] RD_MEM_BYPASS_X = 2'b11;
	////Specific for the S Type instruction
	const logic [1 : 0] RS2_BYPASS_REG_BANK = 2'b00;
	const logic [1 : 0] RS2_BYPASS_EXE = 2'b01;
	const logic [1 : 0] RS2_BYPASS_MEM = 2'b10;
	const logic [1 : 0] RS2_BYPASS_WB = 2'b11;
    //---------------------------------------------------------------------------------------//
	//IMM GEN related 
	//---------------------------------------------------------------------------------------//
	const logic [2 : 0] IMM_ZERO = 3'b000;
	const logic [2 : 0] IMM_12BITS_SGN_I = 3'b001;
	const logic [2 : 0] IMM_20BITS_SHIFT_L_U = 3'b010;
	const logic [2 : 0] IMM_12BITS_UNSGN_S = 3'b011;
	const logic [2 : 0] IMM_20BITS_SGN_J = 3'b100;
	const logic [2 : 0] IMM_12BITS_SGN_I_JALR = 3'b101;
	const logic [2 : 0] IMM_12BITS_SGN_B = 3'b110;
	//---------------------------------------------------------------------------------------//
	//ALU related 
	//---------------------------------------------------------------------------------------//
	////Alu operand1 selector
    const logic [2 : 0] MUX_SEL_OP1_RS1 = 3'b000;
    const logic [2 : 0] MUX_SEL_OP1_IMM = 3'b001;
    const logic [2 : 0] MUX_SEL_OP1_PC = 3'b010;
    const logic [2 : 0] MUX_SEL_OP1_BYPASS_EXE = 3'b011;
    const logic [2 : 0] MUX_SEL_OP1_BYPASS_MEM = 3'b100;
    const logic [2 : 0] MUX_SEL_OP1_BYPASS_WB = 3'b101;
    ////Alu operand2 selector
    const logic [2 : 0] MUX_SEL_OP2_RS2 = 3'b000;
    const logic [2 : 0] MUX_SEL_OP2_IMM = 3'b001;
    const logic [2 : 0] MUX_SEL_OP2_BYPASS_EXE = 3'b010;
    const logic [2 : 0] MUX_SEL_OP2_BYPASS_MEM = 3'b011;
    const logic [2 : 0] MUX_SEL_OP2_BYPASS_WB = 3'b100;
    ////Alu control selector
    const logic [3 : 0] ALU_SEL_ZERO = 4'h0;
    const logic [3 : 0] ALU_SEL_ADD = 4'h1;
    const logic [3 : 0] ALU_SEL_SUB = 4'h2;
    const logic [3 : 0] ALU_SEL_SLL = 4'h3;
    const logic [3 : 0] ALU_SEL_SRL = 4'h4;
    const logic [3 : 0] ALU_SEL_SRA = 4'h5;
    const logic [3 : 0] ALU_SEL_AND = 4'h6;
    const logic [3 : 0] ALU_SEL_OR = 4'h7;
    const logic [3 : 0] ALU_SEL_XOR = 4'h8;
    const logic [3 : 0] ALU_SEL_COMP = 4'h9;
    const logic [3 : 0] ALU_SEL_COMP_UNSGN = 4'ha;
    const logic [3 : 0] ALU_SEL_OP1 = 4'hb;
    //---------------------------------------------------------------------------------------//
	//Register Bank related 
	//---------------------------------------------------------------------------------------//
	const logic [1 : 0] MUX_SEL_WB_MEM = 2'b00;
	const logic [1 : 0] MUX_SEL_WB_ALU = 2'b01;
	const logic [1 : 0] MUX_SEL_WB_PC_PLUS4 = 2'b10;
	const logic [1 : 0] MUX_SEL_WB_X = 2'b11;
endpackage : RISCV32i_Pack