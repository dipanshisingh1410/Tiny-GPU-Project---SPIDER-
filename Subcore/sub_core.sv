`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2026 08:54:09 PM
// Design Name: 
// Module Name: sub_core
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


module sub_core#(
    parameter ALU_COUNT = 2,
    parameter DATA_W = 16,
    parameter NUM_OF_REG = 8,
    parameter PTR_W = 16,
    localparam ADDR_WIDTH = (NUM_OF_REG >1)?$clog2(NUM_OF_REG):1
)(  input clk,
    input rst_n,
    input hold_ip,
    input init_ip,
    input logic [PTR_W-1:0] srcptr,
    input logic [PTR_W-1:0] destptr,
    input logic [PTR_W-1:0] instrucptr,
    input logic [DATA_W-1:0] instruction,    
    input logic [15:0] gbl_warp_id,
    input logic [DATA_W*ALU_COUNT-1:0]mem_data_ip,
    input logic input_detect, // still have to figure out
    
    output logic [DATA_W*ALU_COUNT-1:0]opc,
    output logic state, //when initialised it is 0 and after finishing it becomes 1
    output logic [31:0] pc,
    output logic [DATA_W*ALU_COUNT-1:0]mem_addr,
    output logic [DATA_W*ALU_COUNT-1:0]mem_data_op,
    output logic [PTR_W-1:0] intruc_addr,
    output logic mem_rd_op,
    output logic mem_wr_op
    
    );
    
    //logic [31:0] pc = 32'b0;
    logic [31:0] next_pc = 32'b0;
    logic [PTR_W-1:0] localinstrucptr = 32'b0;
    logic [ALU_COUNT-1:0] dataflag = {ALU_COUNT{1'b0}};
    logic [4:0] op_code; 
    
    logic [DATA_W-1:0] init_r1 [ALU_COUNT-1:0]; //
    logic [DATA_W-1:0] init_r2 [ALU_COUNT-1:0]; //
    logic [DATA_W-1:0] init_rtid [ALU_COUNT-1:0]; //
    
    logic [DATA_W-1:0] ra_data [ALU_COUNT-1:0]; //
    logic [DATA_W-1:0] rb_data [ALU_COUNT-1:0]; //
    logic [ADDR_WIDTH-1:0] ra_addr; //
    logic [ADDR_WIDTH-1:0] rb_addr; //
    logic [DATA_W-1:0] w_data [ALU_COUNT-1:0]; //
    logic [ADDR_WIDTH-1:0] w_addr; //
    logic we; //
    logic [DATA_W-1:0]imm16; //
    
    logic [DATA_W-1:0] alu_a [ALU_COUNT-1:0]; //
    logic [DATA_W-1:0] alu_b [ALU_COUNT-1:0]; //
    
    logic [DATA_W-1:0] alu_out [ALU_COUNT-1:0]; //


    
    //decoder flags/control signals
     logic alu_b_sel;
     logic wb_sel;
     logic mem_rd;
     logic mem_wr;
     logic br_uncond;
     logic br_cond;
     logic is_exit;
     logic is_nop;
     
     logic hold;
     logic init;
     
     
    
    decoder my_decoder(.instr(instruction),
            .rs1_addr(ra_addr),
            .rs2_addr(rb_addr),
            .rd_addr(w_addr),
            .imm16(imm16),
            .alu_op(op_code),
            .alu_b_sel(alu_b_sel),
            .reg_we(we),
            .wb_sel(wb_sel),
            .mem_rd(mem_rd),
            .mem_wr(mem_wr),
            .br_uncond(br_uncond),
            .br_cond(br_cond),
            .is_exit(is_exit),
            .is_nop(is_nop),
            .illegal());
    
    genvar i;
    generate 
        for (i = 0; i <ALU_COUNT;i=i+1) begin : ALU_block
            alu my_alu( .a(alu_a[i])
            ,.b(alu_b[i])
            ,.alu_op(op_code)
            ,.alu_out(alu_out[i]));
            
            reg_array #(.DATA_W(DATA_W),
            .NUM_OF_REG(NUM_OF_REG)
            )my_reg
            (.clk(clk)
            ,.hold(hold)
            ,.rst_n(rst_n)
            ,.init_en(init)
            ,.init_r1(init_r1[i])
            ,.init_r2(init_r2[i])
            ,.init_rtid(init_rtid[i])
            ,.ra_addr(ra_addr)
            ,.rb_addr(rb_addr)
            ,.ra_data(ra_data[i])
            ,.rb_data(rb_data[i])
            ,.we(we)
            ,.waddr(w_addr)
            ,.wdata(w_data[i]));
        end
    endgenerate
    
    integer k;
    
    always@(*) begin //calculate hold
        hold = hold_ip;
        init = init_ip&state + !rst_n + is_exit;
    end
    
    always@(*) begin //connect the modules
        next_pc <= pc+4;
        mem_rd_op = mem_rd;
        mem_wr_op = mem_wr;
        intruc_addr = localinstrucptr + pc;
        alu_a = ra_data;
        if (alu_b_sel) begin
            alu_b = rb_data;
        end else begin
            alu_b = '{ALU_COUNT{imm16}};
        end
        if(alu_b_sel) begin
            for (k = 0;k<ALU_COUNT;k=k+1) begin
                w_data[k] = mem_data_ip[k*DATA_W+:DATA_W]; // dest data is from the memory
            end      
        end else begin
            w_data = alu_out;
            // dest data is from the alu
        end
        if(mem_wr | mem_rd ) begin
            for (k = 0;k<ALU_COUNT;k=k+1) begin
                mem_addr[k*DATA_W+:DATA_W] = alu_out[k]; // copying address from alu_out
            end 
            
        end
        if(mem_wr)begin
            for (k = 0;k<ALU_COUNT;k=k+1) begin
                mem_data_op[k*DATA_W+:DATA_W] = ra_data[k]; // copying address from alu_out
            end 
        end
        
        
    end
    
    always@(posedge clk) begin
        if(!rst_n) //reset block
        begin
            pc <= 32'b0;
            state = 1'b1;;
            for (k = 0; k < ALU_COUNT; k = k + 1) begin
                init_r1[k]   <= '0;
                init_r2[k]   <= '0;
                init_rtid[k] <= '0;
            end
            
        end else if(init) //initilization block
        begin
            pc <= 32'b0;
            state = 1'b0;
            localinstrucptr = instrucptr;
            for (k = 0;k < ALU_COUNT; k=k+1) 
            begin
                init_rtid[k] <= gbl_warp_id + k;
                init_r1[k] <= srcptr + gbl_warp_id + k;
                init_r2[k] <= destptr + gbl_warp_id + k;
            end
            
        end else 
        begin   //normal execution block
            if(is_exit) begin
                pc <= 32'b0;
                state = 1'b1;               
                for (k = 0; k < ALU_COUNT; k = k + 1) begin
                    init_r1[k]   <= '0;
                    init_r2[k]   <= '0;
                    init_rtid[k] <= '0;
                end
            end
            pc <= next_pc;
            
        end
    end    
    
    
endmodule
