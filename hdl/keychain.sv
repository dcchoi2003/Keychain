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

    // UART width (bits)
    localparam UART_WIDTH = MSG_WIDTH + 2 * KEY_WIDTH;

    // UART control signals
    logic rx_valid, tx_ready, tx_busy;

    // ExpMod control signals
    logic expmod_busy, expmod_valid;

    // UART data
    logic [UART_WIDTH-1:0] rx_data;
    logic [KEY_WIDTH-1:0] tx_data;

    // UART Receiver
    deserializer #(
        .MSG_BYTES(MSG_BYTES),
        .KEY_BYTES(KEY_BYTES),
        .BAUD_RATE(BAUD_RATE),
    ) receive (
        
    );

    // ExpMod block
    exponent_modulus #(
        .KEY_WIDTH(KEY_WIDTH),
        .MSG_WIDTH(MSG_WIDTH)
    ) expmod (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .ready_in(rx_valid),
        .value_in(rx_data[MSG_WIDTH-1:0]),
        .exponent_in(rx_data[KEY_WIDTH+MSG_WIDTH-1:MSG_WIDTH]),
        .modulus_in(rx_data[UART_WIDTH-1:KEY_WIDTH+MSG_WIDTH]),
        .value_out(tx_data),
        .busy_out(expmod_busy),
        .valid_out(expmod_valid)
    );

    // UART Transmitter
    serializer #(
        .BYTES(KEY_BYTES)
        .BAUD_RATE(BAUD_RATE),
    ) transmit (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .ready_in(tx_ready),
        .data_in(tx_data),
        .busy_out(tx_busy),
        .tx_wire_out(tx_wire_out)
    );

endmodule

`default_nettype wire