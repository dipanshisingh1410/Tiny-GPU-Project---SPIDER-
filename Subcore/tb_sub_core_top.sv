`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/15/2026 06:27:23 PM
// Design Name: 
// Module Name: tb_sub_core_top
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


module tb_sub_core_top;

    localparam int ALU_COUNT  = 2;
    localparam int DATA_W     = 32;
    localparam int NUM_OF_REG = 8;
    localparam int PTR_W      = 32;
    
       
    logic             clk;
    logic             rst_n;
    logic             hold_ip;
    logic             init_ip;
    logic [PTR_W-1:0] srcptr;
    logic [PTR_W-1:0] destptr;
    logic [PTR_W-1:0] instrucptr;
    logic [31:0]      gbl_warp_id;
    
    initial clk = 1'b1;
    always #(20) clk = ~clk;
    
    sub_core_top dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .hold_ip     (hold_ip),
        .init_ip     (init_ip),
        .srcptr      (srcptr),
        .destptr     (destptr),
        .instrucptr  (instrucptr),
        .gbl_warp_id (gbl_warp_id)
    );
    
    
    // Launch a warp: set pointers, pulse init_ip for one cycle.
    // Note: sub_core only accepts init_ip while state == 1 (idle).
    task automatic launch_warp(
        input logic [PTR_W-1:0] src,
        input logic [PTR_W-1:0] dst,
        input logic [PTR_W-1:0] iptr,
        input logic [31:0]      warp_id
    );
        begin
            @(negedge clk);
            srcptr      = src;
            destptr     = dst;
            instrucptr  = iptr;
            gbl_warp_id = warp_id;
            init_ip     = 1'b1;
            @(negedge clk);
            init_ip     = 1'b0;
        end
    endtask
    
        initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
        hold_ip = 0;
        launch_warp(16'h0080, 16'h0010, 16'h0000, 16'd0);
        #500
        launch_warp(16'h0080, 16'h0010, 16'h0000, 16'd2);
        end
        
    
endmodule
