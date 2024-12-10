`timescale 1ns / 1ps
`default_nettype none

module top_level (
    // 100 MHz system clock
    input wire          clk_100mhz,

    // LEDs
    output logic [15:0] led,

    // Switches (not useful for us?)
    input wire [15:0]   sw,

    // Buttons (SYSRST)
    input wire [3:0]    btn,

    // RGB LEDs
    output logic [2:0]  rgb0,
    output logic [2:0]  rgb1,

    // Seven-segment display
    output logic [3:0]  ss0_an, // Anode control for upper four digits
    output logic [3:0]  ss1_an, // Anode control for lower four digits
    output logic [6:0]  ss0_c,  // Cathode control for the segments of upper four digits
    output logic [6:0]  ss1_c,  // Cathode control for the segments of lower four digits

    input wire      uart_rxd, // UART computer-FPGA
	output logic    uart_txd  // UART FPGA-computer
    );

    // Bit width of a message
    localparam MSG_WIDTH = 16;

    // Bit width of a key
    localparam KEY_WIDTH = 32;

    // Turn off those RGB LEDs
    assign rgb0 = 0;
    assign rgb1 = 0;

    // Button D controlls SYSRST
    logic sys_rst;
    assign sys_rst = btn[0];

    // Synchronizer
    logic uart_rx_buf0, uart_rx_buf1;
    always_ff @(posedge clk_100mhz) begin
        uart_rx_buf0 <= uart_rxd;
        uart_rx_buf1 <= uart_rx_buf0;
    end

    // UART Receiver
    logic receiver_data_out;
    logic [7:0] byte_out_data;

    uart_receive #(
        .BAUD_RATE(115200)
    ) receive (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .rx_wire_in(uart_rx_buf1),
        .new_data_out(receiver_data_out),
        .data_byte_out(byte_out_data)
    );

    // // BRAM Memory
    // // We've configured this for you, but you'll need to hook up your address and data ports to the rest of your logic!

    // // 256-bit (or size of WIDTH) keys, no need for depth
    // parameter BRAM_WIDTH = WIDTH;
    // parameter BRAM_DEPTH = 1;
    // parameter ADDR_WIDTH = 1; // $clog2(BRAM_DEPTH)

    // // only using port a for reads: we only use dout
    // logic [BRAM_WIDTH-1:0]     douta;
    // logic [ADDR_WIDTH-1:0]     addra;

    // // bram access for secret key

    //     xilinx_single_port_ram_read_first #(
    //     .RAM_WIDTH(BRAM_WIDTH),                       // Specify RAM data width
    //     .RAM_DEPTH(BRAM_DEPTH),                     // Specify RAM depth (number of entries)
    //     .INIT_FILE(`FPATH(secret_key.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    //     ) secret_key_bram (
    //     .addra(addra),     // Address bus, width determined from RAM_DEPTH
    //     .dina(0),       // RAM input data, width determined from RAM_WIDTH
    //     .clka(clk_100mhz),       // Clock
    //     .wea(1'b0),         // Write enable
    //     .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    //     .rsta(sys_rst),       // Output reset (does not affect memory contents)
    //     .regcea(1'b1),   // Output register enable
    //     .douta(douta)      // RAM output data, width determined from RAM_WIDTH
    // );

    logic [7:0]                uart_data_in;
    logic                      uart_data_valid;
    logic                      uart_busy;

    // UART Transmitter
    uart_transmit #(
        .BAUD_RATE(115200)
    ) transmit (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .data_byte_in(uart_data_in),
        .trigger_in(uart_data_valid),
        .busy_out(uart_busy),
        .tx_wire_out(uart_txd)
    );

    // ExpMod control signals
    logic expmod_ready, expmod_busy, expmod_valid;

    // Input and output signals
    logic [MSG_WIDTH-1:0] value;
    logic [KEY_WIDTH-1:0] modulus, exponent, result;

    exponent_modulus #(
        .KEY_WIDTH(KEY_WIDTH),
        .MSG_WIDTH(MSG_WIDTH)
    ) expmod (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .ready_in(expmod_ready),
        .value_in(value),
        .modulus_in(modulus),
        .exponent_in(exponent),
        .value_out(result),
        .busy_out(expmod_busy),
        .valid_out(expmod_valid)
    );

    // logic pull_key_from_bram;

    // always_ff @(posedge clk_100mhz) begin

    //     if (sys_rst) begin
    //         modulus <= 0;
    //         exponent <= 0;
    //         expmod_ready <= 0;
    //     end else begin

    //         if (pull_key_from_bram) begin

    //             exponent <= douta;

    //         end else begin

                

    //         end


    //         if (!expmod_busy && !expmod_valid) begin
    //             exponent <= 16'd72;
    //             modulus <= 16'd1073;
    //             expmod_ready <= 1;
    //         end else if (expmod_valid) begin
    //             led <= result;
    //         end
    //     end

    //     if (expmod_ready) expmod_ready <= 0;

    // end

endmodule // top_level


`default_nettype wire