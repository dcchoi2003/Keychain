`timescale 1ns / 1ps
`default_nettype none

module square #(
    parameter WIDTH = 16
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire ready_in,
    input wire [WIDTH-1:0] value_in,
    output logic [2*WIDTH-1:0] square_out,
    output logic busy_out,
    output logic valid_out
    );

    // BUSY signal during the last clock cycle
    logic last_busy;

    // Combinationally assign the VALID signal
    assign valid_out = last_busy && !busy_out;

    // Intermediate result
    logic [2*WIDTH-1:0] mult_result;

    // Reset the multiplier
    logic mult_rst;

    // State of FSM
    // 
    // Idle:   0
    // Square: 1
    logic state;

    logic square_enable;
    logic square_valid;

    simple_mult #(
        .INPUT_SIZE(WIDTH)
    ) square_block (
        .input_1(value_in),
        .input_2(value_in),
        .result(mult_result),
        .clk_in(clk_in),
        .rst_in(rst_in || mult_rst),
        .ready_in(square_enable),
        .valid_out(square_valid)
    );

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Reset the block
            last_busy <= 1'b0;
            square_out <= 0;
            busy_out <= 1'b0;
            state <= 1'b0;
            square_enable <= 1'b0;
        end else begin
            case (state)
                // Idle
                1'b0: begin
                    mult_rst <= 1'b0;

                    if (ready_in) begin
                        // We're busy
                        busy_out <= 1'b1;
                        
                        // Begin squaring
                        state <= 1'b1;
                    end
                end

                // Squaring
                1'b1: begin
                    if (!square_valid) begin
                        // Square the value
                        square_enable <= 1'b1;
                    end else if (square_valid) begin
                        // Return
                        state <= 1'b0;

                        // Output value
                        square_out <= mult_result;

                        // We're no longer busy!
                        busy_out <= 1'b0;

                        // Reset the multiplier
                        mult_rst <= 1'b1;
                    end
                end

                // default case unnecessary as we've covered every possibility
            endcase
        end

        // Update the LASTBUSY register
        last_busy <= busy_out;

        // Disable square enable signal after one cycle
        if (square_enable) begin
            square_enable <= 1'b0;
        end
    end

endmodule

`default_nettype wire