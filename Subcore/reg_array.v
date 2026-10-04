// reg_array : 8 x 16-bit registers (1 array per lane)

/* 2 asynchronous read ports, 1 synchronous write port, init ports
   Reserved registers: (for easier access)
        R1 : src_addr + global_thread_id
        R2 : dst_addr + global_thread_id
        R7 : global_thread_id */

module reg_array (
    input  wire clk,
    input  wire rst_n, // active low reset

    // for initialization during launch:
    input  wire        init_en,
    input  wire [15:0] init_r1,  // src_ptr + gtid
    input  wire [15:0] init_r2,  // dst_ptr + gtid
    input  wire [15:0] init_r7,  // gtid
    
    // 2 asynchronous read ports:
    input  wire [2:0]  ra_addr,
    input  wire [2:0]  rb_addr,
    output wire [15:0] ra_data,
    output wire [15:0] rb_data,

    // 1 synchronous write port:
    input  wire        we,
    input  wire [2:0]  waddr,
    input  wire [15:0] wdata
);

    reg [15:0] regs [0:7]; // 8x 16-bit registers
    integer i;

    assign ra_data = regs[ra_addr]; // asynchronous reading
    assign rb_data = regs[rb_addr];


    always @(posedge clk) begin  // synchronous writes, reset, and initialization
        if (!rst_n) begin
            // active low, clear all registers
            for (i = 0; i < 8; i = i + 1) begin
                regs[i] <= 16'h0000;
            end
        end 
        else if (init_en) begin  // give priority to initialization at warp launch
            regs[0] <= 16'h0000;
            regs[1] <= init_r1;
            regs[2] <= init_r2;
            regs[3] <= 16'h0000;
            regs[4] <= 16'h0000;
            regs[5] <= 16'h0000;
            regs[6] <= 16'h0000;
            regs[7] <= init_r7;
        end 
        else if (we) begin
            regs[waddr] <= wdata; // synchronous write
        end
    end
endmodule