`timescale 1ns / 1ps
`default_nettype none

module top_level (
    // 100 MHz system clock
    input wire          clk_100mhz,

    // LEDs
    output logic [15:0] led,

    // Buttons (SYSRST)
    input wire [3:0]    btn,

    // RGB LEDs
    output logic [2:0]  rgb0,
    output logic [2:0]  rgb1,

    // Seven-segment display
    // output logic [3:0]  ss0_an, // Anode control for upper four digits
    // output logic [3:0]  ss1_an, // Anode control for lower four digits
    // output logic [6:0]  ss0_c,  // Cathode control for the segments of upper four digits
    // output logic [6:0]  ss1_c,  // Cathode control for the segments of lower four digits

    input wire      uart_rxd, // UART RX: computer --> FPGA
	output logic    uart_txd  // UART TX: FPGA     --> computer
    );

    // Bit width of a message
    localparam MSG_WIDTH = 16;

    // Bit width of a key
    localparam KEY_WIDTH = 32;

    // Total UART message width
    localparam UART_WIDTH = MSG_WIDTH + 2 * KEY_WIDTH;

    // UART BAUD rate
    localparam BAUD = 115_200;

    // Turn off those RGB LEDs
    assign rgb0 = 0;
    assign rgb1 = 0;

    // Button D controls SYSRST
    logic sys_rst;
    assign sys_rst = btn[0];

    // UART RX control signal and data
    logic rx_valid;
    logic [UART_WIDTH-1:0] rx_data;

    // UART TX control signals and data
    logic [MSG_WIDTH-1:0] tx_data;
    logic tx_ready;
    logic tx_busy;

    // ExpMod control signals
    logic expmod_ready, expmod_busy, expmod_valid;

    // ExpMod input and output signals
    logic [MSG_WIDTH-1:0] value;
    logic [KEY_WIDTH-1:0] modulus, exponent, result;

    // Received data
    logic [UART_WIDTH-1:0] received_data;

    // Data to transmit
    logic [KEY_WIDTH-1:0] data_to_transmit;

    // Assign ExpMod inputs
    assign value = received_data[MSG_WIDTH-1:0];
    assign exponent = received_data[MSG_WIDTH+KEY_WIDTH-1:MSG_WIDTH];
    assign modulus = received_data[UART_WIDTH-1:MSG_WIDTH+KEY_WIDTH];

    // Assign ExpMod output
    assign tx_data = result;

    // Assign ExpMod control signals
    always_ff @(posedge clk_100mhz) begin
        if (sys_rst) begin
            expmod_ready <= 1'b0;
            tx_ready <= 1'b0;
        end else begin
            expmod_ready <= rx_valid;
            tx_ready <= expmod_valid;

            if (rx_valid) received_data <= rx_data;
            if (expmod_valid) data_to_transmit <= result;
        end
    end

    // Synchronizer to prevent metastability
    logic uart_rx_buf0, uart_rx_buf1;
    always_ff @(posedge clk_100mhz) begin
        uart_rx_buf0 <= uart_rxd;
        uart_rx_buf1 <= uart_rx_buf0;
    end

    // LED LFSR (just for show)
    always_ff @(posedge clk_100mhz) begin
        if (sys_rst) begin
            led <= 16'b1111_1111_1111_1111;
        end else if (expmod_busy) begin
            led[15] <= led[14];
            led[14] <= led[13];
            led[13] <= led[12];
            led[12] <= led[11] ^ led[15];
            led[11] <= led[10];
            led[10] <= led[9];
            led[9] <=  led[8];
            led[8] <=  led[7] ^ led[15];
            led[7] <=  led[6];
            led[6] <=  led[5];
            led[5] <=  led[4];
            led[4] <=  led[3] ^ led[15];
            led[3] <=  led[2];
            led[2] <=  led[1];
            led[1] <=  led[0];
            led[0] <=  led[15];
        end else begin
            led <= 16'b0;
        end
    end

    // UART Receiver
    deserializer #(

    ) uart_receiver (

    );

    // ExpMod block
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

    // UART Transmitter
    seralizer #(
        .BYTES(KEY_WIDTH)
    ) uart_transmitter (

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