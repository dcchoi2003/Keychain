`timescale 1ns / 1ps
`default_nettype none

module exponent_modulus #(
    parameter WIDTH = 16
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire ready_in,
    input wire [WIDTH-1:0] value_in,
    input wire [WIDTH-1:0] modulus_in,
    input wire [WIDTH-1:0] exponent_in,
    output logic [2*WIDTH-1:0] value_out,
    output logic busy_out,
    output logic valid_out
    );

    // Width of the exponent
    localparam DEPTH = WIDTH;

    // Width of the active index
    localparam INDEX_WIDTH = $clog2(DEPTH);

    // Intermediate results
    logic [DEPTH-1:0][WIDTH-1:0] intermediate;

    // Busy signal value during the last clock cycle
    logic last_busy;

    // Combinationally assign valid signal from busy signal
    assign valid_out = last_busy && !busy_out;

    // Squaring block control signals
    logic square_ready, square_busy, square_valid;

    // Squaring block input and output registers
    logic [WIDTH-1:0] square_input, square_output;

    // Modulus block control signals
    logic modulus_ready, modulus_busy, modulus_valid;

    // Modulus result
    logic [WIDTH-1:0] modulus_result;

    // Active index in intermediate results array
    logic [INDEX_WIDTH-1:0] index;

    // Running total of output
    logic [2*WIDTH-1:0] running_total;

    // State of FSM
    // 
    // Idle:   00
    // Square: 01
    // Add:    10
    // Return: 11
    logic [1:0] state;

    // Squaring block
    square #(
        .WIDTH(WIDTH)
    ) square_block (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .ready_in(square_ready),
        .value_in(square_input),
        .modulus_in(modulus_in),
        .square_out(square_output),
        .busy_out(square_busy),
        .valid_out(square_valid)
    );

    // Modulus block
    modulus #(
        .WIDTH(WIDTH)
    ) modulus_block (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .ready_in(modulus_ready),
        .value_in(running_total),
        .modulus_in(modulus_in),
        .value_out(modulus_result),
        .busy_out(modulus_busy),
        .valid_out(modulus_valid)
    );

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Reset the block
            intermediate <= 0;
            busy_out <= 1'b0;
            square_ready <= 1'b0;
            last_busy <= 1'b0;
            state <= 2'b00;
            running_total <= 1;
            square_input <= 0;
            index <= 0;
            value_out <= 0;
            modulus_ready <= 1'b0;
        end else begin
            case (state)
                // Idle
                2'b00: begin
                    if (ready_in) begin
                        // We're busy
                        busy_out <= 1'b1;

                        // Load the initial value into the
                        // intermediate register
                        intermediate[0] <= value_in;

                        // Switch to squaring state
                        state <= 2'b01;
                    end
                end

                // Square
                2'b01: begin
                    if (!square_valid && !square_busy) begin
                        // Load input into squaring block
                        square_input <= intermediate[index];

                        // Trigger squaring block
                        square_ready <= 1'b1;
                    end else if (square_valid) begin
                        // Store squared result
                        intermediate[index + 1] <= square_output;

                        // Check if we're done
                        if (index == DEPTH - 2 || exponent_in <= (1 << (index + 1))) begin
                            // Switch to adding state
                            state <= 2'b10;

                            // Reset the index
                            index <= 0;
                        end else begin
                            // We're not done yet

                            // Increment the index
                            index <= index + 1;
                        end
                    end
                end

                // Add
                2'b10: begin
                    // Compute contribution from this index
                    if (exponent_in[index]) begin
                        running_total <= running_total * intermediate[index];
                    end

                    // Check if we're done
                    if (index == DEPTH - 1) begin
                        // We've already loaded everything into the modulus block

                        // Trigger the modulus block
                        modulus_ready <= 1'b1;

                        // Switch to returning state
                        state <= 2'b11;
                    end else begin
                        // We're not done yet

                        // Increment the index
                        index <= index + 1;
                    end
                end

                // Return
                2'b11: begin
                    if (modulus_valid) begin
                        // We're no longer busy
                        busy_out <= 1'b0;

                        // Load result
                        value_out <= modulus_result;

                        // Reset running total
                        running_total <= 1;

                        // Reset intermediate
                        intermediate <= 0;

                        // Reset index
                        index <= 0;

                        // Switch to idle state
                        state <= 2'b00;
                    end
                end

                // default unnecessary as we've covered every possibility
            endcase
        end

        // Update LASTBUSY register
        last_busy <= busy_out;

        // Square block trigger is one-cycle high only
        if (square_ready) begin
            square_ready <= 1'b0;
        end

        // Modulus block trigger is one-cycle high only
        if (modulus_ready) begin
            modulus_ready <= 1'b0;
        end
    end

endmodule

`default_nettype wire