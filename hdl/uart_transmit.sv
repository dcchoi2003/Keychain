`timescale 1ns / 1ps
`default_nettype none

module uart_transmit
    #(
        parameter INPUT_CLOCK_FREQ = 100_000_000,
        parameter BAUD_RATE = 9600
    )
    (
        input wire clk_in,
        input wire rst_in,
        input wire ready_in,
        input wire [7:0] data_in,
        output logic busy_out,
        output logic tx_wire_out
    );

    // Number of clock cycles per bit
    localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;

    // Width of the bit period
    localparam PERIOD_WIDTH = $clog2(2*BAUD_BIT_PERIOD);

    // Data to be transmitted
    logic [7:0] transmit_data;

    // Index of the current bit
    logic [2:0] index;

    // How far along are we in this period?
    logic [PERIOD_WIDTH-1:0] count;

    // Define FSM
    typedef enum {IDLE, START, DATA, STOP} state_t;
    state_t state;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Reset
            state <= IDLE;
            transmit_data <= 8'b0;
            count <= 0;
            index <= 0;
            tx_wire_out <= 1'b1;
            busy_out <= 1'b0;
        end else begin
            case (state)
                // Idle, wait for new data
                IDLE: begin
                    // If we're receiving data, go to the START state
                    if (ready_in) begin
                        // We're busy!
                        busy_out <= 1'b1;

                        // Save input data
                        transmit_data <= data_in;

                        state <= START;
                    end
                end

                // Start, send a start bit
                START: begin
                    if (count == BAUD_BIT_PERIOD - 1) begin
                        // Reset the count and begin sending data
                        state <= DATA;
                        count <= 0;
                    end else begin
                        count <= count + 1;
                        tx_wire_out <= 1'b0;
                    end
                end

                // Transmit data, one bit at a time
                DATA: begin
                    if (count == BAUD_BIT_PERIOD - 1) begin
                        // Reset the count
                        count <= 0;

                        // Are we done yet?
                        if (index == 7) begin
                            state <= STOP;
                        end else begin
                            index <= index + 1;
                        end
                    end else begin
                        count <= count + 1;
                        tx_wire_out <= transmit_data[index];
                    end
                end

                // Stop, send a stop bit
                STOP: begin
                    if (count == 2*BAUD_BIT_PERIOD - 1) begin
                        // All done!
                        state <= IDLE;

                        // Reset the block
                        transmit_data <= 8'b0;
                        count <= 0;
                        index <= 0;
                        tx_wire_out <= 1'b1;
                        busy_out <= 1'b0;
                    end else begin
                        count <= count + 1;
                        tx_wire_out <= 1'b1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule // uart_transmit

`default_nettype wire