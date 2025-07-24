`timescale 1ns/1ps

module cpu_tb();

    reg clk;
    reg reset;

    cpu uut(
        .clk(clk),
        .reset(reset)
    );

    initial begin
        $dumpfile("cpu_wave.vcd");
        $dumpvars(0, cpu_tb);

        clk = 0;
        reset = 1;

        #10 reset = 0;

        #500 $finish; // Run for some cycles
    end

    always #5 clk = ~clk;  // 10ns clock period
endmodule

