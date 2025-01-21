//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 13/01/2025
// Design Name: write_back_cache_tb.sv
// Module Name: write_back_cache_tb
// Project Name: RISCV_RV32i_pipeline
// Description: TestBench for the Write through enabled cache
//
// Dependencies:
// write_back_cache.sv
// dram_emulation_mem.sv
//
// Current revision : 0.1
// Last modification : 13/01/2025
//
// Revision: 0.1
// Additional Comments: Not currently completed, file creation and first additions.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module write_back_cache_tb #(
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
    logic write_en_r;
    logic [31:0] addr_r;
    logic mem_read_valid_r;
    logic mem_write_en_r;
    logic [31:0] write_word_r;
    logic [LineSize-1:0] mem_read_data_r;
    logic [LineSize-1:0] mem_write_data_r;
    //Outputs
    logic read_valid_r;
    logic write_valid_r;
    logic [31:0] read_word_r;
    logic [31:0] mem_addr_r;
    logic mem_read_en_r;
    logic mem_write_valid_r;
    
    real freq = FREQ;
    real half_period;
    
    write_back_cache #(ByteOffsetBits,IndexBits,TagBits,4) DUT(
        //General ports
        .clk_i(clk_r),
        .rstn_i(resetn_r),
        .addr_i(addr_r),
        //Read ports
        .read_en_i(read_en_r),
        .read_valid_o(read_valid_r),
        .read_word_o(read_word_r),
        //Write ports
        .write_en_i(write_en_r),
        .write_word_i(write_word_r),
        .write_valid_o(write_valid_r),
        //Memory general ports
        .mem_addr_o(mem_addr_r),
        //Memory read ports
        .mem_read_valid_i(mem_read_valid_r),
        .mem_read_data_i(mem_read_data_r),
        .mem_read_en_o(mem_read_en_r),
        //Memory write ports
        .mem_write_en_o(mem_write_en_r),
        .mem_write_data_o(mem_write_data_r),
        .mem_write_valid_i(mem_write_valid_r)
    );
    
    dram_emulation_mem #(ByteOffsetBits,4096,"../../../../firmware/data_multway_dram.txt",10) DRAM(
        //General ports
        .clk_i(clk_r),
        .add_i(mem_addr_r),
        //Write ports
        .write_enable_i(mem_write_en_r),
        .data_i(mem_write_data_r),
        .write_valid_o(mem_write_valid_r),
        //Read ports
        .read_enable_i(mem_read_en_r),
        .read_valid_o(mem_read_valid_r),
        .data_o(mem_read_data_r)
    );
    
    //clock generator
    always begin
        #(half_period) clk_r = ~clk_r;
    end
    
    initial begin
        half_period = realtime'($ceil(500.0 / freq));
        ////Initialisation
        clk_r = 1'b0;
        resetn_r = 1'b1;
        read_en_r = 1'b0;
        write_en_r = 1'b0;
        write_word_r = 32'h00000000;
        addr_r = 32'h00000000;
        #1 resetn_r = 1'b0;
        repeat (2) begin
          @(posedge clk_r);
        end
        #0.1 resetn_r = 1'b1;
        @(posedge clk_r);
        ////Testbench tailored to stress the multiway cache
        //First write in memory cache, L1, W0, Tag 0
        write_en_r = 1'b1;
        addr_r = 32'h00000010;
        write_word_r = 32'hDEADBEEF;
        repeat (25) begin
          @(posedge clk_r);
        end
        //First read in memory cache, L1, W1, Tag 1
        write_en_r = 1'b0;
        read_en_r = 1'b1;
        addr_r = 32'h00000114;
        repeat (25) begin
          @(posedge clk_r);
        end
        //Second write in memory cache, L1, W2, Tag 0
        write_en_r = 1'b1;
        read_en_r = 1'b0;
        addr_r = 32'h00000018;
        write_word_r = 32'hABCDABCD;
        repeat (25) begin
          @(posedge clk_r);
        end
        //Third write in memory cache, L1, W1, 2nd Tag
        addr_r = 32'h00000214;
        write_word_r = 32'h12345678;
        repeat (25) begin
          @(posedge clk_r);
        end
        //Fourth write in memory cache, L1, W0, Tag 0
        write_en_r = 1'b1;
        read_en_r = 1'b0;
        addr_r = 32'h00000010;
        write_word_r = 32'hABBAABBA;
        repeat (25) begin
          @(posedge clk_r);
        end
        //Fifth write in memory cache, L1, W3, Tag 3
        write_en_r = 1'b1;
        read_en_r = 1'b0;
        addr_r = 32'h0000031c;
        write_word_r = 32'h69696969;
        repeat (25) begin
          @(posedge clk_r);
        end
        //Sixth write in memory cache, L1, W1, Tag 4
        write_en_r = 1'b1;
        read_en_r = 1'b0;
        addr_r = 32'h00000414;
        write_word_r = 32'h52525252;
        repeat (25) begin
          @(posedge clk_r);
        end
        //Second read in memory cache, L1, W1, Tag 2
        write_en_r = 1'b0;
        read_en_r = 1'b1;
        addr_r = 32'h00000214;
        repeat (25) begin
          @(posedge clk_r);
        end
        //Sixth write in memory cache, L1, W2, Tag 5
        write_en_r = 1'b1;
        read_en_r = 1'b0;
        addr_r = 32'h00000518;
        write_word_r = 32'hFFFFFFFF;
        repeat (25) begin
          @(posedge clk_r);
        end
        $stop;
    end
endmodule : write_back_cache_tb