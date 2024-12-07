`timescale 1ns / 1ps
`default_nettype none

module uart_transmit 
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	     clk_in,
    input wire 	     rst_in,
    input wire [7:0] data_byte_in,
    input wire 	     trigger_in,
    output logic     busy_out,
    output logic     tx_wire_out
    );
   
   // TODO: module to transmit on UART

   localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;

    logic [7:0] send_data;
    logic [4:0] num_cycles;
    logic [$clog2(BAUD_BIT_PERIOD)-1:0] period_count;
    logic [2:0] step;

  always_ff @(posedge clk_in) begin
        if (rst_in) begin
            busy_out <= 0;
            tx_wire_out <= 1'b1;
        end

        if (trigger_in && ~busy_out) begin
            busy_out <= 1'b1;
            tx_wire_out <= 1'b0;
            period_count <= 0;
            num_cycles <= 0;
            send_data <= data_byte_in;
            step <= 2'b01;
        end

        else if (step == 2'b01) begin

            if (period_count == BAUD_BIT_PERIOD) begin

                if (num_cycles == 4'h8) begin
                    step <= 2'b10;
                    tx_wire_out <= 1'b1;
                    period_count <= 0;
                
                end else begin

                    period_count <= 0;
                    num_cycles <= num_cycles + 1'b1;
                    tx_wire_out <= send_data[0];
                    send_data <= send_data >> 1;

                end

            end else begin
                period_count <= period_count + 1'b1;
            end
        end

        else if (step == 2'b10) begin
            if (period_count == BAUD_BIT_PERIOD) begin
                step <= 0;
                busy_out <= 0;
            end else begin
                period_count <= period_count + 1'b1;
            end
        end

    end
   
endmodule // uart_transmit

`default_nettype wire