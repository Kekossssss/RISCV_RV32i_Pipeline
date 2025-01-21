//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 09/12/2024
// Design Name: direct_cache.sv
// Module Name: direct_cache
// Project Name: RISCV_RV32i_pipeline
// Description: Direct cache module, represented with registers,read and write are synchronous
// 
// Dependencies: x
// 
// Current revision : 1.0
// Last modification : 09/12/2024
//
// Revision: 1.0
// Additional Comments: Completed and tested. Fully working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module direct_cache #(
    parameter ByteOffsetBits = 5,
    parameter IndexBits = 5,
    parameter TagBits = 22,
    localparam NrWordsPerLine = (2**ByteOffsetBits)/4,
    localparam NrLines = 2**IndexBits,
    localparam LineSize = 32 * NrWordsPerLine
) (
    input logic clk_i,
    input logic rstn_i,
    input logic [31:0] addr_i,

    // Read port
    input logic read_en_i,
    output logic read_valid_o,
    output logic [31:0] read_word_o,

    // Write port
    //input logic write_en_i,
    //input logic [31:0] write_word_i,
    //output logic write_valid_o,

    // Memory
    output logic [31:0] mem_addr_o,

    // Memory read port
    output logic mem_read_en_o,
    input logic mem_read_valid_i,
    input logic [LineSize-1:0] mem_read_data_i//,

    // Memory write port
    //output logic mem_write_en_o,
    //output logic [LineSize-1:0] mem_write_data_o,
    //input logic mem_write_valid_i
);
    //---------------------------------------------------------------------------------------//
	//Internal connections declaration
	//---------------------------------------------------------------------------------------//
    //Address segmentation
    logic [ByteOffsetBits-1:0] read_offset;
    logic [ByteOffsetBits-1:0] read_offset_zero = 0;
    logic [IndexBits-1:0] read_index;
    logic [TagBits-1:0] read_tag;
    
    //Cache elements
    logic cache_line_validity[NrLines-1:0];
    logic [TagBits-1:0] cache_tags[NrLines-1:0];
    logic [LineSize-1:0] cache_words[NrLines-1:0];
    
    //Register Outputs
    logic [NrLines-1:0][TagBits-1:0] registers_output_lines_tags;
    logic [NrLines-1:0][LineSize-1:0] registers_output_all;
    logic [LineSize-1:0] registers_output_line;
    logic [NrWordsPerLine-1:0][31:0] registers_output_words;
    
    //Internal logic connections
    logic hit_w;
    
    //---------------------------------------------------------------------------------------//
	//"Pre-memory" logic of the module
	//---------------------------------------------------------------------------------------//
    //Generation of the hit signal, stating if the data is present in the cache
    always_comb begin : hit_or_miss
        if (cache_tags[read_index]==read_tag && read_en_i && cache_line_validity[read_index]) hit_w = 1'b1;
        else hit_w = 1'b0; 
    end : hit_or_miss
    
    //Segmetation of the input adress into smaller signals to facilitate code writting
    always_comb begin : adress_segmentation
        if (rstn_i==1'b0) begin
            read_offset = 0;
            read_index = 0;
            read_tag = 0;
        end
        else if (read_en_i) begin
            read_offset = addr_i[ByteOffsetBits-1:2];
            read_index = addr_i[IndexBits+ByteOffsetBits-1:ByteOffsetBits];
            read_tag = addr_i[TagBits+IndexBits+ByteOffsetBits-1:IndexBits+ByteOffsetBits];
        end
    end : adress_segmentation
    
    //Memory outputs
    assign mem_addr_o = {read_tag,read_index,read_offset_zero};
    
    //---------------------------------------------------------------------------------------//
	//"Memory" of the module
	//---------------------------------------------------------------------------------------//
    //Registers implementation
    generate
        for (genvar i=0;i<NrLines;i++) begin : registers_cache
            always_ff @(posedge clk_i or negedge rstn_i) begin : write_cache
                if(rstn_i==1'b0) begin
                    cache_line_validity[i] <= 1'b0;
                    cache_tags[i] <= 0;
                    cache_words[i] <= 0;
                end
                //Line writting from memory
                else if (mem_read_valid_i && (read_index==i)) begin
                    cache_line_validity[i] <= 1'b1;
                    cache_tags[i] <= read_tag;
                    cache_words[i] <= mem_read_data_i;
                end
            end : write_cache
            always_comb begin : read_cache
                registers_output_lines_tags[i] <= cache_tags[i];
                registers_output_all[i] <= cache_words[i];
            end : read_cache
        end : registers_cache
     endgenerate 
     
     //---------------------------------------------------------------------------------------//
	 //"Post-Memory" logic of the module
	 //---------------------------------------------------------------------------------------//
     //Registers output logic and data assignation
     always_comb begin : mux_read_out
        //Bypass of the incoming data from memory directly to the lower level memory/CPU
        if (mem_read_valid_i && read_en_i) begin
            registers_output_line = mem_read_data_i;
            mem_read_en_o = 1'b0;
        end
        //In case of a line already present in cache, output of the correct word
        else if (hit_w && read_en_i) begin
            registers_output_line = registers_output_all[read_index];
            mem_read_en_o = 1'b0;
        end
        //In case of a miss, asking the upper level memory for the line
        else if(read_en_i&&rstn_i) begin
            mem_read_en_o = 1'b1;
        end
        //Default case
        else begin
            mem_read_en_o = 1'b0;
        end
     end : mux_read_out
     
     //Data reorganization
     generate
         for (genvar k=0;k<NrWordsPerLine;k++) begin : memory_input_distribution
            assign registers_output_words[k] = registers_output_line[(k+1)*32-1:k*32]; 
         end : memory_input_distribution
     endgenerate
     
     //Read output logic
     always_comb begin : register_output_formalized
        if ((mem_read_valid_i || hit_w) && read_en_i) begin
            read_valid_o <= 1'b1;
            read_word_o <= registers_output_words[read_offset];
        end
        else read_valid_o <= 1'b0;
     end : register_output_formalized
    
endmodule : direct_cache