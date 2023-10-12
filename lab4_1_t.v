`timescale 1ns/1ps

module lab_4_1_t;
reg clk;
reg rst;
reg stop;
reg start;
reg direction;
wire [3:0] DIGIT;
wire [6:0] DISPLAY;
wire [9:0] led;

lab4_1(.clk(clk), .rst(rst), .stop(stop), .start(start), .direction(direction),
        .DIGIT(DIGIT), .DISPLAY(DISPLAY), .led(led));
always@* #5 clk = ~clk;
always@(*) begin
    @(negedge clk) rst = 1'b1;
    @(negedge clk) rst = 1'b0;
    #5000
    @(negedge clk) start = 1'b1; direction = 1'b1;
    @(negedge clk) start = 1'b0; 
    @(negedge clk) start = 1'b1;
    #1500
end
endmodule