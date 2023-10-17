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

module lab4_2 ( 
    input wire clk,
    input wire rst,
    input wire Digit_1,
    input wire Digit_2,
    input wire Digit_3,
    input wire stop,
    input wire start,
    input wire increase,
    input wire decrease,
    input wire direction,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY,
    output reg [15:0] led
); 

    // clk
    wire clk_001, clk_1, clk_div;
    clock_divider clk1(.clk(clk), .clk_div(clk_div));
    clock_divider001 clk2(.clk(clk), .clk_div(clk_001));
    clock_divider1 clk3(.clk(clk), .clk_div(clk_1));

    // button signal
    wire stop_pb, start_pb, direction_pb, increase_pb, decrease_pb;
    wire stop_out, start_out, direction_out, increase_out, decrease_out;
    debounce d1(.clk(clk_div), .pb(stop), .pb_debounced(stop_pb));
    one_pulse o1(.clk(clk_div), .pb_in(stop_pb), .pb_out(stop_out));
    debounce d2(.clk(clk_div), .pb(start), .pb_debounced(start_pb));
    one_pulse o2(.clk(clk_div), .pb_in(start_pb), .pb_out(start_out));
    debounce d3(.clk(clk_div), .pb(direction), .pb_debounced(direction_pb));
    one_pulse o3(.clk(clk_div), .pb_in(direction_pb), .pb_out(direction_out));
    debounce d4(.clk(clk_div), .pb(increase), .pb_debounced(increase_pb));
    one_pulse o4(.clk(clk_div), .pb_in(increase_pb), .pb_out(increase_out));
    debounce d5(.clk(clk_div), .pb(decrease), .pb_debounced(decrease_pb));
    one_pulse o5(.clk(clk_div), .pb_in(decrease_pb), .pb_out(decrease_out));
    // parameter for state
    parameter INITIAL = 2'd0;
    parameter COUNTING = 2'd1;
    parameter FAIL = 2'd2;    
    parameter SUCCESS = 2'd3;
    // parameter for 7-segment
    parameter UP = 4'd10;
    parameter DOWN = 4'd11;
    parameter F = 4'd12;
    parameter S = 4'd13;
    parameter DASH = 4'd14;

    reg [1:0] state, next_state;
    reg [9:0] initail_num, end_num;
    reg [9:0] D0, D1, D2; // 3 2 1 0
    reg [9:0] next_D0, next_D1, next_D2;
    reg [9:0] first, hundreds, tens, units;
    reg [9:0] next_first, next_hundreds, next_tens, next_units;
    reg [3:0] value;
    reg [3:0] result[3:0];
    reg [3:0] dir, next_dir;
    reg [2:0] cnt_clk_1, next_cnt_clk_1;
    reg [2:0] cnt_clk_2, next_cnt_clk_2;
    reg [15:0] next_led;
    reg finish = 0, next_finish;
    reg enter = 1'b1;

    // sequential assign with reset
    always@(posedge clk_div, posedge rst) begin
        if(rst==1'b1) begin
            led <= 16'b1111_1111_1111_1111;
            state <= INITIAL;
            dir <= UP;
            first <= UP;
            D0 <= 4'd0;
            D1 <= 4'd0;
            D2 <= 4'd0;
            finish <= 1'b0;   
        end else begin
            led <= next_led;
            state <= next_state;
            dir <= next_dir;
            first <= next_first;
            D0 <= next_D0;
            D1 <= next_D1;
            D2 <= next_D2;
            finish <= next_finish;
        end
    end
    always@(posedge clk_001, posedge rst) begin
        if(rst==1'b1) begin        
            hundreds <= 4'd0;
            tens <= 4'd0;
            units <= 4'd0;        
        end else begin
            hundreds <= next_hundreds;
            tens <= next_tens;
            units <= next_units; 
        end
    end
    always@(posedge clk_1, posedge rst) begin
        if(rst==1'b1) begin
            cnt_clk_1 <= 3'd0;
            cnt_clk_2 <= 3'd0;
        end
        else begin
            cnt_clk_1 <= next_cnt_clk_1;
            cnt_clk_2 <= next_cnt_clk_2;
        end
    end

    // next_cnt_clk
    always@(*) begin
        if(state==INITIAL || state==FAIL || state==SUCCESS)
            next_cnt_clk_1 = 3'd0;
        else if(cnt_clk_1 <= 3'd5)
            next_cnt_clk_1 = cnt_clk_1 + 3'd1;
        else next_cnt_clk_1 = 3'd5;
    end
    always@(*) begin
        if(state==INITIAL || state==COUNTING)
            next_cnt_clk_2 = 3'd0;
        else if(cnt_clk_2 <= 3'd5)
            next_cnt_clk_2 = cnt_clk_2 + 3'd1;
        else next_cnt_clk_2 = 3'd5;
    end

    // FSM state, dir combinational
    always@(*) begin
        next_dir = dir;
        case(state) 
            INITIAL: begin
                if(start_out==1'b1) next_state = COUNTING;
                else begin
                    initail_num = D0 + D1*10'd10 + D2*10'd100;
                    next_state = INITIAL;
                    if(direction_out == 1'b1)
                        next_dir = (dir==UP)? DOWN:UP;
                end
            end
            COUNTING: begin
                if(finish==1'b1) begin
                    next_state = FAIL;
                end else if(stop_out==1'b1) begin
                    end_num = units + tens*10'd10 + hundreds*10'd100;
                    if(end_num>=initail_num && end_num-initail_num <= 10'd100)
                        next_state = SUCCESS;
                    else if(end_num<initail_num && initail_num-end_num <= 10'd100)
                        next_state = SUCCESS;
                    else next_state = FAIL;
                end else begin
                    next_state = COUNTING;
                end
            end
            FAIL: begin
                if(start_out==1'b1) next_state = INITIAL;
                else next_state = FAIL;
            end
            SUCCESS: begin
                if(start_out==1'b1) next_state = INITIAL;
                else next_state = SUCCESS;
            end
        endcase
    end

    // units, tens, hundreds, first control (next_...)
    // + D0, D1, D2, D3
    always@(*) begin
        case(state) 
            INITIAL: begin
                if(Digit_1==1'b1 && increase_out==1'b1) 
                    next_D0 = (D0==4'd9)? 4'd0:D0+4'd1;
                else if(Digit_1==1'b1 && decrease_out==1'b1) 
                    next_D0 = (D0==4'd0)? 4'd9:D0-4'd1;
                else if(enter == 1'b1) begin 
                    next_D0 = D0;
                end
                else next_D0 = next_D0;
                next_units = (dir==UP)? 4'd0:4'd9;
            end
            COUNTING: begin
                if(hundreds == 4'd9 && tens == 4'd9 && units == 4'd9 && dir == UP)
                    next_units = units;
                else if(hundreds == 4'd0 && tens == 4'd0 && units == 4'd0 && dir == DOWN)
                    next_units = units;
                else if(units == 4'd9 && dir==UP)  next_units = 4'd0;
                else if(units == 4'd0 && dir == DOWN) next_units = 4'd9;
                else if(dir == UP) next_units = units + 4'd1;
                else next_units = units - 4'd1;
            end
            FAIL, SUCCESS: begin
                next_units = units;
            end
        endcase
    end
    always@(*) begin
        case(state) 
            INITIAL: begin
                if(Digit_2==1'b1 && increase_out==1'b1) 
                    next_D1 = (D1==4'd9)? 4'd0:D1+4'd1;
                else if(Digit_2==1'b1 && decrease_out==1'b1) 
                    next_D1 = (D1==4'd0)? 4'd9:D1-4'd1;
                else if(enter == 1'b1) begin 
                    next_D1 = D1;
                end
                else next_D1 = next_D1;
                next_tens = (dir==UP)? 4'd0:4'd9;
            end
            COUNTING: begin
                if(hundreds == 4'd9 && tens == 4'd9 && units == 4'd9 && dir == UP)
                    next_tens = tens;
                else if(hundreds == 4'd0 && tens == 4'd0 && units == 4'd0 && dir == DOWN)
                    next_tens = tens;
                else if(hundreds != 4'd9 && tens == 4'd9 && dir == UP)  next_tens = 4'd0;
                else if(hundreds != 4'd0 && tens == 4'd0 && dir == DOWN) next_tens = 4'd9;
                else if(units == 4'd9 && dir==UP)
                    next_tens = tens + 4'd1;
                else if(units == 4'd0 && dir==DOWN)
                    next_tens = tens - 4'd1;
                else next_tens = tens;
            end
            FAIL, SUCCESS: begin
                next_tens = tens;
            end
        endcase
    end
    always@(*) begin
        case(state) 
            INITIAL: begin
                if(Digit_3==1'b1 && increase_out==1'b1) 
                    next_D2 = (D2==4'd9)? 4'd0:D2+4'd1;
                else if(Digit_3==1'b1 && decrease_out==1'b1) 
                    next_D2 = (D2==4'd0)? 4'd9:D2-4'd1;
                else if(enter == 1'b1) begin 
                    next_D2 = D2;
                end
                else next_D2 = next_D2;
                next_hundreds = (dir==UP)? 4'd0:4'd9;
            end
            COUNTING: begin
                enter = 1'b1;
                if(hundreds == 4'd9 && dir == UP)  next_hundreds = 4'd9;
                else if(hundreds == 4'd0 && dir == DOWN) next_hundreds = 4'd0;
                else if(tens == 4'd9 && dir==UP)
                    next_hundreds = hundreds + 4'd1;
                else if(tens == 4'd0 && dir==DOWN)
                    next_hundreds = hundreds - 4'd1;
                else next_hundreds = hundreds;
            end
            FAIL, SUCCESS: begin
                next_hundreds = hundreds;
            end
        endcase
    end
    always@(*) begin
        case(state) 
            INITIAL, COUNTING: begin
                if(dir==UP) next_first = UP;
                else next_first = DOWN;
            end
            FAIL: begin
                next_first = F;
            end
            SUCCESS: begin
                next_first = S;
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
            next_led = 16'b1111_1111_1111_1111;
        end 
        COUNTING: begin
            case(cnt_clk_1) 
                4'd0, 4'd1, 4'd2: next_led = 16'b1111_1111_1111_1111;
                default: next_led = 16'b0000_0000_0000_0000;
            endcase
        end
        FAIL: begin
            case(cnt_clk_2) 
                4'd0: next_led = 16'b1111_1111_1111_1111;
                4'd1: next_led = 16'b0000_0000_0000_0000;
                4'd2: next_led = 16'b1111_1111_1111_1111;
                4'd3: next_led = 16'b0000_0000_0000_0000;
                4'd4: next_led = 16'b1111_1111_1111_1111;
                default: next_led = 16'b0000_0000_0000_0000;
            endcase
        end
        SUCCESS: begin
            case(cnt_clk_2) 
                4'd0: next_led = 16'b1111_1111_1111_1111;
                4'd1: next_led = 16'b0000_0000_0000_0000;
                4'd2: next_led = 16'b1111_1111_1111_1111;
                4'd3: next_led = 16'b0000_0000_0000_0000;
                default: next_led = 16'b1111_1111_1111_1111;
            endcase
        end
        endcase
    end

     // 7-segment output (value, DIGIT)
    always@(posedge clk_div) begin
        case(DIGIT)
            4'b0111: begin
                if(state==COUNTING && cnt_clk_1>=3) value = DASH;
                else if(state==INITIAL) value = D0;
                else value = units;
                DIGIT = 4'b1110;
            end
            4'b1110: begin
                if(state==COUNTING && cnt_clk_1>=3) value = DASH;
                else if(state==INITIAL) value = D1;
                else value = tens;
                DIGIT = 4'b1101;
            end
            4'b1101: begin
                if(state==COUNTING && cnt_clk_1>=3) value = DASH;
                else if(state==INITIAL) value = D2;
                else value = hundreds;
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
            UP: DISPLAY = 7'b101_1100;
            DOWN: DISPLAY = 7'b110_0011; 
            S: DISPLAY = 7'b001_0010;
            F: DISPLAY = 7'b000_1110;
            DASH: DISPLAY = 7'b011_1111;
            default: DISPLAY = 7'b111_1111; // empty
        endcase
    end


endmodule 