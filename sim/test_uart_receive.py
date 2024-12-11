import cocotb
import os
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
from random import randint

# Key width
KEY_BYTES = 2

# Message width
MSG_BYTES = 1

# Total bytes
BYTES = 2 * KEY_BYTES + MSG_BYTES

# Number of tests
N = 25

# Max input size
MAX_KEY_SIZE = pow(2, 8*KEY_BYTES) - 1
MAX_MSG_SIZE = pow(2, 8*MSG_BYTES) - 1

# Baud rate
BAUD = 921_600

# Clock frequency
FREQ = 100_000_000

def convert_bits_le(number, width):
    return ('{0:0' + str(width) + 'b}').format(number)[::-1]

async def test_rx(dut, value, exponent, modulus):
    start_time = gst("ns")

    print(f"Checking ({value}, {exponent}, {modulus}) ... ", end="")

    # Convert value to bits & reverse (LSB first)
    value_bits = convert_bits_le(value, 8*MSG_BYTES)
    key_bits   = convert_bits_le(exponent, 8*KEY_BYTES)
    mod_bits   = convert_bits_le(modulus, 8*KEY_BYTES)
    bits = mod_bits + key_bits + value_bits

    # Initialize index
    i = 0

    while i < BYTES:
        byte = bits[8*i:8*i+8]

        # Start bit
        await ClockCycles(dut.clk_in, FREQ//BAUD)
        dut.rx_wire_in.value = 0
        await ClockCycles(dut.clk_in, FREQ//BAUD)
        await RisingEdge(dut.clk_in)

        # Send each bit
        for bit in byte:
            dut.rx_wire_in.value = int(bit)
            await ClockCycles(dut.clk_in, FREQ//BAUD)
            await RisingEdge(dut.clk_in)

        # Stop bit
        dut.rx_wire_in.value = 1

        i += 1

    # Wait for valid data
    await RisingEdge(dut.valid_out)

    # Wait another clock cycle
    await ClockCycles(dut.clk_in, 1)

    # Check output values
    assert dut.message_out == value
    assert dut.exponent_out == exponent
    assert dut.modulus_out == modulus

    cycles = int((gst("ns") - start_time) / 10)

    print(f"OK in {cycles} cycles")

    return cycles

@cocotb.test()
async def test_uart_receive(dut):
    # Start clock
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    # Set input
    dut.rx_wire_in.value = 1

    # Assert RESET
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 3)
    dut.rst_in.value = 0

    # Keep tally of cycles
    total_cycles = 0

    # Send random data
    for _ in range(N):
        # Generate random numbers
        modulus = randint(1, MAX_KEY_SIZE)
        value = randint(1, min(MAX_MSG_SIZE, modulus))
        exponent = randint(1, MAX_KEY_SIZE)

        # See if it calculates it correctly
        total_cycles += await test_rx(dut, value, exponent, modulus)

    # Average cycles
    average_cycles = round(total_cycles/N, 3)

    # Average time
    average_time = round(average_cycles / 1000, 3)

    print(f"Completed {N} tests in {average_cycles} cycles/test ({average_time} us/test)")

def is_runner():
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_receive.sv"]
    sources += [proj_path / "hdl" / "deserializer.sv"]
    build_test_args = ["-Wall"]
    parameters = {"KEY_BYTES": KEY_BYTES, "MSG_BYTES": MSG_BYTES, "BAUD_RATE": BAUD, "INPUT_CLOCK_FREQ": FREQ}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="deserializer",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="deserializer",
        test_module="test_uart_receive",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()