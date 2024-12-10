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
KEY_WIDTH = 32

# Message width
MSG_WIDTH = 16

# Number of tests
N = 1

# Max input size
MAX_KEY_SIZE = pow(2, KEY_WIDTH) - 1
MAX_MSG_SIZE = pow(2, MSG_WIDTH) - 1

# Baud rate
BAUD = 921_600

# Clock frequency
FREQ = 100_000_000

def convert_bits_le(number, width):
    return ('{0:0' + str(width) + 'b}').format(number)[::-1]

async def encode_decode(dut, value, exponent, modulus):
    start_time = gst("ns")

    print(f"Checking ({value}, {exponent}, {modulus})...")

    # Convert value to bits & reverse (LSB first)
    value_bits = convert_bits_le(value, MSG_WIDTH)
    exponent_bits = convert_bits_le(exponent, KEY_WIDTH)
    modulus_bits = convert_bits_le(modulus, KEY_WIDTH)
    print(value_bits[::-1], exponent_bits[::-1], modulus_bits[::-1])
    bits = value_bits + exponent_bits + modulus_bits

    # Start bit
    dut.rx_wire_in.value = 0
    await ClockCycles(dut.clk_in, FREQ//BAUD)
    await RisingEdge(dut.clk_in)
    print("\tSending UART start bit")

    # Send each bit
    for i, bit in enumerate(bits):
        dut.rx_wire_in.value = int(bit)
        await ClockCycles(dut.clk_in, FREQ//BAUD)
        await RisingEdge(dut.clk_in)
        print(f"\tSending UART bit {i}")

    # Stop bit
    dut.rx_wire_in.value = 1
    print(f"\tSending UART stop bit")

    # Wait for valid data
    print(f"\tAwaiting output ...")
    await FallingEdge(dut.tx_wire_out)
    await ClockCycles(dut.clk_in, FREQ//(2*BAUD))

    # Assert start bit
    assert dut.tx_wire_out == 0
    print(f"\tReceived start bit!")

    # Convert output value to bits
    expected_output = pow(value, exponent, modulus)
    expected_bits = convert_bits_le(expected_output, KEY_WIDTH)

    # Check each bit
    for i, bit in enumerate(expected_bits):
        await ClockCycles(dut.clk_in, FREQ//BAUD)
        assert dut.tx_wire_out.value == int(bit)
        await RisingEdge(dut.clk_in)
        print(f"\tReceived UART bit {i}")

    # Stop bit
    await ClockCycles(dut.clk_in, FREQ//BAUD)
    assert dut.tx_wire_out == 1
    await ClockCycles(dut.clk_in, FREQ//(2*BAUD))
    print(f"\tReceived stop bit")

    cycles = int((gst("ns") - start_time) / 10)

    print(f"OK in {cycles} cycles")
    print()
    print()

    return cycles

@cocotb.test()
async def test_keychain(dut):
    # Start clock
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    # Set input
    dut.rx_wire_in.value = 1

    # Assert RESET
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in,3)
    dut.rst_in.value = 0

    # Keep tally of cycles
    total_cycles = 0

    # Send random data
    for _ in range(N):
        # Generate random numbers
        modulus = randint(1, MAX_KEY_SIZE)
        exponent = randint(1, MAX_KEY_SIZE)
        value = randint(1, min(modulus, MAX_MSG_SIZE))

        # See if it calculates it correctly
        total_cycles += await encode_decode(dut, value, exponent, modulus)

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
    sources += [proj_path / "hdl" / "uart_transmit.sv"]
    sources += [proj_path / "hdl" / "keychain.sv"]
    sources += [proj_path / "hdl" / "exponent_modulus.sv"]
    sources += [proj_path / "hdl" / "modulus.sv"]
    sources += [proj_path / "hdl" / "simple_mult.sv"]
    build_test_args = ["-Wall"]
    parameters = {"KEY_WIDTH": KEY_WIDTH, "MSG_WIDTH": MSG_WIDTH, "BAUD_RATE": BAUD}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="keychain",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="keychain",
        test_module="test_keychain",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()