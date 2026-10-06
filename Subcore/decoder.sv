`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2026 08:01:31 PM
// Design Name: 
// Module Name: decoder
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

module decoder (
    input  wire [31:0] instr,

    output wire [2:0]  rs1_addr,    // Read addr 1 (always Ra)
    output wire [2:0]  rs2_addr,    // Read addr 2 (Rb, or Rd for STR)
    output wire [2:0]  rd_addr,     // Write-back destination register (Rd)
    output wire [15:0] imm16,       // 16-bit immediate

    output reg  [4:0]  alu_op,      // Internal ALU opcode
    output reg         alu_b_sel,   // 0: alu_b = Rb, 1: alu_b = imm16
    output reg         reg_we,      // Instruction writes a register
    output reg         wb_sel,      // 0:  = ALU result, 1: = Load data
    output reg         mem_rd,      // LDR flag
    output reg         mem_wr,      // STR flag
    output reg         br_uncond,   // BRA flag
    output reg         br_cond,     // BRP flag
    output reg         is_exit,     // EXIT flag
    output reg         is_nop,      // NOP flag
    output reg         illegal      // Undefined instruction flag
);

    // opcode and opfunc's
    wire [4:0] opcode = instr[31:27];
    wire [4:0] func   = instr[26:22];

    assign rd_addr  = instr[21:19];
    assign rs1_addr = instr[18:16];
    assign imm16    = instr[15:0];

    // Read addr 2 multiplexing: 
    // the data to be stored during STR is in Rd
    // For other instructions, read addr 2 points to Rb.
    assign rs2_addr = (opcode == 5'b00100 && func == 5'b00001) ? instr[21:19] : instr[15:13];

    always @(*) begin
        // default assignments
        alu_op    = func;     
        alu_b_sel = 1'b0;
        reg_we    = 1'b0;
        wb_sel    = 1'b0;
        mem_rd    = 1'b0;
        mem_wr    = 1'b0;
        br_uncond = 1'b0;
        br_cond   = 1'b0;
        is_exit   = 1'b0;
        is_nop    = 1'b0;
        illegal   = 1'b0;

        case (opcode)
            5'b00000: begin // C-type
                case (func)
                    5'b00000: is_exit   = 1'b1;
                    5'b00001: is_nop    = 1'b1;
                    5'b00010: br_uncond = 1'b1;
                    5'b00011: br_cond   = 1'b1;
                    default:  illegal   = 1'b1;
                endcase
            end
            
            5'b00001: begin // A-type
                reg_we = 1'b1; // all A-types write to a register
                case (func) 
                    5'b00000, 5'b00001, 5'b00010, 5'b00011, 
                    5'b00100, 5'b00101, 5'b00110, 5'b00111, 
                    5'b01000, 5'b01001, 5'b01010,           
                    5'b10000, 5'b10001, 5'b10010,           
                    5'b10011, 5'b10100, 5'b10101: ;  // Valid ops, do nothing extra    
                    default: begin
                        illegal = 1'b1;
                        reg_we  = 1'b0; 
                    end
                endcase
            end

            5'b00010: begin // I-type
                reg_we = 1'b1; // All I-types write to a register
                case (func)
                    5'b00000: alu_b_sel = 1'b1; // ADDI: ALU_B = imm
                    5'b11000: alu_b_sel = 1'b0; // MOV:  ALU_B = Rb (ignored by ALU in OP_MOV anyways)
                    5'b11001: alu_b_sel = 1'b1; // MOVI: ALU_B = imm
                    default: begin
                        illegal = 1'b1;
                        reg_we  = 1'b0; 
                    end
                endcase
            end

            5'b00100: begin  // M-type
                case (func)
                    5'b00000: begin // LDR
                        mem_rd = 1'b1;
                        reg_we = 1'b1;
                        wb_sel = 1'b1;  // Write back from load data, not ALU
                    end
                    5'b00001: begin // STR
                        mem_wr = 1'b1;
                    end
                    default: illegal = 1'b1;
                endcase
            end

            default: illegal = 1'b1; 
        endcase
    end
endmodule
