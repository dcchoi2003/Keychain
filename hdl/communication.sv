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
    input wire 		    uart_rxd, // UART computer-FPGA
	output logic 	    uart_txd // UART FPGA-computer
    );

    localparam WIDTH = 16;

    // shut up those RGBs
    assign rgb0 = 0;
    assign rgb1 = 0;

    // have btnd control system reset
    logic sys_rst;
    assign sys_rst = btn[0];

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

      //  Xilinx Single Port Read First RAM
    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(18),                       // Specify RAM data width
        .RAM_DEPTH(1024),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(data.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) your_instance_name (
        .addra(addra),     // Address bus, width determined from RAM_DEPTH
        .dina(dina),       // RAM input data, width determined from RAM_WIDTH
        .clka(clka),       // Clock
        .wea(wea),         // Write enable
        .ena(ena),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(rsta),       // Output reset (does not affect memory contents)
        .regcea(regcea),   // Output register enable
        .douta(douta)      // RAM output data, width determined from RAM_WIDTH
    );

    uart_receive #(.BAUD_RATE(115200)) receive (.clk_in(clk_100mhz),
                .rst_in(sys_rst),
                .rx_wire_in(uart_rx_buf1),
                .new_data_out(receiver_data_out),
                .data_byte_out(byte_out_data));

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