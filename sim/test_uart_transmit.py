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

# Bit width
WIDTH = 256

# Number of tests
N = 5

# Max input size
MAX_SIZE = pow(2, WIDTH) - 1

# Baud rate
BAUD = 115_200

# Clock frequency
FREQ = 100_000_000

def convert_bits_le(number):
    return ('{0:0' + str(WIDTH) + 'b}').format(number)[::-1]

async def test_tx(dut, value):
    start_time = gst("ns")

    print(f"Checking ({value}) ... ", end="")

    # Convert value to bits & reverse (LSB first)
    bits = convert_bits_le(value)

    # Set input and trigger transmission
    dut.data_in.value = value
    dut.ready_in.value = 1
    await RisingEdge(dut.clk_in)
    dut.ready_in.value = 0

    await ClockCycles(dut.clk_in, FREQ//(2*BAUD))

    # Start bit
    assert dut.tx_wire_out == 0

    # Check each bit
    for bit in bits:
        await ClockCycles(dut.clk_in, FREQ//BAUD)
        assert dut.tx_wire_out.value == int(bit)
        await RisingEdge(dut.clk_in)

    # Stop bit
    await ClockCycles(dut.clk_in, FREQ//BAUD)
    assert dut.tx_wire_out == 1
    await ClockCycles(dut.clk_in, FREQ//(2*BAUD))

    cycles = int((gst("ns") - start_time) / 10)

    print(f"OK in {cycles} cycles")

    return cycles

@cocotb.test()
async def test_uart_transmit(dut):
    # Start clock
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    # Set input
    dut.ready_in.value = 0
    dut.data_in.value = 0

    # Assert RESET
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in,3)
    dut.rst_in.value = 0

    # Keep tally of cycles
    total_cycles = 0

    # Send random data
    for _ in range(N):
        # Generate random numbers
        value = randint(1, MAX_SIZE)

        # See if it calculates it correctly
        total_cycles += await test_tx(dut, value)

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
    sources = [proj_path / "hdl" / "uart_transmit.sv"]
    build_test_args = ["-Wall"]
    parameters = {"WIDTH": WIDTH, "BAUD_RATE": BAUD, "INPUT_CLOCK_FREQ": FREQ}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="uart_transmit",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="uart_transmit",
        test_module="test_uart_transmit",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()