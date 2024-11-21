`timescale 1ns / 1ps
`default_nettype none

module exponent_modulus #(
    parameter WIDTH = 16
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire ready_in,
    input wire [7:0] value_in,
    input wire [7:0] modulus_in,
    input wire [7:0] exponent_in,
    output logic [15:0] value_out,
    output logic busy_out,
    output logic valid_out
    );

    // Intermediate result
    logic [2*WIDTH-1:0] intermediate;

    logic last_busy;

    assign valid_out = last_busy && !busy_out;

    // Modulus READY, BUSY, and VALID signals
    logic modulus_ready, modulus_busy, modulus_valid;

    // Modulus block
    modulus modulus_block (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .ready_in(modulus_ready),
        .value_in(intermediate),
        .modulus_in(modulus_in),
        .value_out(value_out),
        .busy_out(modulus_busy),
        .valid_out(modulus_valid)
    );

    // Squaring READY, BUSY, and VALID signals
    logic square_ready, square_busy, square_valid;

    // Squaring block
    // square square_block (
    //     .clk_in(clk_in),
    //     .rst_in(rst_in),
    //     .ready_in(square_ready),
    //     .value_in(0),
    //     .square_out(),
    //     .busy_out(square_busy),
    //     .valid_out(square_valid)
    // );

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Assert RESET
            intermediate <= 16'b0;
            busy_out <= 1'b0;
            modulus_ready <= 1'b0;
        end else begin
            if (ready_in && !busy_out) begin
                intermediate <= value_in ** exponent_in;
                busy_out <= 1'b1;
            end else if (modulus_valid) begin
                busy_out <= 1'b0;
            end else if (busy_out && !modulus_busy && !modulus_ready) begin
                modulus_ready <= 1'b1;
            end
            
            if (modulus_ready) begin
                modulus_ready <= 1'b0;
            end
        end

        // Update LASTBUSY register
        last_busy <= busy_out;
    end

endmodule

`default_nettype wire