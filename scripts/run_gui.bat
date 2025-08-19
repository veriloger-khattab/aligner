@echo off
echo                                           ____________________________________________________________
echo                                           \                       Ahmad Khattab                      /
echo                                            ==========================================================
echo                                             \ compiling files, running REG_ACCESS_TEST in gui mode /
echo                                              ======================================================
echo.
echo.
qrun -gui -access=rw+/. -uvmhome uvm-1.2 -mfcu ^
design\\design.sv testbench\\testbench.sv ^
-voptargs="+acc" ^
-do "vlog -timescale 1ns/1ns +incdir+testbench design\\design.sv testbench\\testbench.sv; vsim -voptargs=+acc=rn work.testbench +UVM_TESTNAME=cfs_algn_test_reg_access; add wave -position insertpoint sim:/testbench/dut/reset_n sim:/testbench/dut/clk sim:/testbench/dut/psel sim:/testbench/dut/penable sim:/testbench/dut/pwrite sim:/testbench/dut/paddr sim:/testbench/dut/pwdata sim:/testbench/dut/prdata sim:/testbench/dut/pready sim:/testbench/dut/pslverr; run -all; exit"
