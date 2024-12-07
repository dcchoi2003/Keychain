`timescale 1ns / 1ps
`default_nettype none

module fast_adder #(
    parameter WIDTH = 1000
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire ready_in,
    input wire [WIDTH-1:0] value_1,
    input wire [WIDTH-1:0] value_2,
    output logic [WIDTH:0] sum
    );

    assign sum = value_1 + value_2;

endmodule

`default_nettype wire