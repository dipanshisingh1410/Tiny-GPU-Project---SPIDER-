`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2026 08:01:04 PM
// Design Name: 
// Module Name: ALU
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

// 16 bit ALU (1 per lane)
// executes A-type and I-type instr, alu_op == OP_FUNC.


module alu (
    input  wire [15:0] a,        // A (Ra)
    input  wire [15:0] b,        // B (Rb or imm16)
    input  wire [4:0]  alu_op,
    output reg  [15:0] alu_out
);

    reg zero,neg,carry,overflow,c;
    // A-type, arithmetic
    localparam OP_ADD   = 5'b00000;
    localparam OP_SUB   = 5'b00001;
    localparam OP_MUL   = 5'b00010;
    localparam OP_MULH  = 5'b00011;
    localparam OP_AND   = 5'b00100;
    localparam OP_OR    = 5'b00101;
    localparam OP_XOR   = 5'b00110;
    localparam OP_NOT   = 5'b00111;
    localparam OP_SHL   = 5'b01000;
    localparam OP_SHR   = 5'b01001;
    localparam OP_SRA   = 5'b01010;

    // A-type, comparisons (signed)
    localparam OP_EQ    = 5'b10000;
    localparam OP_NEQ   = 5'b10001;
    localparam OP_LT    = 5'b10010;
    localparam OP_LE    = 5'b10011;
    localparam OP_GT    = 5'b10100;
    localparam OP_GE    = 5'b10101;

    // I-type, moving
    localparam OP_MOV   = 5'b11000;   
    localparam OP_MOVI  = 5'b11001;   

    wire signed [15:0] a_signed   = a;
    wire signed [15:0] b_signed   = b;
    wire signed [31:0] mul_signed = a_signed * b_signed;   
    wire        [3:0]  shift_amt  = b[3:0];    

    always @(*) begin
    c=1'b0;
        case (alu_op)
        
            // A-type, arithmetic
            OP_ADD:   {c,alu_out} = a + b;
            OP_SUB:   {c,alu_out} = a - b;
            OP_MUL:   alu_out = mul_signed[15:0];
            OP_MULH:  alu_out = mul_signed[31:16];
            OP_AND:   alu_out = a & b;
            OP_OR:    alu_out = a | b;
            OP_XOR:   alu_out = a ^ b;
            OP_NOT:   alu_out = ~a;
            OP_SHL:   alu_out = a << shift_amt;
            OP_SHR:   alu_out = a >> shift_amt;
            OP_SRA:   alu_out = a_signed >>> shift_amt;
            
            // A-type, comparisons (signed)
            OP_EQ:    alu_out = {15'b0, (a == b)};
            OP_NEQ:   alu_out = {15'b0, (a != b)};
            OP_LT:    alu_out = {15'b0, (a_signed <  b_signed)};
            OP_LE:    alu_out = {15'b0, (a_signed <= b_signed)};
            OP_GT:    alu_out = {15'b0, (a_signed >  b_signed)};
            OP_GE:    alu_out = {15'b0, (a_signed >= b_signed)};

            // I-type, moving
            OP_MOV:   alu_out = a;  // Ra
            OP_MOVI:  alu_out = b;  // imm16

            default:  alu_out = 16'h0000;
        
        endcase
    end
    
    assign zero     = (alu_out == 16'b0);
    assign neg      = alu_out[15];                     
    assign carry    = c;
    assign overflow = (alu_op == 4'b0000) ? (a[15] == b[15]) && (alu_out[15] != a[15]) :
                  (alu_op == 4'b1000) ? (alu_out[15] != b[15]) && (alu_out[15] != a[15]) :
                  1'b0;
endmodule
