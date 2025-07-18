@echo off
echo _______________________________________________________________________________
echo                                Ahmad Khattab
echo ===============================================================================
echo   Compiling the design, Adding dut signals to waveform and running simulation
echo   ===========================================================================
echo.
echo                                .         .
echo                              .    .   .    .
echo                             .       .       .
echo                              .             .
echo                                 .      .
echo                                     .
echo.
qrun -gui -access=rw+/. -uvmhome uvm-1.2 -mfcu ^
Design\design.sv Testbench\testbench.sv ^
-voptargs="+acc" ^
-do "vlog -timescale 1ns/1ns +incdir+Testbench Design\design.sv Testbench\testbench.sv; vsim -voptargs=+acc work.testbench; add wave -position insertpoint sim:/testbench/dut/*; run -all; exit" ^
+UVM_TESTNAME=cfs_algn_test_reg_access