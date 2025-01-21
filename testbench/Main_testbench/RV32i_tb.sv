//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 08/01/2025
// Design Name: RV32i_tb.sv
// Module Name: RV32i_tb
// Project Name: RISCV_RV32i_pipeline
// Description: TestBench for the RISCV RV32i processor, made to stop when an instruction to write 0xDEADBEEF in
//             the x1 register
//
// Dependencies:
// soc_pipeline.sv
//
// Current revision : 1.0
// Last modification : 10/01/2025
//
// Revision: 1.0
// Additional Comments: Completely functionnal for the current spec. Input/Outputs/Parameters added for the DUT.
// 
// Revision: 0.1
// Additional Comments: Not currently completed, file creation and first additions. DUT not completed with 
//                     its input/outputs and parameters
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module RV32i_tb #(
    localparam ByteOffsetBits = 4,
    localparam IndexBits = 4,
    localparam TagBits = 24,
    localparam Nb_ways = 4,
    localparam NrWordsPerLine = (2**ByteOffsetBits)/4,
    localparam NrLines = 2**IndexBits,
    localparam LineSize = 32 * NrWordsPerLine,
    localparam Dram_size = 16384,
    localparam Dram_latency_cycle = 10,
    real FREQ = 100,
    real HALF_PERIOD = 1000/(2*FREQ)
) ();
  //---------------------------------------------------------------------------------------//
  //Internal connection declaration
  //---------------------------------------------------------------------------------------//
  logic clk_r;
  logic resetn_r;
  logic [31:0] inst_w;
  //---------------------------------------------------------------------------------------//
  //Programs to execute
  //---------------------------------------------------------------------------------------//
  // To test the data memory : imem_memcpy.hex and data_memcpy.txt
  // To test the multiplication : imem_mult_modif_boucle.hex
  // To test the multiway cache : imem_multway_stress.hex
  //---------------------------------------------------------------------------------------//
  //Module declaration
  //---------------------------------------------------------------------------------------//
  soc_pipeline #(
      .instruction_file("../../../../firmware/imem_memcpy.hex"),
      .data_file("../../../../firmware/data_memcpy.txt"),
      .BYTE_OFF_BITS(ByteOffsetBits),
      .INDEX_BITS(IndexBits),
      .TAG_BITS(TagBits),
      .NB_WAYS(Nb_ways),
      .SIZE_DRAM(Dram_size),
      .CYCLE_LATENCE_DRAM(Dram_latency_cycle)
  ) RV32i_soc (
      .clk_i(clk_r),
      .rst_i(resetn_r)
  );
  ////Fetching of the instruction in order to stop the testbench at the end of the programm
  assign inst_w=RV32i_tb.RV32i_soc.CORE_1.instr_cache_data_s;

  //---------------------------------------------------------------------------------------//
  //Clock generator
  //---------------------------------------------------------------------------------------//
  always begin
    #(HALF_PERIOD) clk_r = ~clk_r;
  end
  //---------------------------------------------------------------------------------------//
  //Test
  //---------------------------------------------------------------------------------------//
  initial begin
    clk_r = 1'b0;
    resetn_r = 1'b1;
    #1 resetn_r = 1'b0;

    repeat (5) begin
      @(posedge clk_r);
    end

    #0.1 resetn_r = 1'b1;
    @(posedge clk_r);

    wait (inst_w == 32'hFF9FF06F);

    repeat (5) begin
      @(posedge clk_r);
    end

    $stop;
  end

endmodule
