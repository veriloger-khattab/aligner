@echo off
echo                                           ______________________________________________________________
echo                                           \                        Ahmad Khattab                       /
echo                                            ============================================================
echo                                             \ compiling files, running REG_ACCESS_TEST in batch mode /
echo                                              ========================================================
echo.
echo.
qrun -batch -access=rw+/. -uvmhome uvm-1.2 -mfcu ^
design\\design.sv testbench\\testbench.sv ^
-voptargs="+acc=npr" ^
-do "vlog -timescale 1ns/1ns +incdir+testbench design\\design.sv testbench\\testbench.sv; run -all; exit" ^
+UVM_TESTNAME=ak_algn_test_reg_access +UVM_MAX_QUIT_COUNT=1