`timescale 1ns/1ps

module pipeline_cpu_tb();

    reg clk;
    reg reset;
    reg [7:0] switches;
    wire [7:0] leds;

    pipeline_cpu uut (
        .clk(clk),
        .reset(reset),
        .switches(switches),
        .leds(leds)
    );

    initial begin
        $dumpfile("pipeline_cpu.vcd");
        $dumpvars(0, pipeline_cpu_tb);

        clk = 0;
        reset = 1;
        switches = 8'hAA; // example initial switch state

        #20 reset = 0;

        #1000 ;
    
    // Call the register dump task inside regfile
    $display("\n====== Simulation Complete: Register Dump ======");
    uut.regs.dump_registers();
    
    $finish;
end

    end

    always #5 clk = ~clk;

endmodule

