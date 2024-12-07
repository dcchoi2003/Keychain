`timescale 1ns / 1ps
`default_nettype none

module karat_mult_recursion #(
parameter input_size = 1024,
parameter output_size = 2 * input_size,
parameter num_stages = 8
)
(
// data IOs
input   wire   [input_size-1:0]    input_1,
input   wire   [input_size-1:0]    input_2,
output  logic   [output_size-1:0]    result,
// control IOs
input   wire   clk_in,
input   wire   rst_in,
input   wire   enable,
output  logic   o_finish
);

localparam half_input_size = input_size / 2;

logic   finish_p, finish_q, finish_ts;

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

// recursion 1: high_1 * high_2
generate
begin: p_high_1_high_2
    if(num_stages == 1)
    begin: p_direct
        assign  p = high_1 * high_2;
        assign  finish_p = enable;
    end
    else
    begin: p_recursive
        karat_mult_recursion #(
            .input_size         (half_input_size),
            .num_stages     (num_stages-1)
        )
        karat_mult_recursion_p (
            .input_1         (high_1),
            .input_2         (high_2),
            .result         (p),
            .clk_in        (clk_in),
            .rst_in      (rst_in),
            .enable   (enable),
            .o_finish   (finish_p)
        );
    end
end
endgenerate

// recursion 2: low_1 * low_2
generate
begin: q_low_1_low_2
    if(num_stages == 1)
    begin: q_direct
        assign  q = low_1 * low_2;
        assign  finish_q = enable;
    end
    else
    begin: q_recursive
        karat_mult_recursion #(
            .input_size         (half_input_size),
            .num_stages     (num_stages-1)
        )
        karat_mult_recursion_q (
            .input_1         (low_1),
            .input_2         (low_2),
            .result         (q),
            .clk_in        (clk_in),
            .rst_in      (rst_in),
            .enable   (enable),
            .o_finish   (finish_q)
        );
    end
end
endgenerate

// recursion 3: r_lo * s_lo
generate
begin: ts_eq_rlo_x_slo
    if(num_stages == 1)
    begin: ts_direct_mult
        assign  t_s = r_lo * s_lo;
        assign  finish_ts = enable;
    end
    else
    begin: ts_karat_mult
        karat_mult_recursion #(
            .input_size         (half_input_size),
            .num_stages     (num_stages-1)
        )
        karat_mult_recursion_ts (
            .input_1         (r_lo),
            .input_2         (s_lo),
            .result         (t_s),
            .clk_in        (clk_in),
            .rst_in      (rst_in),
            .enable   (enable),
            .o_finish   (finish_ts)
        );
    end
end
endgenerate

assign t = ((r_hi & s_hi) << input_size) + ((r_hi * s_lo + s_hi * r_lo) << half_input_size) + t_s;

assign result = (p << input_size) + ((t - u) << half_input_size) + q;

always  @(posedge clk_in or negedge rst_in)
    if(!rst_in)
        o_finish    <= 1'b0;
    else
        o_finish    <= finish_p && finish_q && finish_ts;

endmodule

`default_nettype wire