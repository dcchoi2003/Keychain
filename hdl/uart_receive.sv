`timescale 1ns / 1ps
`default_nettype none

module uart_receive
    #(
        parameter INPUT_CLOCK_FREQ = 100_000_000,
        parameter BAUD_RATE = 9600,
        parameter WIDTH = 16
    )
    (
        input wire clk_in,
        input wire rst_in,
        input wire rx_wire_in,
        output logic valid_out,
        output logic [WIDTH-1:0] data_out
    );

    // Number of clock cycles per bit
    localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;

    // Half the bit period, used to sample the signal
    localparam HALF_BAUD = BAUD_BIT_PERIOD / 2;

    // Width of the bit period
    localparam PERIOD_WIDTH = $clog2(BAUD_BIT_PERIOD);

    // Width of the bit index
    localparam INDEX_WIDTH = $clog2(WIDTH);

    // Data to be received
    logic [WIDTH-1:0] receive_data;

    // Index of the current bit
    logic [INDEX_WIDTH-1:0] index;

    // How far along are we in this period?
    logic [PERIOD_WIDTH-1:0] count;

    // Define FSM
    typedef enum {IDLE, START, DATA, STOP, TRANSMIT} state_t;
    state_t state;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Reset
            state <= IDLE;
            receive_data <= 0;
            count <= 0;
            index <= 0;
            data_out <= 0;
            valid_out <= 1'b0;
        end else begin
            case (state)
                // Idle, wait for new data
                IDLE: begin
                    // Reset the block
                    receive_data <= 0;
                    count <= 0;
                    index <= 0;
                    data_out <= 0;
                    valid_out <= 1'b0;

                    // If we're receiving data, go to the START state
                    if (!rx_wire_in) begin
                        state <= START;
                    end
                end

                // Start, make sure the signal is low for half a period
                START: begin
                    if (count == HALF_BAUD) begin
                        if (!rx_wire_in) begin
                            // We are good to go!
                            state <= DATA;
                            count <= 0;
                        end else begin
                            // Invalid start bit
                            state <= IDLE;
                        end
                    end else begin
                        count <= count + 1;
                    end
                end

                // Receive data, one bit at a time
                DATA: begin
                    if (count == BAUD_BIT_PERIOD - 1) begin
                        receive_data[index] <= rx_wire_in;

                        // Reset the count
                        count <= 0;

                        // Are we done yet?
                        if (index == WIDTH - 1) begin
                            state <= STOP;
                        end else begin
                            index <= index + 1;
                        end
                    end else begin
                        count <= count + 1;
                    end
                end

                // Stop, make sure the signal is high for half a period
                STOP: begin
                    if (count == BAUD_BIT_PERIOD - 1) begin
                        if (rx_wire_in) begin
                            state <= TRANSMIT;
                        end else begin
                            // Invalid stop bit
                            state <= IDLE;
                        end
                    end else begin
                        count <= count + 1;
                    end
                end

                // Transmit data
                TRANSMIT: begin
                    valid_out <= 1'b1;
                    data_out <= receive_data;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule // uart_receive

`default_nettype wire