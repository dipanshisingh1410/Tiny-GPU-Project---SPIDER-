`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/05/2026 03:39:48 AM
// Design Name: 
// Module Name: Instruction_mem
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


module Instruction_mem #(parameter SIZE = 256)(
input [31:0] pc,
output [31:0] instruction
);

reg [31:0] mem [SIZE-1:0];

	initial $readmemh("program.hex", mem);

 	assign instruction = (pc[31:2] < SIZE) ? mem[pc >> 2] : 32'h400000;

endmodule 
