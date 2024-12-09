`timescale 1ns / 1ps
`default_nettype none

module top_level
    (
    input wire          clk_100mhz,
    output logic [15:0] led,
    // inout wire          i2c_scl, // i2c inout clock
    // inout wire          i2c_sda, // i2c inout data
    input wire [15:0]   sw,
    input wire [3:0]    btn,
    output logic [2:0]  rgb0,
    output logic [2:0]  rgb1
    // seven segment
    // output logic [3:0]  ss0_an,//anode control for upper four digits of seven-seg display
    // output logic [3:0]  ss1_an,//anode control for lower four digits of seven-seg display
    // output logic [6:0]  ss0_c, //cathode controls for the segments of upper four digits
    // output logic [6:0]  ss1_c, //cathod controls for the segments of lower four digits

    input wire      uart_rxd, // UART computer-FPGA
	output logic    uart_txd // UART FPGA-computer
    );

    localparam WIDTH = 16;

    // shut up those RGBs
    assign rgb0 = 0;
    assign rgb1 = 0;

    // have btnd control system reset
    logic sys_rst;
    assign sys_rst = btn[0];

   // Synchronizer
   // TODO: pass your uart_rx data through a couple buffers,
   // save yourself the pain of metastability!
   logic    uart_rx_buf0, uart_rx_buf1;

    always_ff @(posedge clk_100mhz) begin
        uart_rx_buf0 <= uart_rxd;
        uart_rx_buf1 <= uart_rx_buf0;
    end

   // UART Receiver
   // TODO: instantiate your uart_receive module, connected up to the buffered uart_rx signal
		// declare any signals you need to keep track of!

    logic receiver_data_out;
    logic [7:0] byte_out_data;

    uart_receive #(.BAUD_RATE(115200)) receive (.clk_in(clk_100mhz),
                .rst_in(sys_rst),
                .rx_wire_in(uart_rx_buf1),
                .new_data_out(receiver_data_out),
                .data_byte_out(byte_out_data));

   // BRAM Memory
   // We've configured this for you, but you'll need to hook up your address and data ports to the rest of your logic!

   // 256-bit keys, no need for depth
   parameter BRAM_WIDTH = 256;
   parameter BRAM_DEPTH = 1;
   parameter ADDR_WIDTH = $clog2(BRAM_DEPTH);

   // only using port a for reads: we only use dout
   logic [BRAM_WIDTH-1:0]     douta;
   logic [ADDR_WIDTH-1:0]     addra;

   // only using port b for writes: we only use din
   logic [BRAM_WIDTH-1:0]     dinb;
   logic [ADDR_WIDTH-1:0]     addrb;

   xilinx_true_dual_port_read_first_2_clock_ram
     #(.RAM_WIDTH(BRAM_WIDTH),
       .RAM_DEPTH(BRAM_DEPTH),
       .INIT_FILE(`FPATH(secret_key.mem))
       ) key_bram
       (
        // PORT A
        .addra(addra),
        .dina(0), // we only use port A for reads!
        .clka(clk_100mhz),
        .wea(1'b0), // read only
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(douta),
        // PORT B
        .addrb(addrb),
        .dinb(dinb),
        .clkb(clk_100mhz),
        .web(1'b1), // write always
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb() // we only use port B for writes!
        );

       logic [7:0]                uart_data_in;
   logic                      uart_data_valid;
   logic                      uart_busy;


   // UART Transmitter to FTDI2232
   // TODO: instantiate the UART transmitter you just wrote, using the input signals from above.

    uart_transmit #(.BAUD_RATE(115200)) transmit (.clk_in(clk_100mhz),
                .rst_in(sys_rst),
                .data_byte_in(uart_data_in),
                .trigger_in(uart_data_valid),
                .busy_out(uart_busy),
                .tx_wire_out(uart_txd));

    // Ready, Busy, Valid signals
    logic expmod_ready, expmod_busy, expmod_valid;

    // Input and output signals
    logic [WIDTH-1:0] value, modulus, exponent, result;

    assign value = sw;

    exponent_modulus #(
        .WIDTH(WIDTH)
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

    always_ff @(posedge clk_100mhz) begin

        if (sys_rst) begin
            modulus <= 0;
            exponent <= 0;
            expmod_ready <= 0;
        end else begin
            if (!expmod_busy && !expmod_valid) begin
                exponent <= 16'd72;
                modulus <= 16'd1073;
                expmod_ready <= 1;
            end else if (expmod_valid) begin
                led <= result;
            end
        end

        if (expmod_ready) expmod_ready <= 0;

    end

endmodule // top_level


`default_nettype wire