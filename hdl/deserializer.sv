`timescale 1ns / 1ps
`default_nettype none

module deserializer #(
    parameter MSG_BYTES = 2,
    parameter KEY_BYTES = 4,
    parameter BAUD_RATE = 9600,
    parameter INPUT_CLOCK_FREQ = 100_000_000
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire rx_wire_in,
    output logic valid_out,
    output logic [8*BYTES-1:0] data_out
    );

    // Total bytes
    localparam BYTES = MSG_BYTES + 2 * KEY_BYTES;

    // Index width
    localparam INDEX_WIDTH = $clog2(BYTES);

    // Index
    logic [INDEX_WIDTH-1:0] index;

    // Active byte
    logic [7:0] active_byte;

    // Output data
    logic [8*BYTES-1:0] data;

    // State
    logic state;

    // UART Receiver control signal
    logic uart_valid;

    // UART Receiver
    uart_receive #(
        .BAUD_RATE(BAUD_RATE),
        .INPUT_CLOCK_FREQ(INPUT_CLOCK_FREQ)
    ) receiver (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rx_wire_in(rx_wire_in),
        .valid_out(uart_valid),
        .data_out(active_byte)
    );

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Reset the deserializer
            data_out <= 0;
            data <= 0;
            valid_out <= 1'b0;
            state <= 1'b0;
            index <= 0;
        end else begin
            if (!state) begin
                // Accumulate

                // We received a byte from the UART RX!
                if (uart_valid) begin
                    // Receive byte into data array
                    data[8*index + 7] <= active_byte[7];
                    data[8*index + 6] <= active_byte[6];
                    data[8*index + 5] <= active_byte[5];
                    data[8*index + 4] <= active_byte[4];
                    data[8*index + 3] <= active_byte[3];
                    data[8*index + 2] <= active_byte[2];
                    data[8*index + 1] <= active_byte[1];
                    data[8*index]     <= active_byte[0];

                    // Are we done?
                    if (index == BYTES - 1) begin
                        // We're done!
                        state <= 1'b1;
                    end else begin
                        // Not done yet!
                        index <= index + 1;
                    end
                end
            end else begin
                // Send our result
                data_out <= data;

                // Send a valid signal
                valid_out <= 1'b1;

                // Reset our state
                state <= 1'b0;

                // Reset our data buffer
                data <= 0;

                // Reset the index
                index <= 0;
            end
        end

        // VALID signal is one-cycle high
        if (valid_out) begin
            valid_out <= 1'b0;
        end
    end

endmodule

`default_nettype wire