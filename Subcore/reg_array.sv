`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2026 08:01:58 PM
// Design Name: 
// Module Name: reg_array
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


// reg_array : 8 x 16-bit registers (1 array per lane)

/* 2 asynchronous read ports, 1 synchronous write port, init ports
   Reserved registers: (for easier access)
        R1 : src_addr + global_thread_id
        R2 : dst_addr + global_thread_id
        R7 : global_thread_id */

module reg_array #(
    parameter DATA_W = 16,
    parameter NUM_OF_REG = 8,
    parameter ADDR_WIDTH = (NUM_OF_REG >1)?$clog2(NUM_OF_REG):1
)(
    input  wire clk,
    input  wire rst_n, // active low reset
    input  wire hold,

    // for initialization during launch:
    input  wire  init_en,
    input  wire [DATA_W-1:0] init_r1,  // src_ptr + gtid
    input  wire [DATA_W-1:0] init_r2,  // dst_ptr + gtid
    input  wire [DATA_W-1:0] init_rtid,  // gtid
    
    // 2 asynchronous read ports:
    input  wire [ADDR_WIDTH-1:0]  ra_addr,
    input  wire [ADDR_WIDTH-1:0]  rb_addr,
    output reg [DATA_W-1:0] ra_data,
    output reg [DATA_W-1:0] rb_data,

    // 1 synchronous write port:
    input  wire        we,
    input  wire [ADDR_WIDTH-1:0]  waddr,
    input  wire [15:0] wdata
);



    reg [DATA_W-1:0] regs [NUM_OF_REG-1:0]; // 8x 16-bit registers
    integer i;
    
    always @(*)
    begin
        if(!hold)begin
            ra_data <= regs[ra_addr];
            rb_data <= regs[rb_addr];
        end
    end


    always @(posedge clk) begin  // synchronous writes, reset, and initialization
        if (!rst_n) begin
            // active low, clear all registers
            for (i = 0; i < NUM_OF_REG; i = i + 1) begin
                regs[i] <= {DATA_W{1'b0}};
            end
        end 
        else if (init_en & !hold) begin  // give priority to initialization at warp launch
            for (i = 0; i < NUM_OF_REG; i = i + 1)
                regs[i] <= {DATA_W{1'b0}};
            regs[1]  <= init_r1;   // later NBA wins over the loop's zero
            regs[2]  <= init_r2;
            regs[NUM_OF_REG-1] <= init_rtid;
        end 
        else if (we&!hold) begin
            regs[waddr] <= wdata; // synchronous write
        end
    end
endmodule
