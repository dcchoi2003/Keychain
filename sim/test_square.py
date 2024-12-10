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

WIDTH = 256

N = 100

MAX_SIZE = pow(2, WIDTH) - 1

@cocotb.test()
async def test_square(dut):
    # Start clock
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    # Set all inputs to zero
    dut.value_in.value = 0
    dut.ready_in.value = 0

    # Reset
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 3)
    dut.rst_in.value = 0
    
    for i in range(N):
        value = randint(1, MAX_SIZE)
        print(f"Checking ({value}) ... ", end="")
        dut.value_in.value = value
        dut.ready_in.value = 1
        await RisingEdge(dut.clk_in)
        dut.ready_in.value = 0
        await RisingEdge(dut.valid_out)
        await ClockCycles(dut.clk_in, 1)
        assert dut.square_out.value == value**2
        print("OK")

def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "square.sv"]
    sources += [proj_path / "hdl" / "simple_mult.sv"]
    build_test_args = ["-Wall"]
    parameters = {"WIDTH": WIDTH}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="square",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="square",
        test_module="test_square",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()