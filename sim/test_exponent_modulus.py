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

# Max input size
MAX_INPUT_SIZE = 1023

async def test_expmod(dut, base, exponent, modulus):
    print(f"Checking ({base}, {exponent}, {modulus}) ... ", end="")

    dut.value_in.value = base
    dut.exponent_in.value = exponent
    dut.modulus_in.value = modulus
    dut.ready_in.value = 1
    await RisingEdge(dut.clk_in)
    dut.ready_in.value = 0
    await RisingEdge(dut.valid_out)

    # Wait another clock cycle
    await ClockCycles(dut.clk_in, 1)

    assert dut.value_out == pow(base, exponent, modulus)

    print("ok!")

@cocotb.test()
async def test_exponent_modulus(dut):
    # Start clock
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    # Set all inputs to zero
    dut.value_in.value = 0
    dut.ready_in.value = 0
    dut.exponent_in.value = 0
    dut.modulus_in.value = 0

    # Assert RESET
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in,3)
    dut.rst_in.value = 0

    # Send random data
    for _ in range(100):
        # Generate random numbers
        base = randint(1, MAX_INPUT_SIZE)
        exponent = randint(1, MAX_INPUT_SIZE)
        modulus = randint(1, MAX_INPUT_SIZE)

        # See if it calculates it correctly
        await test_expmod(dut, base, exponent, modulus)

def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "exponent_modulus.sv"]
    sources += [proj_path / "hdl" / "modulus.sv"]
    sources += [proj_path / "hdl" / "square.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="exponent_modulus",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="exponent_modulus",
        test_module="test_exponent_modulus",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()