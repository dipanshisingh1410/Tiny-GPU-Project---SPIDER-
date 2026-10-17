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


module alu #(
    parameter DATA_W = 16
)(
    input  wire [DATA_W-1:0] a,        // A (Ra)
    input  wire [DATA_W-1:0] b,        // B (Rb or imm)
    input  wire [4:0]        alu_op,
    output reg  [DATA_W-1:0] alu_out,
    output wire              zero,
    output wire              neg,
    output wire              carry,
    output wire              overflow
);

    localparam SHAMT_W = (DATA_W > 1) ? $clog2(DATA_W) : 1;

    reg c;

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

    wire signed [DATA_W-1:0]   a_signed   = a;
    wire signed [DATA_W-1:0]   b_signed   = b;
    wire signed [2*DATA_W-1:0] mul_signed = a_signed * b_signed;
    wire        [SHAMT_W-1:0]  shift_amt  = b[SHAMT_W-1:0];

    localparam [DATA_W-2:0] ZEROS = {(DATA_W-1){1'b0}};

    always @(*) begin
        c = 1'b0;
        case (alu_op)
            // A-type, arithmetic
            OP_ADD:   {c, alu_out} = a + b;
            OP_SUB:   {c, alu_out} = a - b;      // c = borrow
            OP_MUL:   alu_out = mul_signed[DATA_W-1:0];
            OP_MULH:  alu_out = mul_signed[2*DATA_W-1:DATA_W];
            OP_AND:   alu_out = a & b;
            OP_OR:    alu_out = a | b;
            OP_XOR:   alu_out = a ^ b;
            OP_NOT:   alu_out = ~a;
            OP_SHL:   alu_out = a << shift_amt;
            OP_SHR:   alu_out = a >> shift_amt;
            OP_SRA:   alu_out = a_signed >>> shift_amt;

            // A-type, comparisons (signed)
            OP_EQ:    alu_out = {ZEROS, (a == b)};
            OP_NEQ:   alu_out = {ZEROS, (a != b)};
            OP_LT:    alu_out = {ZEROS, (a_signed <  b_signed)};
            OP_LE:    alu_out = {ZEROS, (a_signed <= b_signed)};
            OP_GT:    alu_out = {ZEROS, (a_signed >  b_signed)};
            OP_GE:    alu_out = {ZEROS, (a_signed >= b_signed)};

            // I-type, moving
            OP_MOV:   alu_out = a;
            OP_MOVI:  alu_out = b;

            default:  alu_out = {DATA_W{1'b0}};
        endcase
    end

    wire add_ovf = (a[DATA_W-1] == b[DATA_W-1]) && (alu_out[DATA_W-1] != a[DATA_W-1]);
    wire sub_ovf = (a[DATA_W-1] != b[DATA_W-1]) && (alu_out[DATA_W-1] != a[DATA_W-1]);

    assign zero     = (alu_out == {DATA_W{1'b0}});
    assign neg      = alu_out[DATA_W-1];
    assign carry    = c;
    assign overflow = (alu_op == OP_ADD) ? add_ovf :
                      (alu_op == OP_SUB) ? sub_ovf : 1'b0;

endmodule
