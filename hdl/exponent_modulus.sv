`timescale 1ns / 1ps
`default_nettype none

module exponent_modulus #(
    parameter MSG_WIDTH = 8,
    parameter KEY_WIDTH = 16
    ) (
    input wire clk_in,
    input wire rst_in,
    input wire ready_in,
    input wire [MSG_WIDTH-1:0] value_in,
    input wire [KEY_WIDTH-1:0] modulus_in,
    input wire [KEY_WIDTH-1:0] exponent_in,
    output logic [KEY_WIDTH-1:0] value_out,
    output logic busy_out,
    output logic valid_out
    );

    // Width of the exponent
    localparam DEPTH = KEY_WIDTH;

    // Width of the active index
    localparam IDX_WIDTH = $clog2(DEPTH);

    // Intermediate results
    logic [DEPTH-1:0][KEY_WIDTH-1:0] intermediate;

    // Busy signal value during the last clock cycle
    logic last_busy;

    // Combinationally assign valid signal from busy signal
    assign valid_out = last_busy && !busy_out;

    // Multiplier block input and output registers
    logic [KEY_WIDTH-1:0] mult_input_1, mult_input_2;
    logic [2*KEY_WIDTH-1:0] mult_output;

    // Multiplier block control signals
    logic mult_ready, mult_busy, mult_valid;

    // Modulus block control signals
    logic modulus_ready, modulus_busy, modulus_valid;

    // Modulus block result
    logic [KEY_WIDTH-1:0] modulus_result;

    // Active index in intermediate results array
    logic [IDX_WIDTH-1:0] index;

    // Running total of output
    logic [KEY_WIDTH-1:0] running_total;
    
    // Modulus value input
    logic [2*KEY_WIDTH-1:0] modulus_input;

    // State of FSM
    // 
    // Idle:   000 (also return)
    // Square: 001
    // Mod:    010
    // Mult:   011
    // Mod:    100
    logic [2:0] state;

    // Modulus block
    modulus #(
        .WIDTH(KEY_WIDTH)
    ) modulus_block (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .ready_in(modulus_ready),
        .value_in(modulus_input),
        .modulus_in(modulus_in),
        .value_out(modulus_result),
        .busy_out(modulus_busy),
        .valid_out(modulus_valid)
    );

    // Hardware multiplier
    simple_mult #(
        .INPUT_SIZE(KEY_WIDTH)
    ) multiplier (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .ready_in(mult_ready),
        .busy_out(mult_busy),
        .valid_out(mult_valid),
        .input_1(mult_input_1),
        .input_2(mult_input_2),
        .result(mult_output)
    );

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // Reset the block
            intermediate <= 0;
            busy_out <= 1'b0;
            last_busy <= 1'b0;
            state <= 2'b00;
            running_total <= 1;
            index <= 0;
            value_out <= 0;
            modulus_ready <= 1'b0;
            mult_ready <= 1'b0;
            mult_input_1 <= 0;
            mult_input_2 <= 0;
            modulus_input <= 0;
        end else begin
            case (state)
                // Idle
                3'b000: begin
                    // See if we're returning
                    if (busy_out) begin
                        // We're no longer busy
                        busy_out <= 1'b0;

                        // Load result
                        value_out <= exponent_in == 0 ? 1 : modulus_result;

                        // Reset running total
                        running_total <= 1;

                        // Reset intermediate & modulus input
                        intermediate <= 0;
                        modulus_input <= 0;

                        // Reset index
                        index <= 0;
                    end else if (ready_in) begin
                        // We're busy
                        busy_out <= 1'b1;

                        // Load the initial value into the
                        // intermediate register
                        intermediate[0] <= value_in;

                        // Switch to squaring state
                        state <= 3'b001;
                    end
                end

                // Square
                3'b001: begin
                    if (!mult_busy && !mult_valid) begin
                        // Load inputs to multiplier block
                        mult_input_1 <= intermediate[index];
                        mult_input_2 <= intermediate[index];

                        // Trigger multiplier block
                        mult_ready <= 1'b1;
                    end else if (mult_valid) begin
                        // Output running total
                        modulus_input <= mult_output;

                        // Calculate modulus to prevent overflow

                        // Switch to square-modulus state
                        state <= 3'b010;
                    end
                end

                // Square Modulus
                3'b010: begin
                    if (!modulus_busy && !modulus_valid) begin
                        // Trigger the modulus block
                        modulus_ready <= 1'b1;
                    end else if (modulus_valid) begin
                        // Update the running product
                        intermediate[index + 1] <= modulus_result;

                        // Check if we're done
                        if (index == DEPTH - 2 || exponent_in <= (1 << (index + 1))) begin
                            // Switch to multiplying state
                            state <= 3'b011;

                            // Reset the index
                            index <= 0;
                        end else begin
                            // We're not done yet

                            // Increment the index
                            index <= index + 1;

                            // Switch to squaring state
                            state <= 3'b001;
                        end
                    end
                end

                // Multiply
                3'b011: begin
                    // Compute contribution from this index
                    if (exponent_in[index]) begin
                        if (!mult_busy && !mult_valid) begin
                            // Load inputs to multiplier block
                            mult_input_1 <= running_total;
                            mult_input_2 <= intermediate[index];

                            // Trigger multiplier block
                            mult_ready <= 1'b1;
                        end else if (mult_valid) begin
                            // Output running total
                            modulus_input <= mult_output;

                            // Calculate modulus to prevent overflow

                            // Switch to mult-modulus state
                            state <= 3'b100;
                        end                        
                    end else begin
                        // Check if we're done
                        if (index == DEPTH - 1) begin
                            // Switch to idle/returning state
                            state <= 3'b000;
                        end else begin
                            // Go to the next index
                            index <= index + 1;
                        end
                    end                    
                end

                // Multiply Modulus
                3'b100: begin
                    if (!modulus_busy && !modulus_valid) begin
                        // Trigger the modulus block
                        modulus_ready <= 1'b1;
                    end else if (modulus_valid) begin
                        // Update the running product
                        running_total <= modulus_result;

                        // Check if we're done
                        if (index == DEPTH - 1) begin
                            // Switch to idle/returning state
                            state <= 3'b000;
                        end else begin
                            // Go to the next index
                            index <= index + 1;

                            // Switch to the multiplier state
                            state <= 3'b011;
                        end
                    end
                end

                // default unnecessary as we've covered every possibility
            endcase
        end

        // Update LASTBUSY register
        last_busy <= busy_out;

        // Modulus block trigger is one-cycle high only
        if (modulus_ready) begin
            modulus_ready <= 1'b0;
        end

        // Multiplier block trigger is one-cycle high only
        if (mult_ready) begin
            mult_ready <= 1'b0;
        end
    end

endmodule

`default_nettype wire