//////////////////////////////////////////////////////////////////////////////////
// Engineer: Kevin GUILLOUX
// 
// Create Date: 16/01/2025
// Design Name: dram_emulation_mem_modelsim.sv
// Module Name: dram_emulation_mem_modelsim
// Project Name: RISCV_RV32i_pipeline
// Description: DRAM model. Synchonous writing, Asynchronous reading with a 10 cycles latency. 
//             The mask component as currently been removed for added simplicity
//
// Dependencies: x
//
// Current revision : 1.0
// Last modification : 16/01/2025
//
// Revision: 1.0
// Additional Comments: Modification of the DRAM I normaly use, bu adapted to be ablo to be compiled on Modelsim
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module dram_emulation_mem_modelsim #(
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
  //Signals for memorization and latency
  logic [31:0] mem[SIZE];
  logic [CYCLE_LATENCE-1:0][NB_WORDS_LINE-1:0][31:0] data_delayed_w;
  logic [CYCLE_LATENCE-1:0] propag_bit_w;
  logic [CYCLE_LATENCE-1:0][NB_WORDS_LINE-1:0][31:0] data_delayed_write_w;
  logic [CYCLE_LATENCE-1:0] propag_bit_write_w;
  
  //Adress reorg
  logic [29:0] add_w;
  assign add_w = add_i[31:2];

  //Initialisation of the memory cells
  initial begin
    if (INIT_FILE == "") $readmemh("../../../../firmware/zero.hex", mem);
    else $readmemh(INIT_FILE, mem);
  end
  
  always_comb begin : data_entry_reorg
        for (int i=0;i<NB_WORDS_LINE;i++) begin
            data_delayed_write_w[0][i] = data_i[(i*32)+:32];
        end
  end : data_entry_reorg
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
        for (int i=0;i<NB_WORDS_LINE;i++) begin
            mem[add_w+i] <= data_delayed_write_w[CYCLE_LATENCE-1][i];
        end
        write_valid_o <= 1'b1;
    end
    else write_valid_o <= 1'b0;
  end

  //Logic for the reading operation
  always_comb begin : rmem
    if (read_enable_i == 1'b1) begin
        for (int i=0;i<NB_WORDS_LINE;i++) begin
            data_delayed_w[0][i] <= mem[add_w+i];
        end
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
            for (int i=0; i<NB_WORDS_LINE; i++) begin
                data_o[(i*32)+:32] <= data_delayed_w[CYCLE_LATENCE-1][i];
            end
            read_valid_o <= 1'b1;
        end
        else begin
            data_o <= 0;
            read_valid_o <= 1'b0;
        end
  end
endmodule : dram_emulation_mem_modelsim