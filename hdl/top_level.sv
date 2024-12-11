`timescale 1ns / 1ps
`default_nettype none

module top_level (
    // 100 MHz system clock
    input wire          clk_100mhz,

    // LEDs
    output logic [15:0] led,

    // Buttons (SYSRST)
    input wire [3:0]    btn,

    // RGB LEDs
    output logic [2:0]  rgb0,
    output logic [2:0]  rgb1,

    // Seven-segment display
    // output logic [3:0]  ss0_an, // Anode control for upper four digits
    // output logic [3:0]  ss1_an, // Anode control for lower four digits
    // output logic [6:0]  ss0_c,  // Cathode control for the segments of upper four digits
    // output logic [6:0]  ss1_c,  // Cathode control for the segments of lower four digits

    input wire      uart_rxd, // UART RX: computer --> FPGA
	output logic    uart_txd  // UART TX: FPGA     --> computer
    );

    // Shut off RGB LEDs
    assign rgb0 = 0;
    assign rgb1 = 0;

    // SYSRST signal
    logic sys_rst;
    assign sys_rst = btn[0];

    // Hook up LEDs
    always_ff @(posedge clk_100mhz) begin
        if (sys_rst) begin
            led <= 16'b1;
        end else begin
            led <= 16'b0;
        end
    end

    // Hook up Keychain
    keychain #(
        .KEY_BYTES(4),
        .MSG_BYTES(2),
        .BAUD_RATE(115_200)
    ) keychain (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .rx_wire_in(uart_rxd),
        .tx_wire_out(uart_txd)
    );
endmodule // top_level


`default_nettype wire