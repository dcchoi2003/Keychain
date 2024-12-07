`timescale 1ns / 1ps
`default_nettype none

module top_level
    (
    input wire          clk_100mhz,
    output logic [15:0] led,
    // inout wire          i2c_scl, // i2c inout clock
    // inout wire          i2c_sda, // i2c inout data
    input wire [15:0]   sw,
    input wire [3:0]    btn,
    output logic [2:0]  rgb0,
    output logic [2:0]  rgb1
    // seven segment
    // output logic [3:0]  ss0_an,//anode control for upper four digits of seven-seg display
    // output logic [3:0]  ss1_an,//anode control for lower four digits of seven-seg display
    // output logic [6:0]  ss0_c, //cathode controls for the segments of upper four digits
    // output logic [6:0]  ss1_c, //cathod controls for the segments of lower four digits
    );

    localparam WIDTH = 32;

    // shut up those RGBs
    assign rgb0 = 0;
    assign rgb1 = 0;

    // have btnd control system reset
    logic sys_rst;
    assign sys_rst = btn[0];

    // Ready, Busy, Valid signals
    logic expmod_ready, expmod_busy, expmod_valid;

    // Input and output signals
    logic [WIDTH-1:0] value, modulus, exponent, result;

    assign value = sw;

    exponent_modulus #(
        .WIDTH(WIDTH)
    ) expmod (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .ready_in(expmod_ready),
        .value_in(value),
        .modulus_in(modulus),
        .exponent_in(exponent),
        .value_out(result),
        .busy_out(expmod_busy),
        .valid_out(expmod_valid)
    );

    always_ff @(posedge clk_100mhz) begin

        if (sys_rst) begin
            modulus <= 0;
            exponent <= 0;
            expmod_ready <= 0;
        end else begin
            if (!expmod_busy && !expmod_valid) begin
                exponent <= 32'd72;
                modulus <= 32'd1073;
                expmod_ready <= 1;
            end else if (expmod_valid) begin
                led <= result;
            end
        end

        if (expmod_ready) expmod_ready <= 0;

    end

endmodule // top_level


`default_nettype wire