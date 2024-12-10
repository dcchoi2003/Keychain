`timescale 1ns / 1ps
`default_nettype none

module keychain #(
    parameter KEY_WIDTH = 32,
    parameter MSG_WIDTH = 16,
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
    uart_receive #(
        .BAUD_RATE(BAUD_RATE),
        .WIDTH(UART_WIDTH)
    ) receive (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rx_wire_in(rx_wire_in),
        .valid_out(rx_valid),
        .data_out(rx_data)
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
    uart_transmit #(
        .BAUD_RATE(BAUD_RATE),
        .WIDTH(KEY_WIDTH)
    ) transmit (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .data_in(tx_data),
        .ready_in(expmod_valid),
        .busy_out(tx_busy),
        .tx_wire_out(tx_wire_out)
    );

endmodule

`default_nettype wire