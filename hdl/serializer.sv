`timescale 1ns / 1ps
`default_nettype none

module serializer #(
    parameter BYTES = 4,
    parameter BAUD_RATE = 9600,
    parameter INPUT_CLOCK_FREQ = 100_000_000
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire ready_in,
    input wire [8*BYTES-1:0] data_in,
    output logic busy_out,
    output logic tx_wire_out
    );

    // Previous BUSY signal from UART
    logic last_uart_busy;

    // Delay between bytes (cycles)
    // localparam DELAY = 100;

    // Index width
    localparam INDEX_WIDTH = $clog2(BYTES+1);

    // Index
    logic [INDEX_WIDTH-1:0] index;

    // Current state
    logic state;

    // Data to be sent
    logic [8*BYTES-1:0] data;
    
    // UART Transmitter control signals
    logic uart_ready, uart_busy;

    // Active byte
    logic [7:0] active_byte;

    // Index increment signal
    logic increment;
    assign increment = last_uart_busy && !uart_busy;

    // UART Transmitter
    uart_transmit #(
        .BAUD_RATE(BAUD_RATE),
        .INPUT_CLOCK_FREQ(INPUT_CLOCK_FREQ)
    ) transmitter (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .ready_in(uart_ready),
        .data_in(active_byte),
        .busy_out(uart_busy),
        .tx_wire_out(tx_wire_out)
    );
    
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            active_byte <= 8'b0;
            uart_ready <= 1'b0;
            data <= 0;
            state <= 1'b0;
            last_uart_busy <= 1'b0;
            index <= 0;
        end else begin
            // Update LASTBUSY register
            last_uart_busy <= uart_busy;

            // Idle state, wait for ready signal
            if (!state) begin
                if (ready_in) begin
                    // We're busy
                    busy_out <= 1'b1;

                    // Save input data
                    data <= data_in;

                    // Move to transmitting state
                    state <= 1'b1;
                end
            end

            // Transmitting state, send each byte in series
            else begin
                if (increment) begin
                    // Falling edge of BUSY... are we done?
                    if (index == BYTES - 1) begin
                        // We're done!
                        state <= 1'b0;

                        // Reset
                        active_byte <= 8'b0;
                        uart_ready <= 1'b0;
                        data <= 0;
                        state <= 1'b0;
                        last_uart_busy <= 1'b0;
                        index <= 0;
                    end else begin
                        // Not done yet!
                        index <= index + 1;
                    end
                end else if (!uart_busy) begin
                    // Load the active byte
                    active_byte[7] <= data[8*index + 7];
                    active_byte[6] <= data[8*index + 6];
                    active_byte[5] <= data[8*index + 5];
                    active_byte[4] <= data[8*index + 4];
                    active_byte[3] <= data[8*index + 3];
                    active_byte[2] <= data[8*index + 2];
                    active_byte[1] <= data[8*index + 1];
                    active_byte[0] <= data[8*index];

                    // Trigger the UART transmission
                    uart_ready <= 1'b1;
                end
            end

            // READY signal is one-cycle high
            if (uart_ready) begin
                uart_ready <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire