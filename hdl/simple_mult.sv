`timescale 1ns / 1ps
`default_nettype none

module simple_mult #(
        parameter INPUT_SIZE = 1024,
        parameter OUTPUT_SIZE = 2 * INPUT_SIZE
)
(
        // data IOs
        input   wire   [INPUT_SIZE-1:0]    input_1,
        input   wire   [INPUT_SIZE-1:0]    input_2,

        output  logic  [OUTPUT_SIZE-1:0]    result,

        // control IOs
        input   wire   clk_in,
        input   wire   rst_in,
        input   wire   ready_in,

        output  logic  busy_out,
        output  logic  valid_out
);


    localparam HALF_INPUT_SIZE = INPUT_SIZE / 2;

    logic [HALF_INPUT_SIZE-1:0] leftover_1, leftover_2;
    logic [$clog2(INPUT_SIZE)-1:0] shift_1, shift_2;
    logic [OUTPUT_SIZE-1:0] result_1, result_2;

    typedef enum {AWAITING, MULTIPLYING} state_t;

    state_t current_state;

    always_ff @(posedge clk_in)
        if(rst_in) begin
        
            valid_out <= 1'b0;
            busy_out <= 1'b0;
            result <= 0;
            current_state <= AWAITING;
        
        end else begin

            case (current_state) AWAITING: begin

                valid_out <= 1'b0;
                result <= 0;
                result_1 <= 0;
                result_2 <= 0;

                if (ready_in == 1'b1) begin
                    current_state <= MULTIPLYING;
                    {leftover_1, leftover_2} <= input_2;
                    shift_1 <= HALF_INPUT_SIZE;
                    shift_2 <= 0;
                    busy_out <= 1'b1;
                end

            end

            MULTIPLYING: begin

                if (leftover_1 == 0 && leftover_2 == 0) begin
                    busy_out <= 1'b0;
                    valid_out <= 1'b1;
                    result <= result_1 + result_2;
                    current_state <= AWAITING;
                end else begin

                    leftover_1 <= leftover_1 >> 1;
                    shift_1 <= shift_1 + 1'b1;

                    if (leftover_1 & 1'b1) begin
                        result_1 <= result_1 + (input_1 << shift_1);
                    end

                    leftover_2 <= leftover_2 >> 1;
                    shift_2 <= shift_2 + 1'b1;

                    if (leftover_2 & 1'b1) begin
                        result_2 <= result_2 + (input_1 << shift_2);
                    end

                end

            end

            default: begin
                valid_out <= 1'b0;
                busy_out <= 1'b0;
                current_state <= AWAITING;
            end

            endcase

        end

endmodule

`default_nettype wire