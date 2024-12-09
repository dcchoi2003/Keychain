`timescale 1ns / 1ps
`default_nettype none

module modulus #(
    parameter WIDTH = 16
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire ready_in,
    input wire [2*WIDTH-1:0] value_in,
    input wire [WIDTH-1:0] modulus_in,
    output logic [WIDTH-1:0] value_out,
    output logic busy_out,
    output logic valid_out
    );

    // Pipeline depth
    localparam DEPTH = WIDTH / 2;

    // Index width
    localparam INDEX_WIDTH = $clog2(DEPTH);

    // BUSY signal during the last clock cycle
    logic last_busy;

    // Combinationally assign the VALID signal
    assign valid_out = last_busy && !busy_out;

    // Intermediate results register
    logic [DEPTH-1:0] [2*WIDTH-1:0] intermediate;

    // Intermediate results index
    logic [INDEX_WIDTH-1:0] index;

    // Value to subtract from intermediate
    logic [2*WIDTH + DEPTH - 1:0] subtrahend;

    // State
    // 0 -> Idle
    // 1 -> Subtracting
    logic state;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Reset the modulus block
            last_busy <= 1'b0;
            value_out <= 1'b0;
            busy_out <= 1'b0;
            intermediate <= 0;
            subtrahend <= 0;
            state <= 1'b0;
            index <= 0;
        end else begin
            case (state)
                1'b0: begin
                    // If READY is asserted, switch to the subtraction state and load values
                    if (ready_in) begin
                        state <= 2'b11;
                        intermediate[0] <= value_in;
                        busy_out <= 1'b1;
                        subtrahend <= modulus_in << (WIDTH + DEPTH - 1);
                    end
                end

                1'b1: begin                   
                    // Perform subtraction operations

                    // Subtract the relevant multiple of the modulus, if necessary
                    if (intermediate[index] >= 15 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 15 * subtrahend;
                    end else if (intermediate[index] >= 14 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 14 * subtrahend;
                    end else if (intermediate[index] >= 13 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 13 * subtrahend;
                    end else if (intermediate[index] >= 12 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 12 * subtrahend;
                    end else if (intermediate[index] >= 11 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 11 * subtrahend;
                    end else if (intermediate[index] >= 10 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 10 * subtrahend;
                    end else if (intermediate[index] >= 9 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 9 * subtrahend;
                    end else if (intermediate[index] >= 8 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 8 * subtrahend;
                    end else if (intermediate[index] >= 7 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 7 * subtrahend;
                    end else if (intermediate[index] >= 6 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 6 * subtrahend;
                    end else if (intermediate[index] >= 5 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 5 * subtrahend;
                    end else if (intermediate[index] >= 4 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 4 * subtrahend;
                    end else if (intermediate[index] >= 3 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 3 * subtrahend;
                    end else if (intermediate[index] >= 2 * subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - 2 * subtrahend;
                    end else if (intermediate[index] >= subtrahend) begin
                        intermediate[index + 1] <= intermediate[index] - subtrahend;
                    end else begin
                        intermediate[index + 1] <= intermediate[index];
                    end

                    if (index == DEPTH-1 || subtrahend < modulus_in) begin
                        // We're done
                        if (intermediate[index] >= 15 * modulus_in) begin
                            value_out <= intermediate[index] - 15 * modulus_in;
                        end else if (intermediate[index] >= 14 * modulus_in) begin
                            value_out <= intermediate[index] - 14 * modulus_in;
                        end else if (intermediate[index] >= 13 * modulus_in) begin
                            value_out <= intermediate[index] - 13 * modulus_in;
                        end else if (intermediate[index] >= 12 * modulus_in) begin
                            value_out <= intermediate[index] - 12 * modulus_in;
                        end else if (intermediate[index] >= 11 * modulus_in) begin
                            value_out <= intermediate[index] - 11 * modulus_in;
                        end else if (intermediate[index] >= 10 * modulus_in) begin
                            value_out <= intermediate[index] - 10 * modulus_in;
                        end else if (intermediate[index] >= 9 * modulus_in) begin
                            value_out <= intermediate[index] - 9 * modulus_in;
                        end else if (intermediate[index] >= 8 * modulus_in) begin
                            value_out <= intermediate[index] - 8 * modulus_in;
                        end else if (intermediate[index] >= 7 * modulus_in) begin
                            value_out <= intermediate[index] - 7 * modulus_in;
                        end else if (intermediate[index] >= 6 * modulus_in) begin
                            value_out <= intermediate[index] - 6 * modulus_in;
                        end else if (intermediate[index] >= 5 * modulus_in) begin
                            value_out <= intermediate[index] - 5 * modulus_in;
                        end else if (intermediate[index] >= 4 * modulus_in) begin
                            value_out <= intermediate[index] - 4 * modulus_in;
                        end else if (intermediate[index] >= 3 * modulus_in) begin
                            value_out <= intermediate[index] - 3 * modulus_in;
                        end else if (intermediate[index] >= 2 * modulus_in) begin
                            value_out <= intermediate[index] - 2 * modulus_in;
                        end else if (intermediate[index] >= modulus_in) begin
                            value_out <= intermediate[index] - modulus_in;
                        end else begin
                            value_out <= intermediate[index];
                        end

                        // Turn off the BUSY signal
                        busy_out <= 1'b0;

                        // Reset the index
                        index <= 0;

                        // Reset the intermediate
                        intermediate <= 0;
                        
                        // Reset the subtrahend
                        subtrahend <= 0;

                        // Return to IDLE
                        state <= 1'b0;
                    end else begin
                        // Increment the result index
                        index <= index + 1;

                        // Update the subtrahend
                        subtrahend <= subtrahend >> 4;
                    end
                end

                // default case unnecessary
            endcase
        end

        // Update the LASTBUSY register
        last_busy <= busy_out;
    end

endmodule

`default_nettype wire