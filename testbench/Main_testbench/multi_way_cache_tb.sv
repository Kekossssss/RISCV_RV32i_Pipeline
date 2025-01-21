//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 21/12/2024
// Design Name: multi_way_cache_tb.sv
// Module Name: multi_way_cache_tb
// Project Name: RISCV_RV32i_pipeline
// Description: TestBench for the multi way cache, paired with a dram
//
// Dependencies:
// multi_way_cache.sv
// dram_emulation_mem.sv
//
// Current revision : 1.0
// Last modification : 22/12/2024
//
// Revision: 1.0
// Additional Comments: Completely functionnal for the current spec. Input/Outputs/Parameters added for the DUT.
// 
// Revision: 0.1
// Additional Comments: Not currently completed, file creation and first additions. DUT not completed with 
//                     its input/outputs and parameters
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module multi_way_cache_tb #(
    localparam ByteOffsetBits = 4,
    localparam IndexBits = 4,
    localparam TagBits = 24,
    localparam NrWordsPerLine = (2**ByteOffsetBits)/4,
    localparam NrLines = 2**IndexBits,
    localparam LineSize = 32 * NrWordsPerLine,
    localparam FREQ = 100
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
    
    real freq = FREQ;
    real half_period;
    
    multi_way_cache #(ByteOffsetBits,IndexBits,TagBits,4) DUT(
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
    
    dram_emulation_mem #(ByteOffsetBits,IndexBits,TagBits,65536,"../../../../firmware/data_multway_dram.txt",10) DRAM(
        .clk_i(clk_r),
        //.write_enable_i(mem_write_en_o),
        .read_enable_i(mem_read_en_r),
        //.data_i(mem_write_data_o),
        .add_i(mem_addr_r),
        .read_valid_o(mem_read_valid_r),
        .data_o(mem_read_data_r)
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
    
        repeat (15) begin
          @(posedge clk_r);
        end
    
        #0.1 resetn_r = 1'b1;
        @(posedge clk_r);
        ////Testbench tailored to stress the multiway cache
        addr_r = 32'h00000114;
        read_en_r = 1'b1;
        repeat (15) begin
          @(posedge clk_r);
        end
        addr_r = 32'h00000214;
        repeat (15) begin
          @(posedge clk_r);
        end
        addr_r = 32'h00000314;
        repeat (15) begin
          @(posedge clk_r);
        end
        addr_r = 32'h00000214;
        repeat (15) begin
          @(posedge clk_r);
        end
        addr_r = 32'h00000414;
        repeat (15) begin
          @(posedge clk_r);
        end
        addr_r = 32'h00000514;
        repeat (15) begin
          @(posedge clk_r);
        end
        addr_r = 32'h00000614;
        repeat (15) begin
          @(posedge clk_r);
        end
        addr_r = 32'h00000714;
        repeat (15) begin
          @(posedge clk_r);
        end
        addr_r = 32'h00000814;
        repeat (15) begin
          @(posedge clk_r);
        end
        addr_r = 32'h00000914;
        repeat (15) begin
          @(posedge clk_r);
        end
        addr_r = 32'h00000a14;
        repeat (15) begin
          @(posedge clk_r);
        end
        
        ////Simple testbench
//        addr_r = 32'h00000414;
//        read_en_r = 1'b1;
//        repeat (15) begin
//          @(posedge clk_r);
//        end
//        addr_r = 32'h00000424;
//        @(posedge clk_r);
//        read_en_r = 1'b1;
//        repeat (15) begin
//          @(posedge clk_r);
//        end
//        read_en_r = 1'b0;
//        addr_r = 32'h00000410;
//        @(posedge clk_r);
//        read_en_r = 1'b1;
//        addr_r = 32'h00000440;
//        repeat (15) begin
//          @(posedge clk_r);
//        end
//        addr_r = 32'h0000041c;
//        @(posedge clk_r);
//        @(posedge clk_r);
//        addr_r = 32'h00000418;
//        @(posedge clk_r);
//        @(posedge clk_r);
//        addr_r = 32'h00000818;
//        repeat (15) begin
//          @(posedge clk_r);
//        end
//        read_en_r = 1'b0;
//        repeat (8) begin
//          @(posedge clk_r);
//        end
        $stop;
    end
endmodule : multi_way_cache_tb