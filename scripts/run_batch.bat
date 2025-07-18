@echo off
echo ______________________________________________________________
echo                        Ahmad Khattab
echo ==============================================================
echo   Compiling the files, Running UVM without opening Questasim
echo   ==========================================================
echo.
echo                         .         .
echo                       .    .   .    .
echo                      .       .       .
echo                       .             .
echo                          .      .
echo                              .
echo.
qrun -batch -access=rw+/. -uvmhome uvm-1.2 -mfcu ^
Design\design.sv Testbench\testbench.sv ^
-voptargs="+acc=npr" ^
-do "vlog -timescale 1ns/1ns +incdir+Testbench Design\design.sv Testbench\testbench.sv; run -all; exit" ^
+UVM_TESTNAME=cfs_algn_test_reg_access