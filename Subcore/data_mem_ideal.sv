`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2026 01:42:40 AM
// Design Name: 
// Module Name: data_mem_ideal
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


module data_mem#(
    parameter DATA_W = 16,
    parameter ALU_COUNT = 2,
    parameter size = 256
    
)(
    input logic clk,
    input logic rst_n,
    input logic mem_rd,
    input logic mem_wr,
    input logic [DATA_W*ALU_COUNT-1:0] addr,
    input logic [DATA_W*ALU_COUNT-1:0] mem_data,
    
    output logic [DATA_W*ALU_COUNT-1:0] read_data
    );
    
    reg [31:0] rf [size-1:0];
    integer i;
    
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
             for(i=0;i<size;i=i+1)
		     rf[i] <= 32'b0;
        end else begin
            if (mem_wr)begin
                for (i = 0;i<ALU_COUNT;i=i+1)begin
                    rf[addr[i*DATA_W+:DATA_W]] <= mem_data[i*DATA_W+:DATA_W];
                end
            end
        end
    end
    
    always@(*) begin
     if(mem_rd) begin
        for(i = 0;i<ALU_COUNT;i=i+1) begin
            read_data[i*DATA_W+:DATA_W] = rf[addr[i*DATA_W+:DATA_W]];
            end
         end
    end
    
endmodule
