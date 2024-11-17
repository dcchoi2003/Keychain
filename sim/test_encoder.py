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

# utility function to reverse bits:
def reverse_bits(n,size):
    reversed_n = 0
    for i in range(size):
        reversed_n = (reversed_n << 1) | (n & 1)
        n >>= 1
    return reversed_n

@cocotb.test()
async def test_a(dut):

    # Start clock
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    # Assert reset
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in,3)
    dut.rst_in.value = 0

    # ENCODE
    dut.mux.value = 1
    dut.message.value = 3
    dut.public_key.value = 5
    dut.modulus.value = 14
    await ClockCycles(dut.clk_in,5)

    # DECODE
    dut.mux.value = 0
    dut.message.value = 5
    dut.modulus.value = 14
    await ClockCycles(dut.clk_in,5)

def is_runner():
    """Image Sprite Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "encoder.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="encoder",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="encoder",
        test_module="test_encoder",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    is_runner()