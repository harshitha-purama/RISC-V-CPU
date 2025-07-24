module instr_mem(
    input  wire [31:0] addr,
    output wire [31:0] instr
);

    reg [31:0] memory[0:31];
    integer i;

    initial begin
        // Example program: simple increment (replace with your own machine code)
        memory[0] = 32'h00500093; // addi x1, x0, 5
        memory[1] = 32'h00100113; // addi x2, x0, 1
        memory[2] = 32'h002081b3; // add x3, x1, x2
        memory[3] = 32'h00000013; // nop
        for(i=4; i<32; i=i+1)
            memory[i] = 32'h00000013; // nop
    end

    assign instr = memory[addr[6:2]]; // word aligned

endmodule

