`timescale 1ns / 1ps
`default_nettype none

module encoder (
    input wire clk_in,
    input wire rst_in,
    input wire [10:0] message,
    input wire [10:0] public_key,
    input wire [10:0] modulus,
    input wire mux,
    output logic [10:0] line_out
    );


    // use N = 14, public key = 5, private key = 11


    logic [40:0] exponent;
    logic [10:0] private_key;
    assign private_key = 11;

    always_ff @ (posedge clk_in) begin

        if (rst_in) begin
            
        // mux = 0 -> encode, mux = 1 -> decode
        end else if (mux) begin
            
            exponent <= message ** public_key;
            line_out <= exponent % modulus;

        end else begin

            // read private key from BRAM

            exponent <= message ** private_key;
            line_out <= exponent % modulus;

        end

    end

endmodule

`default_nettype wire