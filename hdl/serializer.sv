`timescale 1ns / 1ps
`default_nettype none

module serializer (
    input wire clk_in,
    input wire rst_in,
    input wire inp,
    output logic line_out
    );

    always_ff @ (posedge clk_in) begin

        if (rst_in) begin
            
        end else begin

        end

    end

endmodule

`default_nettype wire