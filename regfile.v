module regfile(
    input  wire        clk,
    input  wire        we3,
    input  wire [4:0]  ra1,
    input  wire [4:0]  ra2,
    input  wire [4:0]  wa3,
    input  wire [31:0] wd3,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);

reg [31:0] regs[0:31];
integer i;

initial begin
    for(i=0; i<32; i=i+1) regs[i] = 0;
end

assign rd1 = (ra1 != 0) ? regs[ra1] : 0;
assign rd2 = (ra2 != 0) ? regs[ra2] : 0;

always @(posedge clk) begin
    if(we3 && (wa3 != 0))
        regs[wa3] <= wd3;
end

// Task to dump all regs - can be called from testbench
task dump_registers;
    integer j;
    begin
        $display("\n--- Register File Contents ---");
        for(j=0; j<32; j=j+1) begin
            $display("x%0d = 0x%08x (%0d)", j, regs[j], regs[j]);
        end
        $display("------------------------------\n");
    end
endtask

endmodule
