//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 14/12/2024
// Design Name: dram_emulation_mem.sv
// Module Name: dram_emulation_mem
// Project Name: RISCV_RV32i_pipeline
// Description: DRAM model. Synchonous writing, Asynchronous reading with a 10 cycles latency. 
//             The mask component as currently been removed for added simplicity
//
// Dependencies: x
//
// Current revision : 1.1
// Last modification : 20/12/2024
//
// Revision: 1.1
// Additional Comments: Added support for writes with latency.
//
// Revision: 1.0
// Additional Comments: Tested and working with multiple caches (direct and multiway). Not currently succesfully tested
//                     with a write enabled cache.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module dram_emulation_mem #(
    parameter ByteOffsetBits = 5,
    parameter SIZE = 4096,    //In bytes
    parameter INIT_FILE = "",
    parameter CYCLE_LATENCE = 10,
    localparam NB_WORDS_LINE = (2**ByteOffsetBits)/4,
    localparam LINE_SIZE = 32 * NB_WORDS_LINE,
    localparam ADDR_LEN = $clog2(SIZE)
) (
    //General purpose ports
    input logic clk_i,
    input logic [31:0] add_i,
    //Write ports
    input logic write_enable_i,
    input logic [LINE_SIZE-1:0] data_i,
    output logic write_valid_o,
    //Read ports
    input logic read_enable_i,
    output logic read_valid_o,
    output logic [LINE_SIZE-1:0] data_o
);
  //Adress for the memory by lines
  logic [31-ByteOffsetBits+1:0] add_w;
  assign add_w = add_i[31:ByteOffsetBits];

  //Signals for memorization and latency
  logic [31:0] mem[SIZE];
  logic [LINE_SIZE-1:0] mem_line[SIZE/NB_WORDS_LINE];
  logic [CYCLE_LATENCE-1:0][LINE_SIZE-1:0] data_delayed_w;
  logic [CYCLE_LATENCE-1:0] propag_bit_w;
  logic [CYCLE_LATENCE-1:0][LINE_SIZE-1:0] data_delayed_write_w;
  logic [CYCLE_LATENCE-1:0] propag_bit_write_w;

  //Initialisation of the memory cells
  initial begin
    if (INIT_FILE == "") $readmemh("../../../../firmware/zero.hex", mem);
    else $readmemh(INIT_FILE, mem);
    for (int lines=0;lines<SIZE/NB_WORDS_LINE;lines++) begin 
        for (int column=0; column<NB_WORDS_LINE; column++) begin
            mem_line[lines][(column*32)+:32] = mem[NB_WORDS_LINE*lines+column];
        end
    end
  end
  
  assign data_delayed_write_w[0] = data_i;
  assign propag_bit_write_w[0] = write_enable_i;

  //Register for the writing in memory
  generate
    for (genvar wr=0;wr<CYCLE_LATENCE-1;wr++) begin : REGISTER_LATENCE_WRITE
        always_ff @(posedge clk_i) begin
            if (write_enable_i && propag_bit_write_w[wr]) begin
                data_delayed_write_w[wr+1] <= data_delayed_write_w[wr];
                propag_bit_write_w[wr+1] <= propag_bit_write_w[wr];
            end
            else begin
                data_delayed_write_w[wr+1] <= 0;
                propag_bit_write_w[wr+1] <= 1'b0;
            end
        end
    end : REGISTER_LATENCE_WRITE
  endgenerate
  
  always_ff @(posedge clk_i) begin : wmem
    if (write_enable_i && propag_bit_write_w[CYCLE_LATENCE-1]) begin
        mem_line[add_w] <= data_delayed_write_w[CYCLE_LATENCE-1];
        write_valid_o <= 1'b1;
    end
    else write_valid_o <= 1'b0;
  end

  //Logic for the reading operation
  always_comb begin : rmem
    if (read_enable_i == 1'b1) begin
        data_delayed_w[0] = mem_line[add_w];
        propag_bit_w[0] = 1'b1;
    end
    else begin
        data_delayed_w[0] = 0;
        propag_bit_w[0] = 1'b0;
    end
  end
  
  //Propagation registers aimed at simulating the read latency of the memory
  generate
    for (genvar i=0;i<CYCLE_LATENCE-1;i++) begin : REGISTER_LATENCE_READ
        always_ff @(posedge clk_i) begin
            if (read_enable_i && propag_bit_w[i]) begin
                data_delayed_w[i+1] <= data_delayed_w[i];
                propag_bit_w[i+1] <= propag_bit_w[i];
            end
            else begin
                data_delayed_w[i+1] <= 0;
                propag_bit_w[i+1] <= 1'b0;
            end
        end
    end : REGISTER_LATENCE_READ
  endgenerate 
  
  //Final propagation register for the simulated latency, affects the outputs
  always_ff @(posedge clk_i) begin
        if (read_enable_i && propag_bit_w[CYCLE_LATENCE-1]) begin
            data_o <= data_delayed_w[CYCLE_LATENCE-1];
            read_valid_o <= 1'b1;
        end
        else begin
            data_o <= 0;
            read_valid_o <= 1'b0;
        end
  end
endmodule : dram_emulation_mem