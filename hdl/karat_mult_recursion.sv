`timescale 1ns / 1ps
`default_nettype none

module karat_mult_recursion #(
        parameter input_size = 1024,
        parameter output_size = 2 * input_size,
        parameter num_stages = 2
        // parameter num_stages = $clog2(input_size);
)
(
        // data IOs
        input   wire   [input_size-1:0]    input_1,
        input   wire   [input_size-1:0]    input_2,

        output  logic  [output_size-1:0]    result,

        // control IOs
        input   wire   clk_in,
        input   wire   rst_in,
        input   wire   ready_in,

        output  logic  busy_out,
        output  logic  ready_out
);

    localparam half_input_size = input_size / 2;

    logic   finish_p, finish_q, finish_ts;
    // logic   ready_p, ready_q, ready_ts;  // replace this with ready_in for all recursive modules?

    logic   [half_input_size-1:0] high_1, low_1;
    logic   [half_input_size-1:0] high_2, low_2;

    assign  {high_1, low_1} = input_1;
    assign  {high_2, low_2} = input_2;

    logic   [half_input_size*2-1:0]   p;
    logic   [half_input_size*2-1:0]   q;
    logic   [half_input_size:0]       r;
    logic   [half_input_size:0]       s;

    assign  r = high_1 + low_1;
    assign  s = high_2 + low_2;

    logic   [half_input_size*2:0]     u;
    assign  u = p + q;

    logic   [input_size+1:0]        t;
    logic   r_hi, s_hi;
    logic   [half_input_size-1:0]     r_lo, s_lo;

    assign  {r_hi, r_lo} = r;
    assign  {s_hi, s_lo} = s;

    logic   [input_size-1:0]        t_s;

    typedef enum {AWAITING, MULTIPLYING, FINISHING} state_t;

    state_t current_state;

    generate
        if (num_stages != 1) begin: p_recursive
    karat_mult_recursion #(
            .input_size     (half_input_size),
            .num_stages     (num_stages-1)
        )
        karat_mult_recursion_p (
            .input_1        (high_1),
            .input_2        (high_2),
            .result         (p),
            .clk_in         (clk_in),
            .rst_in         (rst_in),
            .ready_in       (ready_in), // use ready_p instead?
            .ready_out      (finish_p)
        );
        end
    endgenerate

    generate
        if (num_stages != 1) begin: q_recursive
    karat_mult_recursion #(
            .input_size     (half_input_size),
            .num_stages     (num_stages-1)
        )
        karat_mult_recursion_q (
            .input_1        (low_1),
            .input_2        (low_2),
            .result         (q),
            .clk_in         (clk_in),
            .rst_in         (rst_in),
            .ready_in       (ready_in), // use ready_q instead?
            .ready_out      (finish_q)
        );
        end
    endgenerate

    generate
        if (num_stages != 1) begin: ts_recursive
    karat_mult_recursion #(
            .input_size     (half_input_size),
            .num_stages     (num_stages-1)
        )
        karat_mult_recursion_ts (
            .input_1        (r_lo),
            .input_2        (s_lo),
            .result         (t_s),
            .clk_in         (clk_in),
            .rst_in         (rst_in),
            .ready_in       (ready_in), // use ready_ts instead?
            .ready_out      (finish_ts)
        );
        end
    endgenerate


always_ff @(posedge clk_in)
    if(rst_in) begin
    
        ready_out <= 1'b0;
        busy_out <= 1'b0;
        result <= 0;
        current_state <= AWAITING;
    
    end else begin

        case (current_state) AWAITING: begin

            ready_out <= 1'b0;
            result <= 0;

            if (ready_in == 1'b1) begin
                current_state <= MULTIPLYING;
                busy_out <= 1'b1;
            end

        end

        MULTIPLYING: begin
            if (num_stages <= 1) begin

                // ready_p <= 1'b0;
                // ready_q <= 1'b0;
                // ready_ts <= 1'b0;

                p <= high_1 * high_2;
                // finish_p <= 1'b1;

                q <= low_1 * low_2;
                // finish_q <= 1'b1;

                t_s <= r_lo * s_lo;
                // finish_ts <= 1'b1;

                t <= ((r_hi & s_hi) << input_size) + ((r_hi * s_lo + s_hi * r_lo) << half_input_size) + t_s;
                result <= (p << input_size) + ((t - u) << half_input_size) + q;
                ready_out <= 1'b1;
                busy_out <= 1'b0;
                current_state <= AWAITING;

            end else begin

                if (finish_p && finish_q && finish_ts) begin

                    t <= ((r_hi & s_hi) << input_size) + ((r_hi * s_lo + s_hi * r_lo) << half_input_size) + t_s;
                    result <= (p << input_size) + ((t - u) << half_input_size) + q;
                    ready_out <= 1'b1;
                    busy_out <= 1'b0;
                    current_state <= AWAITING;

                end

            end

        end

        default: begin
            ready_out <= 1'b0;
            busy_out <= 1'b0;
            current_state <= AWAITING;
        end

        endcase

    end

endmodule

`default_nettype wire