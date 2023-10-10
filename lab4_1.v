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

module clock_divider2(
    input wire  clk,
    output wire clk_div  
);

    reg [19:0] num;
    wire [19:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1'd1;
    assign clk_div = (next_num==20'd1000000)? 1:0;
    assign next_num = (next_num==20'd1000000)? 0:next_num;
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
    wire stop_pb, start_pb;
    debounce(clk, stop, stop_pb);
    one_pulse(clk, stop_pb, stop_pb);
    debounce(clk, start, start_pb);
    one_pulse(clk, start_pb, start_pb);

    reg clk_001;

    parameter INITIAL = 2'b00;
    parameter PREPARE = 2'b01;
    parameter COUNTING = 2'b10;
    parameter RESULT = 2'b11;
    reg [1:0] state, next_state;
    reg [9:0] counts;
    reg [3:0] first, hundreds, tens, digits;
    reg [3:0] value;
    reg [3:0] result[3:0];
    reg finish = 0;

    parameter UP = 1'b1;
    parameter DOWN = 1'b0;

    // state reset
    always@(posedge clk, negedge rst) begin
        if(!rst) begin
            state <= INITIAL;
        end else begin
            state <= next_state;
        end
    end
    // digits combinational
    always@(posedge clk, negedge rst) begin
        case(state)
        INITIAL: begin
            if(direction==UP) begin
                first <= 4'd11;
                hundreds <= 0;
                tens <= 0;
                digits <= 0;
            end else if(direction==DOWN) begin
                first <= 4'd12;
                hundreds <= 9;
                tens <= 9;
                digits <= 9;
            end
        end 
        PREPARE: begin
            first <= 4'd10;
            hundreds <= hundreds;
            tens <= tens;
            digits <= digits;
        end
        COUNTING: begin
            if(direction==UP) begin
                first <= 4'd11;
                if(digits==4'd9) begin
                    digits <= 4'd0;
                    if(tens==4'd9) begin
                        tens <= 4'd0;
                        if(hundreds==4'd9) finish <= 1;
                        else hundreds <= hundreds+1;
                    end else tens <= tens+1;
                end else digits <= digits+1;
            end else if(direction==DOWN) begin
                first <= 4'd12;
                if(digits==4'd0) begin
                    digits <= 4'd9;
                    if(tens==4'd0) begin
                        tens <= 4'd9;
                        if(hundreds==4'd0) finish <= 1;
                        else hundreds <= hundreds-1;
                    end else tens <= tens-1;
                end else digits <= digits-1;
            end
        end
        RESULT: begin
            digits <= result[0];
            tens <= result[1];
            hundreds <= result[2];
            first <= result[3];
        end
        endcase
    end

     // 7-segment output
    always@(posedge clk) begin
        case(DIGIT)
            4'b1110: begin
                if(state==COUNTING || state==RESULT)
                    value = digits;
                else if(state==INITIAL)
                    value = 4'd13;
                else value = 4'd15; 
                DIGIT = 4'b1101;
            end
            4'b1101: begin
                if(state==COUNTING || state==RESULT)
                    value = tens;
                else if(state==INITIAL)
                    value = 4'd13;
                else value = 4'd15; 
                DIGIT = 4'b1011;
            end
            4'b1011: begin
                if(state==COUNTING || state==RESULT)
                    value = hundreds;
                else if(state==INITIAL)
                    value = 4'd13;
                else value = 4'd15; 
                DIGIT = 4'b0111;
            end
            4'b0111: begin
                value = first;
                DIGIT = 4'b1110;
            end
            default: begin
                value = first;
                DIGIT = 4'b1110;
            end
        endcase
    end

    // state combinational
    always@(*) begin
        case(state) 
            INITIAL: begin
                if(start_pb) next_state = PREPARE;
                else next_state = INITIAL;
            end
            PREPARE: begin
                if(clk_001==3) next_state = COUNTING;
                else next_state = PREPARE;
            end
            COUNTING: begin
                if(stop_pb || (direction==UP && counts==10'd999) || (direction==DOWN && counts==10'd0)) begin
                    next_state = RESULT;
                    result[3] = first;
                    result[2] = hundreds;
                    result[1] = tens;
                    result[0] = digits;
                end
                else next_state = COUNTING;
            end
            RESULT: begin
                if(start_pb) next_state = INITIAL;
                else next_state = RESULT;
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