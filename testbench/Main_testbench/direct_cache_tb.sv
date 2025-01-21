//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 18/12/2024
// Design Name: direct_cache_tb.sv
// Module Name: direct_cache_tb
// Project Name: RISCV_RV32i_pipeline
// Description: TestBench for the multi way cache, paired with a dram
//
// Dependencies:
// direct_cache.sv
//
// Current revision : 1.0
// Last modification : 18/12/2024
//
// Revision: 1.0
// Additional Comments: Completely functionnal for the current spec. Input/Outputs/Parameters added for the DUT.
// 
// Revision: 0.1
// Additional Comments: Not currently completed, file creation and first additions. DUT not completed with 
//                     its input/outputs and parameters
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module direct_cache_tb #(
    localparam ByteOffsetBits = 4,
    localparam IndexBits = 6,
    localparam TagBits = 22,
    localparam NrWordsPerLine = (2**ByteOffsetBits)/4,
    localparam NrLines = 2**IndexBits,
    localparam LineSize = 32 * NrWordsPerLine
)();
    //Inputs
    logic clk_r;
    logic resetn_r;
    logic read_en_r;
    logic [31:0] addr_r;
    logic mem_read_valid_r;
    logic [LineSize-1:0] mem_read_data_r;
    //Outputs
    logic read_valid_r;
    logic [31:0] read_word_r;
    logic [31:0] mem_addr_r;
    logic mem_read_en_r;
    
    real freq = 100;
    real half_period;
    
    direct_cache #(ByteOffsetBits,IndexBits,TagBits) DUT(
        .clk_i(clk_r),
        .rstn_i(resetn_r),
        .addr_i(addr_r),
        .read_en_i(read_en_r),
        .read_valid_o(read_valid_r),
        .read_word_o(read_word_r),
        .mem_addr_o(mem_addr_r),
        .mem_read_valid_i(mem_read_valid_r),
        .mem_read_data_i(mem_read_data_r),
        .mem_read_en_o(mem_read_en_r)
    );
    
    //clock generator
    always begin
        #(half_period) clk_r = ~clk_r;
    end
    
    initial begin
        half_period = realtime'($ceil(500.0 / freq));
        clk_r = 1'b0;
        resetn_r = 1'b1;
        read_en_r = 1'b0;
        #1 resetn_r = 1'b0;
        repeat (5) begin
          @(posedge clk_r);
        end
        #0.1 resetn_r = 1'b1;
        @(posedge clk_r);
        addr_r = 32'h00000414;
        read_en_r = 1'b1;
        mem_read_valid_r = 1'b0;
        repeat (3) begin
          @(posedge clk_r);
        end
        mem_read_data_r = 128'hDEADBEEFDEADBEEFFEFEFEFEBEEFDEAD;
        mem_read_valid_r = 1'b1;
        @(posedge clk_r);
        mem_read_valid_r = 1'b0;
        mem_read_data_r = 128'h00000000000000000000000000000000;
        @(posedge clk_r);
        addr_r = 32'h00000424;
        repeat (3) begin
          @(posedge clk_r);
        end
        mem_read_data_r = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        mem_read_valid_r = 1'b1;
        @(posedge clk_r);
        mem_read_data_r = 128'h00000000000000000000000000000000;
        mem_read_valid_r = 1'b0;
        @(posedge clk_r);
        @(posedge clk_r);
        read_en_r = 1'b0;
        addr_r = 32'h00000410;
        @(posedge clk_r);
        read_en_r = 1'b1;
        addr_r = 32'h00000440;
        repeat (3) begin
          @(posedge clk_r);
        end
        mem_read_valid_r = 1'b1;
        mem_read_data_r = 128'hEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE;
        @(posedge clk_r);
        mem_read_data_r = 128'h00000000000000000000000000000000;
        mem_read_valid_r = 1'b0;
        @(posedge clk_r);
        addr_r = 32'h0000041c;
        @(posedge clk_r);
        addr_r = 32'h00000418;
        @(posedge clk_r);
        @(posedge clk_r);
        addr_r = 32'h00000818;
        mem_read_valid_r = 1'b0;
        repeat (3) begin
          @(posedge clk_r);
        end
        mem_read_data_r = 128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
        mem_read_valid_r = 1'b1;
        @(posedge clk_r);
        mem_read_valid_r = 1'b0;
        repeat (3) begin
          @(posedge clk_r);
        end
        read_en_r = 1'b0;
        repeat (3) begin
          @(posedge clk_r);
        end
        $stop;
    end
endmodule : direct_cache_tb
