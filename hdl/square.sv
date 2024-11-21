`timescale 1ns / 1ps
`default_nettype none

module square #(
    parameter WIDTH = 16
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire ready_in,
    input wire [WIDTH-1:0] value_in,
    input wire [WIDTH-1:0] modulus_in,
    output logic [WIDTH-1:0] square_out,
    output logic busy_out,
    output logic valid_out
    );

    // BUSY signal during the last clock cycle
    logic last_busy;

    // Combinationally assign the VALID signal
    assign valid_out = last_busy && !busy_out;

    // Modulus block control signals
    logic modulus_ready, modulus_busy, modulus_valid;

    // Intermediate square value
    logic [2*WIDTH-1:0] intermediate;

    // Modulus block result
    logic [WIDTH-1:0] modulus_result;

    // State of FSM
    // 
    // Idle:    00
    // Square:  01
    // Modulus: 10
    // Return:  11
    logic [1:0] state;

    // Modulus block
    modulus #(
        .WIDTH(WIDTH)
    ) modulus_block (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .ready_in(modulus_ready),
        .value_in(intermediate),
        .modulus_in(modulus_in),
        .value_out(modulus_result),
        .busy_out(modulus_busy),
        .valid_out(modulus_valid)
    );

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Reset the block
            last_busy <= 1'b0;
            square_out <= 0;
            busy_out <= 1'b0;
            intermediate <= 0;
            state <= 2'b00;
            
            // Reset control signal
            modulus_ready <= 1'b0;
        end else begin
            case (state)
                // Idle
                2'b00: begin
                    // If this block is triggered and is not
                    // currently working, start working
                    if (ready_in) begin
                        // We're busy
                        busy_out <= 1'b1;
                        
                        // Begin squaring
                        state <= 2'b01;
                    end
                end

                // Squaring
                2'b01: begin
                    // Square the value
                    intermediate <= value_in * value_in;

                    // Begin modulus operation
                    state <= 2'b10;
                end

                // Computing modulus
                2'b10: begin
                    // All values are already loaded into the modulus block

                    // Trigger the modulus block
                    modulus_ready <= 1'b1;

                    // Wait for return
                    state <= 2'b11;
                end

                // Returning
                2'b11: begin
                    // Turn off trigger
                    modulus_ready <= 1'b0;

                    // If the modulus block is done, return
                    if (modulus_valid) begin
                        // Return output
                        square_out <= modulus_result;

                        // No longer busy
                        busy_out <= 1'b0;

                        // Return to idle state
                        state <= 2'b00;
                    end
                end

                // default case unnecessary as we've covered every possibility
            endcase
        end

        // Update the LASTBUSY register
        last_busy <= busy_out;
    end

endmodule

`default_nettype wire