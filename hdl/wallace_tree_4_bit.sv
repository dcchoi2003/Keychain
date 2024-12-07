`timescale 1ns / 1ps
`default_nettype none

// https://github.com/JoeLopez333/WallaceTree - 64 bit


// 6-bit_Carry_lookahead_adder_module
module cla(
        input [5:0] x,
        input [5:0] y,
        output [5:0] sum,
        output carry);

    //carry generation
    logic g0;
    logic g1;
    logic g2;
    logic g3;
    logic g4;
    logic g5;
    assign g0 = x[0] & y[0];
    assign g1 = x[1] & y[1];
    assign g2 = x[2] & y[2];
    assign g3 = x[3] & y[3];
    assign g4 = x[4] & y[4];
    assign g5 = x[5] & y[5];

    //carry propagation
    logic p0;
    logic p1;
    logic p2;
    logic p3;
    logic p4;
    logic p5;
    assign p0 = x[0] ^ y[0];
    assign p1 = x[1] ^ y[1];
    assign p2 = x[2] ^ y[2];
    assign p3 = x[3] ^ y[3];
    assign p4 = x[4] ^ y[4];
    assign p5 = x[5] ^ y[5];

    //intermidiated carries
    logic c0,c1,c2,c3,c4;
    assign c0 = g0;
    assign c1 = g1 | p1 & c0;
    assign c2 = g2 | p2 & c1;
    assign c3 = g3 | p3 & c2;
    assign c4 = g4 | p4 & c3;
    
    //carry out (final carry)

    assign carry = g5 | p5 & c4;

    //sum
    assign sum[0] = p0 ^ c0;
    assign sum[1] = p1 ^ c1;
    assign sum[2] = p2 ^ c2;
    assign sum[3] = p3 ^ c3;
    assign sum[4] = p4 ^ c4;
    assign sum[5] = p5 ^ carry;

endmodule

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
    // assign s1 = (input_2[0] == 1) ? input_1 : (input_2[0] == 0) ? "0000" : 4'bx;
    assign s1 = (input_2[0] == 1) ? input_1 : 4'b0;
    assign s2 = (input_2[1] == 1) ? input_1 : 4'b0;
    assign s3 = (input_2[2] == 1) ? input_1 : 4'b0;
    assign s4 = (input_2[3] == 1) ? input_1 : 4'b0;

    //step_2(first iteration)

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

    // half_adder ha1(i1,c1,s1[2],s2[1]);
    // full_adder fa1(i2,c2,s1[3],s2[2],s3[1]);
    // full_adder fa2(i3,c3,s2[3],s3[2],s4[1]);


    //step_3(second iteration)

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

    // half_adder ha2(i11,c11,c1,i2);
    // half_adder fa3(i22,c22,c2,i3);
    // full_adder fa4(i33,c33,c3,s3[3],s4[2]);



    logic [5:0] x;
    logic [5:0] y;
    assign x = {s4[3],i2_3,i2_2,i2_1,i1,s1[1]};
    assign y = {c2_3,c2_2,c2_1,s4[0],s3[0],s2[0]};

    logic [5:0] sum;
    logic carry;

    // cla cla1(
    //     .x(x),
    //     .y(y),
    //     .sum(sum),
    //     .carry(carry)
    // );

    // assign product = {carry,sum[5],sum[4],sum[3],sum[2],sum[1],sum[0],s1[0]};

    logic [6:0] test_sum;
    assign test_sum = x + y;

    assign product = {test_sum[6],test_sum[5],test_sum[4],test_sum[3],test_sum[2],test_sum[1],test_sum[0],s1[0]};

endmodule

`default_nettype wire