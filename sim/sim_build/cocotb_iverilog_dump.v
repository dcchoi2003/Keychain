module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/davidchoi/Desktop/6.2050/Keychain/sim/sim_build/karat_mult_recursion.fst");
    $dumpvars(0, karat_mult_recursion);
end
endmodule
