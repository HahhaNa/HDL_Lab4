`timescale 1ns/1ps

module lab_4_1_t;
reg clk=0;
reg rst=0;
reg stop=0;
reg start=0;
reg direction=0;
wire [3:0] DIGIT;
wire [6:0] DISPLAY;
wire [9:0] led;

lab4_1 test(.clk(clk), .rst(rst), .stop(stop), .start(start), .direction(direction),
        .DIGIT(DIGIT), .DISPLAY(DISPLAY), .led(led));
always@* #5 clk = ~clk;
always@(*) begin
    @(negedge clk) rst = 1'b1;
    @(negedge clk) rst = 1'b0;
    #5000
    @(negedge clk) start = 1'b1; 
    @(negedge clk) start = 1'b0; 
    @(negedge clk) start = 1'b1;
    #20000
    @(negedge clk) direction = 1'b0; 
    @(negedge clk) direction = 1'b1;
    #20000
    @(negedge clk) stop = 1'b0; 
    @(negedge clk) stop = 1'b1;
end
endmodule