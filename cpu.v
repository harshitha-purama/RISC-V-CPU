`timescale 1ns/1ps
module cpu(
    input  wire        clk,
    input  wire        reset
);

    reg [31:0] pc;

    wire [31:0] instr;

    // Instruction Memory (32 instructions, you can expand)
    reg [31:0] instr_mem[0:31];
	integer i;
    initial begin
        // Initialize instruction memory with a small test program
        // Example: calculate factorial(5)
        // addi x1, x0, 5   # x1 = 5
        instr_mem[0] = 32'h00500093; // addi x1,x0,5
        // addi x2, x0, 1   # x2 = 1 (result)
        instr_mem[1] = 32'h00100113;
        // addi x3, x0, 1   # x3 = 1 (counter)
        instr_mem[2] = 32'h00100193;
        // Loop:
        // mul x2, x2, x3   # x2 *= x3 (note: RV32I doesn't have mul, so let's do add for demo)
        // add x2, x2, x3
        instr_mem[3] = 32'h003101b3;
        // addi x3, x3, 1   # x3++
        instr_mem[4] = 32'h00118193;
        // blt x3, x1, Loop (pc-relative branch)
        instr_mem[5] = 32'hfe519ae3;
        // End: nop (addi x0, x0, 0)
        instr_mem[6] = 32'h00000013;
        // Fill rest with nop
        for(i=7; i<32; i=i+1) instr_mem[i] = 32'h00000013;
    end

    // Signals for instruction decode
    wire [6:0] opcode  = instr[6:0];
    wire [4:0] rd      = instr[11:7];
    wire [2:0] funct3  = instr[14:12];
    wire [4:0] rs1     = instr[19:15];
    wire [4:0] rs2     = instr[24:20];
    wire [6:0] funct7  = instr[31:25];

    // Immediate generation - support I-type and B-type for example
    reg [31:0] imm_i;
    reg [31:0] imm_b;

    always @(*) begin
        imm_i = {{20{instr[31]}}, instr[31:20]};
        imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    end

    // Register File
    wire [31:0] reg_rdata1, reg_rdata2;
    reg        reg_we;
    reg [4:0]  reg_waddr;
    reg [31:0] reg_wdata;

    regfile registers(
        .clk(clk),
        .we3(reg_we),
        .ra1(rs1),
        .ra2(rs2),
        .wa3(reg_waddr),
        .wd3(reg_wdata),
        .rd1(reg_rdata1),
        .rd2(reg_rdata2)
    );

    // ALU Control
    reg [3:0] alu_ctrl;
    reg [31:0] alu_in2;
    wire [31:0] alu_result;
    wire alu_zero;

    alu alu0(.a(reg_rdata1), .b(alu_in2), .alu_control(alu_ctrl), .alu_result(alu_result), .zero(alu_zero));

    // Control Signals
    reg branch;
    reg memread;
    reg memwrite;
    reg memtoreg;
    reg alusrc;          // 0 = reg, 1= imm
    reg [1:0] aluop;

    // Simple Control Unit (Partial implementation for subset)
    always @(*) begin
        // Default
        branch = 0;
        memread = 0;
        memwrite = 0;
        memtoreg = 0;
        alusrc = 0;
        reg_we = 0;
        alu_ctrl = 4'b0000;
        reg_waddr = rd;
        reg_wdata = 0;
        alu_in2 = reg_rdata2;

        case(opcode)
            7'b0010011: begin // I-type ALU immediate (addi, slti, etc)
                reg_we = 1;
                alusrc = 1;
                alu_in2 = imm_i;
                case(funct3)
                    3'b000: alu_ctrl = 4'b0010; // ADDI
                    3'b010: alu_ctrl = 4'b0111; // SLTI
                    3'b111: alu_ctrl = 4'b0000; // ANDI
                    3'b110: alu_ctrl = 4'b0001; // ORI
                    default: alu_ctrl = 4'b0010;
                endcase
                reg_wdata = alu_result;
            end
            7'b0110011: begin // R-type (ADD, SUB, AND, OR, SLT)
                reg_we = 1;
                alusrc = 0;
                alu_in2 = reg_rdata2;
                case({funct7, funct3})
                    10'b0000000000: alu_ctrl = 4'b0010; // ADD
                    10'b0100000000: alu_ctrl = 4'b0110; // SUB
                    10'b0000000111: alu_ctrl = 4'b0000; // AND
                    10'b0000000110: alu_ctrl = 4'b0001; // OR
                    10'b0000000010: alu_ctrl = 4'b0111; // SLT
                    default: alu_ctrl = 4'b0010;
                endcase
                reg_wdata = alu_result;
            end
            7'b1100011: begin // Branch (BEQ, BNE, BLT, BGE)
                branch = 1;
                alusrc = 0;
                alu_in2 = reg_rdata2;
                case(funct3)
                    3'b000: alu_ctrl = 4'b0110; // BEQ = SUB + zero detect
                    3'b001: alu_ctrl = 4'b0110; // BNE
                    3'b100: alu_ctrl = 4'b0111; // BLT
                    3'b101: alu_ctrl = 4'b0111; // BGE
                    default: alu_ctrl = 4'b0110;
                endcase
            end
            7'b0000011: begin // Load (LW)
                reg_we = 1;
                memread = 1;
                alusrc = 1;
                alu_in2 = imm_i;
                alu_ctrl = 4'b0010;  // ADD for address calc
                memtoreg = 1;
            end
            7'b0100011: begin // Store (SW)
                memwrite = 1;
                alusrc = 1;
                alu_in2 = imm_i;
                alu_ctrl = 4'b0010; // ADD for address calc
            end
            default: begin
                reg_we = 0;
                alusrc = 0;
                alu_ctrl = 4'b0010;
                reg_wdata = 0;
            end
        endcase
    end

    // Data Memory Interface
    wire [31:0] mem_rdata;
    data_mem data_memory(
        .clk(clk),
        .memwrite(memwrite),
        .memread(memread),
        .addr(alu_result),
        .writedata(reg_rdata2),
        .readdata(mem_rdata)
    );

    // Writeback Mux
    always @(*) begin
        if(memtoreg)
            reg_wdata = mem_rdata;
        else
            reg_wdata = alu_result;
    end

    // PC Update logic
    reg pc_src;
    wire branch_taken;

    // Branch conditions
    // BEQ: zero==1, BNE: zero==0, BLT: reg_rdata1 < reg_rdata2
    assign branch_taken = (branch) && (
        (funct3 == 3'b000 && alu_zero) ||    // BEQ
        (funct3 == 3'b001 && !alu_zero) ||   // BNE
        (funct3 == 3'b100 && (reg_rdata1 < reg_rdata2)) ||  // BLT
        (funct3 == 3'b101 && (reg_rdata1 >= reg_rdata2))    // BGE
    );

    always @(posedge clk or posedge reset) begin
        if(reset)
            pc <= 0;
        else if(branch_taken)
            pc <= pc + imm_b;
        else
            pc <= pc + 4;
    end

    // Instruction fetch
    assign instr = instr_mem[pc[6:2]];

endmodule

