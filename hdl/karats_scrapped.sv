`timescale 1ns / 1ps
`default_nettype none

// https://github.com/JoeLopez333/WallaceTree - 64 bit

module karatsuba #(
    parameter NUMBITS = 4
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire [NUMBITS-1:0] input_1,
    input wire [NUMBITS-1:0] input_2,
    output logic output_ready,
    output logic [(NUMBITS*2)-1:0] product
    );

    if (input_1 < 10 || input_2 < 10) begin
        assign output_ready = input_1 * input_2;
    end else begin
        logic m_1;
        logic m_2;
        assign m_2 = m_1 << 1;

        logic high_1, low_1, high_2, low_2;
        assign high_1 = input_1[0:];
        assign low_1 = input_1[:];
        assign high_2 = input_2[0:];
        assign low_2 = input_2[:];

        
    end

    // if (num1 < 10 or num2 < 10)
    //     return num1 × num2 /* fall back to traditional multiplication */
    
    // /* Calculates the size of the numbers. */
    // m = max(size_base10(num1), size_base10(num2))
    // m2 = floor(m / 2) 
    // /* m2 = ceil (m / 2) will also work */
    
    // /* Split the digit sequences in the middle. */
    // high1, low1 = split_at(num1, m2)
    // high2, low2 = split_at(num2, m2)
    
    // /* 3 recursive calls made to numbers approximately half the size. */
    // z0 = karatsuba(low1, low2)
    // z1 = karatsuba(low1 + high1, low2 + high2)
    // z2 = karatsuba(high1, high2)
    
    // return (z2 × 10 ^ (m2 × 2)) + ((z1 - z2 - z0) × 10 ^ m2) + z0

endmodule

`default_nettype wire