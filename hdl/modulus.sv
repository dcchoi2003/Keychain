`timescale 1ns / 1ps
`default_nettype none

module modulus #(
    parameter WIDTH = 16
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire ready_in,
    input wire [WIDTH-1:0] value_in,
    input wire [WIDTH-1:0] modulus_in,
    output logic [WIDTH-1:0] value_out,
    output logic busy_out,
    output logic valid_out
    );

    // Pipeline depth
    localparam DEPTH = WIDTH;

    // Index width
    localparam INDEX_WIDTH = $clog2(DEPTH);

    // BUSY signal during the last clock cycle
    logic last_busy;

    // Combinationally assign the VALID signal
    assign valid_out = last_busy && !busy_out;

    // Intermediate results register
    logic [DEPTH-1:0] [WIDTH-1:0] intermediate;

    // Intermediate results index
    logic [INDEX_WIDTH-1:0] index;

    // Value to subtract from intermediate
    logic [2*WIDTH-1:0] subtrahend;

    // State
    // 00 -> Idle
    // 01 -> Doubling
    // 10 -> Subtracting
    // 11 -> Returning
    logic [1:0] state;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Reset the modulus block
            last_busy <= 1'b0;
            value_out <= 1'b0;
            busy_out <= 1'b0;
            intermediate <= 32'b0;
            subtrahend <= 0;
            state <= 2'b0;
            index <= 2'b0;
        end else begin
            case (state)
                2'b00: begin
                    // If READY is asserted, switch to the squaring state and load values
                    if (ready_in) begin
                        state <= 2'b01;
                        intermediate[0] <= value_in;
                        busy_out <= 1'b1;
                        subtrahend <= modulus_in << (DEPTH - 1);
                    end
                end

                2'b01: begin                   
                    // Perform subtraction operations

                    // Subtract the relevant multiple of the modulus, if necessary
                    if (intermediate[index] > subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - subtrahend;
                    end else begin
                        intermediate[index + 1] <= intermediate[index];
                    end

                    if (index == DEPTH-1) begin
                        // We're done
                        if (intermediate[index] >= modulus_in) begin
                            value_out <= intermediate[index] - modulus_in;
                        end else begin
                            value_out <= intermediate[index];
                        end

                        // Go to return state
                        state <= 2'b11;
                    end else begin
                        // Increment the result index
                        index <= index + 1;

                        // Update the subtrahend
                        subtrahend <= subtrahend >> 1;
                    end
                end

                2'b11: begin
                    // Return result

                    // Turn off the BUSY signal
                    busy_out <= 1'b0;

                    // Reset the index
                    index <= 0;

                    // Return to IDLE
                    state <= 2'b00;
                end

                // If invalid state, go back to idle
                default: state <= 2'b00;
            endcase
        end

        // Update the LASTBUSY register
        last_busy <= busy_out;
    end

endmodule

`default_nettype wire