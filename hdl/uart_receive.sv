`timescale 1ns / 1ps
`default_nettype none

module uart_receive
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	       clk_in,
    input wire 	       rst_in,
    input wire 	       rx_wire_in,
    output logic       new_data_out,
    output logic [7:0] data_byte_out
    );

   // TODO: module to read UART rx wire

    localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;
    localparam HALF_BAUD = (BAUD_BIT_PERIOD) / 2;

    logic [7:0] receive_data;
    logic [4:0] num_cycles;
    logic [$clog2(BAUD_BIT_PERIOD)-1:0] period_count;
    typedef enum {IDLE, START, DATA, STOP, TRANSMIT} state_t;

    state_t current_state;

    always_ff @(posedge clk_in) begin
        
        if (rst_in) begin
            current_state <= IDLE;
        end

        if (current_state == IDLE) begin
            receive_data <= 0;
            num_cycles <= 0;
            period_count <= 0;
            new_data_out <= 0;
            if (rx_wire_in == 0) begin
                current_state <= START;
            end
        end

        else if (current_state == START) begin
            if (period_count == (HALF_BAUD)) begin
                if (rx_wire_in == 0) begin
                    current_state <= DATA;
                    period_count <= 0;
                end else begin
                    current_state <= IDLE;
                    // period_count <= 0;
                end
            end else begin
                period_count <= period_count + 1'b1;
            end
        end

        else if (current_state == DATA) begin
            if (period_count == BAUD_BIT_PERIOD-1) begin

                if (num_cycles == 4'h7) begin
                    // receive_data <= (receive_data << 1) + rx_wire_in;
                    receive_data <= receive_data + (rx_wire_in << num_cycles);
                    period_count <= 0;
                    current_state <= STOP;
                end else begin
                    // receive_data <= (receive_data << 1) + rx_wire_in;
                    receive_data <= receive_data + (rx_wire_in << num_cycles);
                    num_cycles <= num_cycles + 1'b1;
                    period_count <= 0;
                end

            end else begin
                period_count <= period_count + 1'b1;
            end
        end

        else if (current_state == STOP) begin
            if (period_count == BAUD_BIT_PERIOD-1) begin
                if (rx_wire_in == 1'b1) begin
                    current_state <= TRANSMIT;
                    // new_data_out <= 1'b1;
                end else begin
                    current_state <= IDLE;
                end
            end else begin
                period_count <= period_count + 1'b1;
            end
        end

        else if (current_state == TRANSMIT) begin
            new_data_out <= 1'b1;
            data_byte_out <= receive_data;
            current_state <= IDLE;
        end

    end


endmodule // uart_receive

`default_nettype wire