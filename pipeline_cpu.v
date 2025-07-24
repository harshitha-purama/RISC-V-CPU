`timescale 1ns/1ps

module pipeline_cpu(
    input wire clk,
    input wire reset,
    input wire [7:0] switches,
    output wire [7:0] leds
);

    // PC register
    reg [31:0] pc;

    // Pipeline registers
    reg [31:0] IF_ID_instr, IF_ID_pcplus4;
    reg [31:0] ID_EX_pcplus4, ID_EX_regdata1, ID_EX_regdata2, ID_EX_imm;
    reg [4:0]  ID_EX_rs1, ID_EX_rs2, ID_EX_rd;
    reg [3:0]  ID_EX_alu_control;
    reg        ID_EX_regwrite, ID_EX_memread, ID_EX_memwrite, ID_EX_memtoreg, ID_EX_alusrc;
    
    reg [31:0] EX_MEM_alu_result, EX_MEM_regdata2;
    reg [4:0]  EX_MEM_rd;
    reg        EX_MEM_regwrite, EX_MEM_memread, EX_MEM_memwrite, EX_MEM_memtoreg;

    reg [31:0] MEM_WB_memdata, MEM_WB_alu_result;
    reg [4:0]  MEM_WB_rd;
    reg        MEM_WB_regwrite, MEM_WB_memtoreg;

    // Wires for instruction fetch
    wire [31:0] instr;
    
    instr_mem imem (
        .addr(pc),
        .instr(instr)
    );
wire [31:0] reg_read_data1, reg_read_data2;
reg  [31:0] reg_write_data;    // reg because assigned in always block
wire [4:0]  reg_write_addr = MEM_WB_rd;
wire        reg_write_en = MEM_WB_regwrite;

    regfile regs (
        .clk(clk),
        .we3(reg_write_en),
        .ra1(IF_ID_instr[19:15]),
        .ra2(IF_ID_instr[24:20]),
        .wa3(reg_write_addr),
        .wd3(reg_write_data),
        .rd1(reg_read_data1),
        .rd2(reg_read_data2)
    );

    // Immediate Generator
    reg [31:0] imm_ext;
    always @(*) begin
        case(instr[6:0])
            7'b0010011, 7'b0000011: imm_ext = {{20{instr[31]}}, instr[31:20]}; // I-type
            7'b0100011: imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-type
            7'b1100011: imm_ext = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type
            default: imm_ext = 32'b0;
        endcase
    end

    // Control signals (simplified)
    reg regwrite, memread, memwrite, memtoreg, alusrc;
    reg [3:0] alucontrol;

    always @(*) begin
        // Defaults
        regwrite = 0;
        memread = 0;
        memwrite = 0;
        memtoreg = 0;
        alusrc = 0;
        alucontrol = 4'b0000;

        case(instr[6:0])
            7'b0010011: begin  // I-type ALU (addi etc.)
                regwrite = 1;
                alusrc = 1;
                alucontrol = 4'b0010; // ADD (simplified)
            end
            7'b0110011: begin // R-type
                regwrite = 1;
                alusrc = 0;
                case({instr[31:25], instr[14:12]})
                    10'b0000000000: alucontrol = 4'b0010; // ADD
                    10'b0100000000: alucontrol = 4'b0110; // SUB
                    10'b0000000111: alucontrol = 4'b0000; // AND
                    10'b0000000110: alucontrol = 4'b0001; // OR
                    default: alucontrol = 4'b0010;
                endcase
            end
            7'b0000011: begin // Load
                regwrite = 1;
                memread = 1;
                alusrc = 1;
                alucontrol = 4'b0010; // ADD (for addr calc)
                memtoreg = 1;
            end
            7'b0100011: begin // Store
                memwrite = 1;
                alusrc = 1;
                alucontrol = 4'b0010; // ADD
            end
            default: begin
                regwrite = 0;
                memread = 0;
                memwrite = 0;
                memtoreg = 0;
                alusrc = 0;
                alucontrol = 4'b0000;
            end
        endcase
    end

    // EX stage ALU inputs
    wire [31:0] alu_in2 = (alusrc) ? ID_EX_imm : ID_EX_regdata2;

    wire [31:0] alu_result;
    wire alu_zero;

    alu alu0(
        .a(ID_EX_regdata1),
        .b(alu_in2),
        .alu_control(ID_EX_alu_control),
        .alu_result(alu_result),
        .zero(alu_zero)
    );

    // Data Memory with Memory Mapped I/O
    wire [31:0] mem_readdata;
    wire [7:0]  led_output;

    data_mem dmem(
        .clk(clk),
        .memwrite(EX_MEM_memwrite),
        .memread(EX_MEM_memread),
        .addr(EX_MEM_alu_result),
        .writedata(EX_MEM_regdata2),
        .readdata(mem_readdata),
        .led_output(led_output),
        .switch_input(switches)
    );

    assign leds = led_output;

    // WB stage
    always @(*) begin
        if(MEM_WB_memtoreg)
            reg_write_data = MEM_WB_memdata;
        else
            reg_write_data = MEM_WB_alu_result;
    end

    // PC update (Simple, no branch support here for brevity)
    always @(posedge clk or posedge reset) begin
        if(reset)
            pc <= 0;
        else
            pc <= pc + 4;
    end

    // Pipeline registers update
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            // Clear pipeline registers
            IF_ID_instr <= 0;
            IF_ID_pcplus4 <= 0;
            ID_EX_pcplus4 <= 0;
            ID_EX_regdata1 <= 0;
            ID_EX_regdata2 <= 0;
            ID_EX_imm <= 0;
            ID_EX_rs1 <= 0;
            ID_EX_rs2 <= 0;
            ID_EX_rd <= 0;
            ID_EX_alu_control <= 0;
            ID_EX_regwrite <= 0;
            ID_EX_memread <= 0;
            ID_EX_memwrite <= 0;
            ID_EX_memtoreg <= 0;
            ID_EX_alusrc <= 0;
            EX_MEM_alu_result <= 0;
            EX_MEM_regdata2 <= 0;
            EX_MEM_rd <= 0;
            EX_MEM_regwrite <= 0;
            EX_MEM_memread <= 0;
            EX_MEM_memwrite <= 0;
            EX_MEM_memtoreg <= 0;
            MEM_WB_memdata <= 0;
            MEM_WB_alu_result <= 0;
            MEM_WB_rd <= 0;
            MEM_WB_regwrite <= 0;
            MEM_WB_memtoreg <= 0;
        end else begin
            // IF/ID
            IF_ID_instr <= instr;
            IF_ID_pcplus4 <= pc + 4;

            // ID/EX
            ID_EX_pcplus4 <= IF_ID_pcplus4;
            ID_EX_regdata1 <= reg_read_data1;
            ID_EX_regdata2 <= reg_read_data2;
            ID_EX_imm <= imm_ext;
            ID_EX_rs1 <= IF_ID_instr[19:15];
            ID_EX_rs2 <= IF_ID_instr[24:20];
            ID_EX_rd <= IF_ID_instr[11:7];
            ID_EX_alu_control <= alucontrol;
            ID_EX_regwrite <= regwrite;
            ID_EX_memread <= memread;
            ID_EX_memwrite <= memwrite;
            ID_EX_memtoreg <= memtoreg;
            ID_EX_alusrc <= alusrc;

            // EX/MEM
            EX_MEM_alu_result <= alu_result;
            EX_MEM_regdata2 <= ID_EX_regdata2;
            EX_MEM_rd <= ID_EX_rd;
            EX_MEM_regwrite <= ID_EX_regwrite;
            EX_MEM_memread <= ID_EX_memread;
            EX_MEM_memwrite <= ID_EX_memwrite;
            EX_MEM_memtoreg <= ID_EX_memtoreg;

            // MEM/WB
            MEM_WB_memdata <= mem_readdata;
            MEM_WB_alu_result <= EX_MEM_alu_result;
            MEM_WB_rd <= EX_MEM_rd;
            MEM_WB_regwrite <= EX_MEM_regwrite;
            MEM_WB_memtoreg <= EX_MEM_memtoreg;
 pc <= pc + 4;

        // Print register write-back activity
        if (MEM_WB_regwrite && MEM_WB_rd != 0) begin
            $display("Cycle %0t: Write Reg x%0d = 0x%08x (%0d)", $time, MEM_WB_rd, reg_write_data, reg_write_data);
        end
    end
end

