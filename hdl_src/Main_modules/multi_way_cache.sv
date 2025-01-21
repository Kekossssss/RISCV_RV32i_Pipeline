//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 20/12/2024
// Design Name: multi_way_cache.sv
// Module Name: multi_way_cache
// Project Name: RISCV_RV32i_pipeline
// Description: Direct cache module, represented with registers,read and write are synchronous
// 
// Dependencies: x
// 
// Current revision : 1.2
// Last modification : 22/12/2024
//
// Revision: 1.0
// Additional Comments: Completed and tested. Fully working.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module multi_way_cache #(
    parameter ByteOffsetBits = 5,
    parameter IndexBits = 5,
    parameter TagBits = 22,
    parameter NB_WAYS = 2,
    localparam BITS_WAYS = $clog2(NB_WAYS),
    localparam NrWordsPerLine = (2**ByteOffsetBits)/4,
    localparam NrLines = 2**IndexBits,
    localparam LineSize = 32 * NrWordsPerLine
) (
    // General purpose input ports
    input logic clk_i,
    input logic rstn_i,
    input logic [31:0] addr_i,

    // Read port
    input logic read_en_i,
    output logic read_valid_o,
    output logic [31:0] read_word_o,

    // Memory
    output logic [31:0] mem_addr_o,

    // Memory read port
    output logic mem_read_en_o,
    input logic mem_read_valid_i,
    input logic [LineSize-1:0] mem_read_data_i
);
    //---------------------------------------------------------------------------------------//
	//Functions
	//---------------------------------------------------------------------------------------//
    //Function to initialise the values of the LRU cache
    function bit [NB_WAYS*BITS_WAYS-1:0] int_lru;
        for (int i=0;i<NB_WAYS;i++) begin
            int_lru[(i*BITS_WAYS)+:BITS_WAYS] = i;
        end
    endfunction 
    //---------------------------------------------------------------------------------------//
	//Internal connections declaration
	//---------------------------------------------------------------------------------------//
    //Address segmentation
    logic [ByteOffsetBits-1:0] read_offset;
    logic [ByteOffsetBits-1:0] read_offset_zero = 0;
    logic [IndexBits-1:0] read_index;
    logic [TagBits-1:0] read_tag;
    
    //Cache elements
    logic cache_line_validity[NrLines-1:0][NB_WAYS-1:0];
    logic [TagBits-1:0] cache_tags[NrLines-1:0][NB_WAYS-1:0];
    logic [LineSize-1:0] cache_words[NrLines-1:0][NB_WAYS-1:0];
    logic [NB_WAYS*BITS_WAYS-1:0] cache_LRU[NrLines-1:0];            //Signal used in order to choose which way to write the new line into
    
    //Register Outputs
    logic [NrLines-1:0][TagBits-1:0] registers_output_lines_tags;
    logic [NrLines-1:0][LineSize-1:0] registers_output_all;
    logic [LineSize-1:0] registers_output_line;
    logic [NrWordsPerLine-1:0][31:0] registers_output_words;
    
    //Internal logic connections
    logic [NB_WAYS-1:0] hit_w;
    logic [BITS_WAYS-1:0] hit_index_w;
    //---------------------------------------------------------------------------------------//
	//"Pre-memory" logic of the module
	//---------------------------------------------------------------------------------------//
    //Generation of the hit signal, one per way
    generate
        for (genvar h_l=0;h_l<NB_WAYS;h_l++) begin : hit_gen
            always_comb begin : hit_or_miss
                if (cache_tags[read_index][h_l]==read_tag && read_en_i && cache_line_validity[read_index][h_l]) begin
                    hit_w[h_l] = 1'b1;
                    hit_index_w = h_l;
                end
                else hit_w[h_l] = 1'b0; 
            end : hit_or_miss
        end : hit_gen
    endgenerate
    
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
            for (genvar j=0;j<NB_WAYS;j++) begin : registers_cache_ways
                always_ff @(posedge clk_i or negedge rstn_i) begin : write_cache
                    ////Reset
                    if(rstn_i==1'b0) begin
                        cache_line_validity[i][j] <= 1'b0;
                        cache_tags[i][j] <= 0;
                        cache_words[i][j] <= 0;
                    end
                    ////Update of a way of the cache, with a data coming from a higher level memory
                    else if (mem_read_valid_i && (read_index==i) && (cache_LRU[i][0+:BITS_WAYS]==j)) begin
                        cache_line_validity[i][j] <= 1'b1;
                        cache_tags[i][j] <= read_tag;
                        cache_words[i][j] <= mem_read_data_i;
                        cache_LRU[i] <= {cache_LRU[i][0+:BITS_WAYS],cache_LRU[i][BITS_WAYS+:(NB_WAYS-1)*BITS_WAYS]};
                    end
                    ////Modification of the LRU value after a succesfull read in a way
                    else if ((hit_w!=0) && (cache_LRU[i][(j*BITS_WAYS)+:BITS_WAYS]==hit_index_w) && read_en_i && (i==read_index)) begin
                        if (j==0) cache_LRU[i] <= {cache_LRU[i][0+:BITS_WAYS],cache_LRU[i][BITS_WAYS+:(NB_WAYS-1)*BITS_WAYS]};
                        else if (j<(NB_WAYS-1)) cache_LRU[i] <= {cache_LRU[i][(j*BITS_WAYS)+:BITS_WAYS],cache_LRU[i][((j+1)*BITS_WAYS)+:(NB_WAYS-j-1)*BITS_WAYS],cache_LRU[i][0+:j*BITS_WAYS]};
                    end
                end : write_cache
                ////Modification of the output based on the hit signal
                always_comb begin : read_cache
                    if (hit_w[j]) begin
                        registers_output_lines_tags[i] <= cache_tags[i][j];
                        registers_output_all[i] <= cache_words[i][j];
                    end
                end : read_cache
            end : registers_cache_ways
            ////Initialisation of the LRU during a reset
            always_ff @(posedge clk_i or negedge rstn_i) begin : LRU_cache
                if(rstn_i==1'b0) begin
                    cache_LRU[i] <= int_lru();
                end
            end : LRU_cache
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
     
     //Read output with a cycle of latency
     always_comb begin : register_output_latency 
        if ((mem_read_valid_i || hit_w) && read_en_i) begin
            read_valid_o <= 1'b1;
            read_word_o <= registers_output_words[read_offset];
        end
        else read_valid_o <= 1'b0;
     end : register_output_latency
endmodule : multi_way_cache
