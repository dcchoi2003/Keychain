`timescale 1ns / 1ps
`default_nettype none

module keychain #(
    parameter KEY_BYTES = 4,
    parameter MSG_BYTES = 2,
    parameter BAUD_RATE = 115_200
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire rx_wire_in,
    output logic tx_wire_out
    );

    // UART control signals
    logic rx_valid, tx_ready, tx_busy;

    // ExpMod control signals
    logic expmod_ready, expmod_busy, expmod_valid;

    always_ff @(posedge clk_in) begin
        expmod_ready <= rx_valid;
        tx_ready <= expmod_valid;
    end

    // UART data
    logic [8*MSG_BYTES-1:0] message;
    logic [8*KEY_BYTES-1:0] exponent;
    logic [8*KEY_BYTES-1:0] modulus;
    logic [8*KEY_BYTES-1:0] tx_data;

    // UART Receiver
    deserializer #(
        .MSG_BYTES(MSG_BYTES),
        .KEY_BYTES(KEY_BYTES),
        .BAUD_RATE(BAUD_RATE)
    ) receive (
        .clk_in(clk_in),
        .rst_in(rst_in),
        
        .valid_out(rx_valid),

        .rx_wire_in(rx_wire_in),
        
        .message_out(message),
        .exponent_out(exponent),
        .modulus_out(modulus)
    );

    // ExpMod block
    exponent_modulus #(
        .KEY_BYTES(KEY_BYTES),
        .MSG_BYTES(MSG_BYTES)
    ) expmod (
        .clk_in(clk_in),
        .rst_in(rst_in),

        .ready_in(expmod_ready),
        .busy_out(expmod_busy),
        .valid_out(expmod_valid),

        .value_in(message),
        .exponent_in(exponent),
        .modulus_in(modulus),

        .value_out(tx_data)
    );

    // UART Transmitter
    serializer #(
        .BYTES(KEY_BYTES),
        .BAUD_RATE(BAUD_RATE)
    ) transmit (
        .clk_in(clk_in),
        .rst_in(rst_in),

        .ready_in(tx_ready),
        .busy_out(tx_busy),

        .data_in(tx_data),
    
        .tx_wire_out(tx_wire_out)
    );

endmodule

`default_nettype wire