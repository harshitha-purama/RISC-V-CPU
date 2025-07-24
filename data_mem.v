module data_mem(
    input  wire        clk,
    input  wire        memwrite,
    input  wire        memread,
    input  wire [31:0] addr,
    input  wire [31:0] writedata,
    output reg  [31:0] readdata,

    // Memory-mapped I/O signals
    output reg  [7:0]  led_output,
    input  wire [7:0]  switch_input
);

    reg [31:0] memory [0:127];
    integer i;

    initial begin
        for(i=0; i<128; i=i+1)
            memory[i] = 0;
        led_output = 0;
    end

    always @(posedge clk) begin
        if(memwrite) begin
            // Memory-mapped I/O region: e.g., 0xFFFF0000 for LED output
            if(addr >= 32'hFFFF0000 && addr <= 32'hFFFF0003) begin
                led_output <= writedata[7:0];
            end else if(addr < 32'h00000200) begin
                memory[addr[6:2]] <= writedata;
            end
        end
    end

    always @(*) begin
        if(memread) begin
            if(addr >= 32'hFFFF0100 && addr <= 32'hFFFF0103) begin
                // I/O read from switches
                readdata = {24'b0, switch_input};
            end else if(addr < 32'h00000200) begin
                readdata = memory[addr[6:2]];
            end else begin
                readdata = 32'b0;
            end
        end else begin
            readdata = 32'b0;
        end
    end

endmodule
