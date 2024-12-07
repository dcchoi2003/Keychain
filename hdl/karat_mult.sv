`timescale 1ns / 1ps
`default_nettype none

module karat_mult #(
parameter size_in = 64,
parameter size_out = 2 * size_in
)
(
input logic [size_in-1:0] input_1,
input logic [size_in-1:0] input_2,
output logic [size_out-1:0] output
);

localparam split = size_in / 2;

logic [split-1:0] high_1, low_1;
logic [split-1:0] high_2, low_2;

assign {high_1, low_1} = input_1;
assign {high_2, low_2} = input_2;

// split*2 - 1 = size_in - 1
logic [split*2-1:0] p;
logic [split*2-1:0] q;

logic [split:0] r;
logic [split:0] s;

assign p = high_1 * high_2;
assign q = low_1 * low_2;
assign r = high_1 + low_1;
assign s = high_2 + low_2;

// high_1 * high_2 + low_1 * low_2
logic [split*2:0] u;
assign u = p + q;

logic [size_in+1:0] t;
logic r_high, s_high;
logic [split-1:0] r_low, s_low;

assign {r_high, r_low} = r;
assign {s_high, s_low} = s;

logic [size_in-1:0] t_s;

assign t_s = r_low * s_low;
assign t = ((r_high & s_high) << size_in) + ((r_high * s_low + s_high * r_low) << split) + t_s;

assign output = (p << size_in) + ((t - u) << split) + q;

endmodule

`default_nettype wire