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
    output logic [WIDTH-1:0] value_out,
    output logic busy_out,
    output logic valid_out
    );

    // Width of the exponent
    localparam DEPTH = WIDTH;

    // Depth of the Karatsuba multiplier
    localparam STAGES = $clog2(WIDTH);

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

    // Karatsuba block input and output registers
    logic [WIDTH-1:0] karat_input_1, karat_input_2;
    logic [2*WIDTH-1:0] karat_output;

    // Karatsuba block control signals
    logic karat_ready, karat_busy, karat_valid;

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
    // Idle:   00 (also return)
    // Square: 01
    // Mult:   10
    // Mod:    11
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

    // Hardware multiplier
    simple_mult #(
        .INPUT_SIZE(WIDTH)
    ) multiplier (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .ready_in(karat_ready),
        .busy_out(karat_busy),
        .valid_out(karat_valid),
        .input_1(karat_input_1),
        .input_2(karat_input_2),
        .result(karat_output)
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
            karat_ready <= 1'b0;
            karat_input_1 <= 0;
            karat_input_2 <= 0;
        end else begin
            case (state)
                // Idle
                2'b00: begin
                    // See if we're returning
                    if (busy_out) begin
                        // We're no longer busy
                        busy_out <= 1'b0;

                        // Load result
                        value_out <= exponent_in == 0 ? 1 : modulus_result;

                        // Reset running total
                        running_total <= 1;

                        // Reset intermediate
                        intermediate <= 0;

                        // Reset index
                        index <= 0;

                        // Switch to idle state
                        state <= 2'b00;
                    end else if (ready_in) begin
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

                // Multiply
                2'b10: begin
                    // Compute contribution from this index
                    if (exponent_in[index]) begin
                        if (!karat_busy && !karat_valid) begin
                            // Load inputs to Karatsuba block
                            karat_input_1 <= running_total;
                            karat_input_2 <= intermediate[index];

                            // Trigger Karatsuba block
                            karat_ready <= 1'b1;
                        end else if (karat_valid) begin
                            // Output running total
                            running_total <= karat_output;

                            // Calculate modulus to prevent overflow

                            // Switch to modulus state
                            state <= 2'b11;
                        end                        
                    end else begin
                        // Check if we're done
                        if (index == DEPTH - 1) begin
                            // Switch to idle/returning state
                            state <= 2'b00;
                        end else begin
                            // Go to the next index
                            index <= index + 1;
                        end
                    end                    
                end

                // Modulus
                2'b11: begin
                    if (!modulus_busy && !modulus_valid) begin
                        // Trigger the modulus block
                        modulus_ready <= 1'b1;
                    end else if (modulus_valid) begin
                        // Update the running product
                        running_total <= modulus_result;

                        // Check if we're done
                        if (index == DEPTH - 1) begin
                            // Switch to idle/returning state
                            state <= 2'b00;
                        end else begin
                            // Go to the next index
                            index <= index + 1;

                            // Switch to the multiplier state
                            state <= 2'b10;
                        end
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

        // Karatsuba block trigger is one-cycle high only
        if (karat_ready) begin
            karat_ready <= 1'b0;
        end
    end

endmodule

`default_nettype wire