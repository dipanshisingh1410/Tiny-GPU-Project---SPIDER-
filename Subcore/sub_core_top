`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2026 03:41:49 AM
// Design Name: 
// Module Name: sub_core_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//this is SM but for testing purposes


module sub_core_top #(
    // ---- Instance parameters ----
    localparam int ALU_COUNT  = 2,
    localparam int DATA_W     = 16,
    localparam int NUM_OF_REG = 8,
    localparam int PTR_W      = 16
)(
    input clk,
    input rst_n,
    input hold_ip,
    input init_ip,
    input logic [PTR_W-1:0] srcptr,
    input logic [PTR_W-1:0] destptr,
    input logic [PTR_W-1:0] instrucptr,
    input logic [15:0] gbl_warp_id

    );
    
    
    
    // ---- Inputs to sub_core ----
    logic                        input_detect;
    logic [DATA_W-1:0]           instruction;
    logic [DATA_W*ALU_COUNT-1:0] mem_data_ip;
    
    // ---- Outputs from sub_core ----
    logic [DATA_W*ALU_COUNT-1:0] opc, mem_addr, mem_data_op;
    logic                        state;
    logic [31:0]                 pc;
    logic [PTR_W-1:0]            intruc_addr;
    logic                        mem_rd_op, mem_wr_op;
    
    sub_core #(
        .ALU_COUNT  (ALU_COUNT),
        .DATA_W     (DATA_W),
        .NUM_OF_REG (NUM_OF_REG),
        .PTR_W      (PTR_W)
        // ADDR_WIDTH intentionally not overridden; it is derived
    ) my_sub_core (
        .clk          (clk),
        .rst_n        (rst_n),
        .hold_ip      (hold_ip),
        .init_ip      (init_ip),
        .srcptr       (srcptr),
        .destptr      (destptr),
        .instrucptr   (instrucptr),
        .instruction  (instruction),
        .gbl_warp_id  (gbl_warp_id),
        .mem_data_ip  (mem_data_ip),
        .input_detect (input_detect),
    
        .opc          (opc),
        .state        (state),
        .pc           (pc),
        .mem_addr     (mem_addr),
        .mem_data_op  (mem_data_op),
        .intruc_addr  (intruc_addr),
        .mem_rd_op    (mem_rd_op),
        .mem_wr_op    (mem_wr_op)
    );
    
    
    Instruction_mem #(
    .SIZE (256)
    )my_instruc_mem(
    .pc(pc),
    .instruction(instruction)
    );
    
    data_mem#(
        .DATA_W     (DATA_W),
        .ALU_COUNT (ALU_COUNT),
        .size       (256)
    )   my_data_mem(
        .clk(clk),
        .rst_n(rst_n),
        .mem_rd(mem_rd_op),
        .mem_wr(mem_wr_op),
        .addr(mem_addr),
        .mem_data(mem_data_op),
        .read_data(mem_data_ip)
    );
    
endmodule
