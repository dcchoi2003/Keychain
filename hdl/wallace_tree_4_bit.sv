`timescale 1ns / 1ps
`default_nettype none

module half_adder(input wire a,
                input wire b,
                output logic sum, 
                output logic carry);
        assign sum = a ^ b;
        assign carry = a & b;
endmodule

module full_adder(input wire a,
                input wire b,
                input logic cin,
                output logic sum,
                output logic carry);
        assign sum = a ^ b ^ cin;
        assign carry = (a & b) | (b & cin) | (a & cin);
endmodule
module wallace_tree_4_bit #(
    parameter NUMBITS = 4
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire [NUMBITS-1:0] input_1,
    input wire [NUMBITS-1:0] input_2,
    output logic output_ready,
    output logic [(NUMBITS*2)-1:0] product
    );
    // always_comb begin
    logic [3:0] s1;
    logic [3:0] s2;
    logic [3:0] s3;
    logic [3:0] s4; 
    // Step 1: Setup
    // assign s1 = (input_2[0] == 1) ? input_1 : (input_2[0] == 0) ? "0000" : 4'bx;
    assign s1 = (input_2[0] == 1) ? input_1 : 4'b0;
    assign s2 = (input_2[1] == 1) ? input_1 : 4'b0;
    assign s3 = (input_2[2] == 1) ? input_1 : 4'b0;
    assign s4 = (input_2[3] == 1) ? input_1 : 4'b0;
    // Step 2: First Iteration
    logic i1;
    logic i2;
    logic i3;
    logic c1;
    logic c2;
    logic c3;
    half_adder ha1 (.a(s1[2]),
                    .b(s2[1]),
                    .sum(i1),
                    .carry(c1));
    full_adder fa1 (.a(s2[2]),
                    .b(s3[1]),
                    .cin(s1[3]),
                    .sum(i2),
                    .carry(c2));
    full_adder fa2 (.a(s3[2]),
                    .b(s4[1]),
                    .cin(s2[3]),
                    .sum(i3),
                    .carry(c3));

    // Step 3: Second Iteration
    logic i2_1, c2_1, i2_2, c2_2, i2_3, c2_3;
    half_adder ha2 (.a(i2),
                    .b(c1),
                    .sum(i2_1),
                    .carry(c2_1));
    half_adder ha3 (.a(i3),
                    .b(c2),
                    .sum(i2_2),
                    .carry(c2_2));
    full_adder fa3 (.a(c3),
                    .b(s3[3]),
                    .cin(s4[2]),
                    .sum(i2_3),
                    .carry(c2_3));


    // Step 4: Add Up
    logic [5:0] x;
    logic [5:0] y;
    assign x = {s4[3],i2_3,i2_2,i2_1,i1,s1[1]};
    assign y = {c2_3,c2_2,c2_1,s4[0],s3[0],s2[0]};
    logic [6:0] test_sum;
    assign test_sum = x + y;
    assign product = {test_sum[6],test_sum[5],test_sum[4],test_sum[3],test_sum[2],test_sum[1],test_sum[0],s1[0]};
endmodule
`default_nettype wire