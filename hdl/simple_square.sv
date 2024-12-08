`timescale 1ns / 1ps
`default_nettype none

module simple_square #(
        parameter input_size = 1024,
        parameter output_size = 2 * input_size
)
(
        // data IOs
        input   wire   [input_size-1:0]    input_1,
        input   wire   [input_size-1:0]    input_2,

        output  logic  [output_size-1:0]    result,

        // control IOs
        input   wire   clk_in,
        input   wire   rst_in,
        input   wire   ready_in,

        output  logic  busy_out,
        output  logic  valid_out
);

    logic [input_size-1:0] leftover;
    logic [$clog2(input_size)-1:0] shift;

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
                shift <= 0;

                if (ready_in == 1'b1) begin
                    current_state <= MULTIPLYING;
                    leftover <= input_2;
                    busy_out <= 1'b1;
                end

            end

            MULTIPLYING: begin

                if (leftover == 0) begin
                    busy_out <= 1'b0;
                    valid_out <= 1'b1;
                    current_state <= AWAITING;
                end else begin

                    leftover <= leftover >> 1;
                    shift <= shift + 1'b1;

                    if (leftover & 1'b1) begin
                        result <= result + (input_1 << shift);
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