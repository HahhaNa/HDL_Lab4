module debounce (
	input wire clk,
	input wire pb, 
	output wire pb_debounced 
);
	reg [3:0] shift_reg; 

	always @(posedge clk) begin
		shift_reg[3:1] <= shift_reg[2:0];
		shift_reg[0] <= pb;
	end

	assign pb_debounced = ((shift_reg == 4'b1111) ? 1'b1 : 1'b0);
endmodule

module one_pulse (
    input wire clk,
    input wire pb_in,
    output reg pb_out
);

	reg pb_in_delay;

	always @(posedge clk) begin
		if (pb_in == 1'b1 && pb_in_delay == 1'b0) begin
			pb_out <= 1'b1;
		end else begin
			pb_out <= 1'b0;
		end
	end
	
	always @(posedge clk) begin
		pb_in_delay <= pb_in;
	end
endmodule

module clock_divider #(
    parameter n = 27
)(
    input wire  clk,
    output wire clk_div  
);

    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule

module clock_divider000001(
    input clk, 
    input rst_n, 
    output reg clk_div
);
    reg [12:0] out, next_out;
    always @(posedge clk or posedge rst_n) begin
        if(rst_n==1'b1)begin
            out <= 0;
        end
        else begin
            out <= next_out;
        end
    end
    always@(*) begin
        if(out == 13'd5000 && rst_n==1'b0) begin
            next_out = 0;
            clk_div = (clk_div==1'b0)? 1'b1:1'b0;
        end
        else begin
            next_out = out + 13'd1;
            clk_div = clk_div;
        end
    end
endmodule

module clock_divider001(
    input clk, 
    input rst_n, 
    output reg clk_div
);
    reg [19:0] out, next_out;
    always @(posedge clk or posedge rst_n) begin
        if(rst_n==1'b1)begin
            out <= 0;
        end
        else begin
            out <= next_out;
        end
    end
    always@(*) begin
        if(out == 20'd500000 && rst_n==1'b0) begin
            next_out = 0;
            clk_div = (clk_div==1'b0)? 1'b1:1'b0;
        end
        else begin
            next_out = out + 20'd1;
            clk_div = clk_div;
        end
    end
endmodule

module clock_divider1(
    input clk, 
    input rst_n, 
    output reg clk_div
);
    reg [25:0] out, next_out;
    always @(posedge clk or posedge rst_n) begin
        if(rst_n==1'b1)begin
            out <= 0;
            clk_div <= 0;
        end
        else begin
            out <= next_out;
        end
    end
    always@(*) begin
        if(out == 26'd50000000 && rst_n==1'b0) begin
            next_out = 0;
            clk_div = (clk_div==1'b0)? 1'b1:1'b0;
        end
        else begin
            next_out = out + 26'd1;
            clk_div = clk_div;
        end
    end
endmodule

module lab4_1 ( 
    input wire clk,
    input wire rst,
    input wire stop,
    input wire start,
    input wire direction,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY,
    output reg [9:0] led
); 
    // clk
    wire clk_001, clk_1, clk_000001;
    clock_divider000001 clk1(.clk(clk), .clk_div(clk_000001), .rst_n(rst));
    clock_divider001 clk2(.clk(clk), .clk_div(clk_001), .rst_n(rst));
    clock_divider1 clk3(.clk(clk), .clk_div(clk_1), .rst_n(rst));

    // button signal
    wire stop_pb, start_pb, direction_pb;
    wire stop_out, start_out, direction_out;
    debounce d1(.clk(clk_000001), .pb(stop), .pb_debounced(stop_pb));
    one_pulse o1(.clk(clk_000001), .pb_in(stop_pb), .pb_out(stop_out));
    debounce d2(.clk(clk_000001), .pb(start), .pb_debounced(start_pb));
    one_pulse o2(.clk(clk_000001), .pb_in(start_pb), .pb_out(start_out));
    debounce d3(.clk(clk_000001), .pb(direction), .pb_debounced(direction_pb));
    one_pulse o3(.clk(clk_000001), .pb_in(direction_pb), .pb_out(direction_out));

    parameter INITIAL = 2'b00;
    parameter PREPARE = 2'b01;
    parameter COUNTING = 2'b10;
    parameter RESULT = 2'b11;

    reg [1:0] state, next_state;
    reg [9:0] counts;
    reg [3:0] first, hundreds, tens, digits;
    reg [3:0] next_first, next_hundreds, next_tens, next_digits;
    reg [3:0] value;
    reg [3:0] result[3:0];
    reg dir, next_dir;
    reg finish = 0;
    reg [2:0] cnt_clk_1, next_cnt_clk_1;
    reg[9:0] next_led;
    reg led_finish;
    
    parameter UP = 1'b0;
    parameter DOWN = 1'b1;

    // sequential assign with reset
    always@(posedge clk_000001, posedge rst) begin
        if(rst==1'b1) begin
            state <= INITIAL;
            dir <= 0;
            first <= 4'd0;
        end else begin
            state <= next_state;
            dir <= next_dir;
            first <= next_first;
        end
    end
    always@(posedge clk_001, posedge rst) begin
        if(rst==1'b1) begin
            led <= 10'b111_111_1111;
            hundreds <= 4'd0;
            tens <= 4'd0;
            digits <= 4'd0;
        end else begin
            led <= next_led;
            hundreds <= next_hundreds;
            tens <= next_tens;
            digits <= next_digits;
        end
    end
    always@(posedge clk_1, posedge rst) begin
        if(rst==1'b1 || state==INITIAL || state==COUNTING)
            cnt_clk_1 <= 3'd0;
        else cnt_clk_1 <= next_cnt_clk_1;
    end

    // FSM state, dir combinational
    always@(*) begin
        next_dir = dir;
        case(state) 
            INITIAL: begin
                if(start_out==1'b1) next_state = PREPARE;
                else begin
                    next_state = INITIAL;
                    if(direction_out == 1'b1)
                        next_dir = (dir==0)? 1:0;
                end
            end
            PREPARE: begin
                if(cnt_clk_1==3'd3) next_state = COUNTING;
                else next_state = PREPARE;
            end
            COUNTING: begin
                if(stop_out==1'b1 || finish==1'b1) begin
                    next_state = RESULT;
                    result[3] = first;
                    result[2] = hundreds;
                    result[1] = tens;
                    result[0] = digits;
                end
                else next_state = COUNTING;
            end
            RESULT: begin
                if(start_out==1'b1) next_state = INITIAL;
                else next_state = RESULT;
            end
        endcase
    end

    // digits, tens, hundreds, first control (next_...)
    always@(*) begin
        case(state)
        INITIAL: begin
            if(dir==UP) begin
                next_first = 4'd11;
                next_hundreds = 4'd0;
                next_tens = 4'd0;
                next_digits = 4'd0;
            end else if(dir==DOWN) begin
                next_first = 4'd12;
                next_hundreds = 4'd9;
                next_tens = 4'd9;
                next_digits = 4'd9;
            end
        end 
        PREPARE: begin
            next_first = 4'd10;
            next_hundreds = hundreds;
            next_tens = tens;
            next_digits = digits;
            finish = 0;
        end
        COUNTING: begin
            if(dir==UP) begin
                next_first = 4'd11;
                if(digits==4'd9) begin
                    next_digits = 4'd0;
                    if(tens==4'd9) begin
                        next_tens = 4'd0;
                        if(hundreds==4'd9) finish = 1;
                        else next_hundreds = hundreds+1;
                    end else next_tens = tens+1;
                end else next_digits = digits+1;
            end else if(dir==DOWN) begin
                next_first = 4'd12;
                if(digits==4'd0) begin
                    next_digits = 4'd9;
                    if(tens==4'd0) begin
                        next_tens = 4'd9;
                        if(hundreds==4'd0) finish = 1;
                        else next_hundreds = hundreds-1;
                    end else next_tens = tens-1;
                end else next_digits = digits-1;
            end
        end
        RESULT: begin
            next_digits = result[0];
            next_tens = result[1];
            next_hundreds = result[2];
            next_first = result[3];
        end
        endcase
    end

    // next_cnt_clk
    always@(*) begin
        if(cnt_clk_1 < 3'd5)
            next_cnt_clk_1 = cnt_clk_1 + 3'd1;
        else next_cnt_clk_1 = 3'd5;
    end
    // led output combinational (next_led)
    always@(*) begin
        case(state)
        INITIAL: begin
            next_led = 10'b111_111_1111;
        end 
        PREPARE: begin
            // next_led = 10'd0;
            if(clk_1==1'b1) next_led = 10'b111_111_1111;
            else next_led = 10'd0;
        end
        COUNTING: begin
            case(hundreds)
                4'd0: next_led = 10'b000_000_0001;
                4'd1: next_led = 10'b000_000_0010;
                4'd2: next_led = 10'b000_000_0100;
                4'd3: next_led = 10'b000_000_1000;
                4'd4: next_led = 10'b000_001_0000;
                4'd5: next_led = 10'b000_010_0000;
                4'd6: next_led = 10'b000_100_0000;
                4'd7: next_led = 10'b001_000_0000;
                4'd8: next_led = 10'b010_000_0000;
                4'd9: next_led = 10'b100_000_0000;
                default: next_led = 10'b000_000_0000;
            endcase
        end
        RESULT: begin
            if(cnt_clk_1<5) begin
                next_led = (cnt_clk_1%3'd2 != 0)? 10'b111_111_1111:10'd0;
            end else begin
                next_led = 10'b111_111_1111;
            end
        end
        endcase
    end

     // 7-segment output (value, DIGIT)
    always@(posedge clk_000001) begin
        case(DIGIT)
            4'b0111: begin
                if(state==COUNTING || state==RESULT)
                    value = digits;
                else if(state==INITIAL)
                    value = 4'd13;
                else value = 4'd15; 
                DIGIT = 4'b1110;
            end
            4'b1110: begin
                if(state==COUNTING || state==RESULT)
                    value = tens;
                else if(state==INITIAL)
                    value = 4'd13;
                else value = 4'd15; 
                DIGIT = 4'b1101;
            end
            4'b1101: begin
                if(state==COUNTING || state==RESULT)
                    value = hundreds;
                else if(state==INITIAL)
                    value = 4'd13;
                else value = 4'd15; 
                DIGIT = 4'b1011;
            end
            4'b1011: begin
                value = first;
                DIGIT = 4'b0111;
            end
            default: begin
                value = first;
                DIGIT = 4'b0111;
            end
        endcase
    end

    // value display
    always @(*) begin
        case(value)
            4'd0: DISPLAY = 7'b100_0000;
            4'd1: DISPLAY = 7'b111_1001;
            4'd2: DISPLAY = 7'b010_0100;
            4'd3: DISPLAY = 7'b011_0000;
            4'd4: DISPLAY = 7'b001_1001;
            4'd5: DISPLAY = 7'b001_0010;
            4'd6: DISPLAY = 7'b000_0010;
            4'd7: DISPLAY = 7'b111_1000;
            4'd8: DISPLAY = 7'b000_0000;
            4'd9: DISPLAY = 7'b001_0000;
            4'd10: DISPLAY = 7'b000_1100; // P
            4'd11: DISPLAY = 7'b101_1100; // UP
            4'd12: DISPLAY = 7'b110_0011; // DOWN
            4'd13: DISPLAY = 7'b011_1111; // -
            default: DISPLAY = 7'b111_1111;
        endcase
    end

endmodule 