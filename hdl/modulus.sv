`timescale 1ns / 1ps
`default_nettype none

module modulus (
    input wire clk_in,
    input wire rst_in,
    input wire ready_in,
    input wire [7:0] value_in,
    input wire [7:0] modulus_in,
    output logic [7:0] value_out,
    output logic busy_out,
    output logic valid_out
    );

    // BUSY signal during the last clock cycle
    logic last_busy;

    // Combinationally assign the VALID signal
    assign valid_out = last_busy && !busy_out;

    // "Dummy" delay register
    logic [3:0] delay;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Reset the modulus block
            last_busy <= 1'b0;
            delay <= 4'b0;
            value_out <= 1'b0;
            busy_out <= 1'b0;
        end else begin
            if (ready_in) begin
                // When READY is asserted, turn on
                // backpressure and start calculation
                busy_out <= 1'b1;
            end else if (busy_out && delay != 4'b1111) begin
                // "Dummy" calculation
                delay <= delay + 1;
            end else if (delay == 4'b1111) begin
                // Actually do the calculation
                value_out <= value_in % modulus_in;

                // Turn off the backpressure
                busy_out <= 1'b0;

                // Reset the delay register
                delay <= 1'b0;
            end
        end

        // Update the LASTBUSY register
        last_busy <= busy_out;
    end

endmodule

`default_nettype wire