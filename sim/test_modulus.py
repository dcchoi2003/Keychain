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
WIDTH = 8

# Number of tests
N = 500

# Max input size
MAX_MODULUS_SIZE = pow(2, WIDTH) - 1
MAX_INPUT_SIZE   = pow(2, 2*WIDTH) - 1

async def test_mod(dut, value, modulus):
    start_time = gst("ns")

    print(f"Checking ({value}, {modulus}) ... ", end="")

    dut.value_in.value = value
    dut.modulus_in.value = modulus
    dut.ready_in.value = 1
    await RisingEdge(dut.clk_in)
    dut.ready_in.value = 0
    await RisingEdge(dut.valid_out)

    # Wait another clock cycle
    await ClockCycles(dut.clk_in, 1)

    assert dut.value_out == value % modulus

    cycles = int((gst("ns") - start_time) / 10)

    print(f"OK in {cycles} cycles")

    return cycles

@cocotb.test()
async def test_modulus(dut):
    # Start clock
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    # Set all inputs to zero
    dut.value_in.value = 0
    dut.ready_in.value = 0
    dut.modulus_in.value = 0

    # Assert RESET
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in,3)
    dut.rst_in.value = 0

    # Keep tally of cycles
    total_cycles = 0

    # Send random data
    for _ in range(N):
        # Generate random numbers
        modulus = randint(1, MAX_MODULUS_SIZE)
        value = randint(1, MAX_INPUT_SIZE)

        # See if it calculates it correctly
        total_cycles += await test_mod(dut, value, modulus)

    # Average cycles
    average_cycles = round(total_cycles/N, 2)

    # Average time
    average_time = round(average_cycles / 1000, 2)

    print(f"Completed {N} tests in {average_cycles} cycles/test ({average_time} us/test)")

def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "modulus.sv"]
    build_test_args = ["-Wall"]
    parameters = {"WIDTH": WIDTH}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="modulus",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="modulus",
        test_module="test_modulus",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()