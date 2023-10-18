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

module clock_divider(
    input clk, 
    output reg clk_div
);
    reg [14:0] out, next_out;
    reg next_clk_div;
    always @(posedge clk) begin 
        out <= next_out;
        clk_div <= next_clk_div;
    end
    always@(*) begin
        if(out == 15'd10000) begin
            next_out = 0;
            next_clk_div = (clk_div==1'b0)? 1'b1:1'b0;
        end
        else begin
            next_out = out + 13'd1;
            next_clk_div = clk_div;
        end
    end
endmodule

module clock_divider001(
    input clk, 
    output reg clk_div
);
    reg [19:0] out, next_out;
    reg next_clk_div;
    always @(posedge clk) begin
        out <= next_out;
        clk_div <= next_clk_div;
    end
    always@(*) begin
        if(out == 20'd500000) begin
            next_out = 0;
            next_clk_div = (clk_div==1'b0)? 1'b1:1'b0;
        end
        else begin
            next_out = out + 20'd1;
            next_clk_div = clk_div;
        end
    end
endmodule

module clock_divider1(
    input clk, 
    output reg clk_div
);
    reg [25:0] out, next_out;
    reg next_clk_div;
    always @(posedge clk) begin
        out <= next_out;
        clk_div <= next_clk_div;
    end
    always@(*) begin
        if(out == 26'd50000000) begin
            next_out = 0;
            next_clk_div = (clk_div==1'b0)? 1'b1:1'b0;
        end
        else begin
            next_out = out + 26'd1;
            next_clk_div = clk_div;
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
    wire clk_001, clk_1, clk_div;
    clock_divider clk1(.clk(clk), .clk_div(clk_div));
    clock_divider001 clk2(.clk(clk), .clk_div(clk_001));
    clock_divider1 clk3(.clk(clk), .clk_div(clk_1));

    // button signal
    wire stop_pb, start_pb, direction_pb;
    wire stop_out, start_out, direction_out;
    debounce d1(.clk(clk_div), .pb(stop), .pb_debounced(stop_pb));
    one_pulse o1(.clk(clk_div), .pb_in(stop_pb), .pb_out(stop_out));
    debounce d2(.clk(clk_div), .pb(start), .pb_debounced(start_pb));
    one_pulse o2(.clk(clk_div), .pb_in(start_pb), .pb_out(start_out));
    debounce d3(.clk(clk_div), .pb(direction), .pb_debounced(direction_pb));
    one_pulse o3(.clk(clk_div), .pb_in(direction_pb), .pb_out(direction_out));

    parameter INITIAL = 2'b00;
    parameter PREPARE = 2'b01;
    parameter COUNTING = 2'b10;
    parameter RESULT = 2'b11;

    parameter P = 4'd10;
    parameter UP = 4'd11;
    parameter DOWN = 4'd12;
    parameter DASH = 4'd13;

    reg [1:0] state, next_state;
    reg [3:0] first, hundreds, tens, units;
    reg [3:0] next_first, next_hundreds, next_tens, next_units;
    reg [3:0] value;
    reg [3:0] result[3:0];
    reg [3:0] dir, next_dir;
    reg finish = 0, next_finish;
    reg [2:0] cnt_clk_1, next_cnt_clk_1;
    reg [2:0] cnt_clk_2, next_cnt_clk_2;
    reg[9:0] next_led;

    // sequential assign with reset
    always@(posedge clk_div, posedge rst) begin
        if(rst==1'b1) begin
            state <= INITIAL;
            led <= 10'b111_111_1111;
            dir <= UP;
            first <= 4'd11;
            finish <= 1'b0;
        end else begin
            state <= next_state;
            led <= next_led;
            dir <= next_dir;
            first <= next_first;
            finish <= next_finish;
        end
    end
    always@(posedge clk_001, posedge rst) begin
        if(rst==1'b1) begin     
            hundreds <= DASH;
            tens <= DASH;
            units <= DASH;     
        end else begin       
            hundreds <= next_hundreds;
            tens <= next_tens;
            units <= next_units;       
        end
    end
    always@(posedge clk_1, posedge rst) begin
        if(rst==1'b1 || state==INITIAL || state==COUNTING) begin
            cnt_clk_1 <= 3'd0;
            cnt_clk_2 <= 3'd0;
        end else if(state==PREPARE) begin
            cnt_clk_1 <= next_cnt_clk_1;
            cnt_clk_2 <= 3'd0;
        end else begin
            cnt_clk_1 <= 3'd0;
            cnt_clk_2 <= next_cnt_clk_2;
        end
    end

    // next_cnt_clk
    always@(*) begin
        if(state==INITIAL || state==COUNTING || state==RESULT)
            next_cnt_clk_1 = 3'd0;
        else if(cnt_clk_1 < 3'd3)
            next_cnt_clk_1 = cnt_clk_1 + 3'd1;
        else next_cnt_clk_1 = 3'd3;
    end
    always@(*) begin
        if(state==INITIAL || state==COUNTING || state==PREPARE)
            next_cnt_clk_2 = 3'd0;
        else if(cnt_clk_2 < 3'd5)
            next_cnt_clk_2 = cnt_clk_2 + 3'd1;
        else next_cnt_clk_2 = 3'd5;
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
                        next_dir = (dir==UP)? DOWN:UP;
                end
            end
            PREPARE: begin
                if(cnt_clk_1==3'd3) next_state = COUNTING;
                else next_state = PREPARE;
            end
            COUNTING: begin
                if(stop_out==1'b1 || finish==1'b1) begin
                    next_state = RESULT;
                end
                else next_state = COUNTING;
            end
            RESULT: begin
                if(start_out==1'b1) next_state = INITIAL;
                else next_state = RESULT;
            end
        endcase
    end

    // units, tens, hundreds, first control (next_...)
    always@(*) begin
        case(state) 
            INITIAL: begin
                next_units = DASH; // -
            end
            PREPARE: begin
                next_units = 4'd15; // empty
            end
            COUNTING: begin
                if(hundreds == 4'd9 && tens == 4'd9 && units == 4'd9 && dir == UP)
                    next_units = units;
                else if(hundreds == 4'd0 && tens == 4'd0 && units == 4'd0 && dir == DOWN)
                    next_units = units;
                else if(units == 4'd15 && dir == UP)
                    next_units = 4'd0;
                else if(units == 4'd15 && dir == DOWN)
                    next_units = 4'd9;
                else if(units == 4'd9 && dir==UP)  next_units = 4'd0;
                else if(units == 4'd0 && dir == DOWN) next_units = 4'd9;
                else if(dir == UP) next_units = units + 4'd1;
                else next_units = units - 4'd1;
            end
            RESULT: begin
                next_units = units;
            end
        endcase
    end
    always@(*) begin
        case(state) 
            INITIAL: begin
                next_tens = DASH; // -
            end
            PREPARE: begin
                next_tens = 4'd15; // empty
            end
            COUNTING: begin
                if(hundreds == 4'd9 && tens == 4'd9 && units == 4'd9 && dir == UP)
                    next_tens = tens;
                else if(hundreds == 4'd0 && tens == 4'd0 && units == 4'd0 && dir == DOWN)
                    next_tens = tens;
                else if(tens == 4'd15 && dir == UP)
                    next_tens = 4'd0;
                else if(tens == 4'd15 && dir == DOWN)
                    next_tens = 4'd9;
                else if(hundreds != 4'd9 && tens == 4'd9 && dir == UP)  next_tens = 4'd0;
                else if(hundreds != 4'd0 && tens == 4'd0 && dir == DOWN) next_tens = 4'd9;
                else if(units == 4'd9 && dir==UP)
                    next_tens = tens + 4'd1;
                else if(units == 4'd0 && dir==DOWN)
                    next_tens = tens - 4'd1;
                else next_tens = tens;
            end
            RESULT: begin
                next_tens = tens;
            end
        endcase
    end
    always@(*) begin
        case(state) 
            INITIAL: begin
                next_hundreds = DASH; // -
            end
            PREPARE: begin
                next_hundreds = 4'd15; // empty
            end
            COUNTING: begin
                if(hundreds == 4'd15 && dir == UP)
                    next_hundreds = 4'd0;
                else if(hundreds == 4'd15 && dir == DOWN)
                    next_hundreds = 4'd9;
                else if(hundreds == 4'd9 && dir == UP)  next_hundreds = 4'd9;
                else if(hundreds == 4'd0 && dir == DOWN) next_hundreds = 4'd0;
                else if(tens == 4'd9 && dir==UP)
                    next_hundreds = hundreds + 4'd1;
                else if(tens == 4'd0 && dir==DOWN)
                    next_hundreds = hundreds - 4'd1;
                else next_hundreds = hundreds;
            end
            RESULT: begin
                next_hundreds = hundreds;
            end
        endcase
    end
    always@(*) begin
        case(state) 
            INITIAL, COUNTING, RESULT: begin
                if(dir==UP) next_first = 4'd11; // UP
                else next_first = 4'd12; // DOWN
            end
            PREPARE: begin
                next_first = P; // P
            end
        endcase
    end

    // the finish for counting
    always@(*) begin
        if(state==COUNTING) begin
            if(dir==UP && units==4'd9 && tens==4'd9 && hundreds==4'd9)
                next_finish = 1'b1;
            else if(dir==DOWN && units==4'd0 && tens==4'd0 && hundreds==4'd0)
                next_finish = 1'b1;
            else next_finish = 1'b0;
        end else begin
            next_finish = 1'b0;
        end
    end

    // led output combinational (next_led)
    always@(*) begin
        case(state)
        INITIAL: begin
            next_led = 10'b111_111_1111;
        end 
        PREPARE: begin
            next_led = 10'd0;
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
            case(cnt_clk_2) 
                4'd0: next_led = 10'b111_111_1111;
                4'd1: next_led = 10'b000_000_0000;
                4'd2: next_led = 10'b111_111_1111;
                4'd3: next_led = 10'b000_000_0000;
                4'd4: next_led = 10'b111_111_1111;
                default: next_led = 10'b111_111_1111;
            endcase
        end
        endcase
    end

     // 7-segment output (value, DIGIT)
    always@(posedge clk_div) begin
        case(DIGIT)
            4'b0111: begin
                value = units;
                DIGIT = 4'b1110;
            end
            4'b1110: begin
                value = tens;
                DIGIT = 4'b1101;
            end
            4'b1101: begin
                value = hundreds;
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
            P: DISPLAY = 7'b000_1100; // P
            UP: DISPLAY = 7'b101_1100; // UP
            DOWN: DISPLAY = 7'b110_0011; // DOWN
            DASH: DISPLAY = 7'b011_1111; // -
            default: DISPLAY = 7'b111_1111;
        endcase
    end

endmodule 