//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 7/8/25
// File      : testbench.sv
// Status    : In progress
// Goal      : Creating a testbench to verify aligner module
// Instructor: Cristian Slav
// Tips      : Read the code guide to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`include "cfs_algn_test_pkg.sv"

module testbench();

  import uvm_pkg::*;
  import cfs_algn_test_pkg::*;

  reg clk;
  initial begin
    clk = 0;
    forever begin
      clk = #5ns ~clk;
    end
  end

  reg reset_n;
  initial begin
    reset_n = 1;
    #6ns;
    reset_n = 0;                                                                                   // Aligner registers will be initialized to zero
    #30ns;
    reset_n = 1;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    run_test("");                                                                                  // Tests run from the very beginning, test name is specified in run_batch.bat file
  end


  cfs_aligner dut(
    .clk(clk),
    .reset_n(reset_n)
    );

endmodule



//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                              --- "Code Guide" ---                                                               *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"  The testbench is the file that contains the dut and runs the tests which use the uvm environment, it is the top level so it sees everything  "*
 *"                                                                                                                                               "*
 *"==============================================================================================================================================="*
 *"                                                                                                                                               "*
 *"  1- The testbench is not a class, it is a normal module                                                                                       "*
 *"                                                                                                                                               "*
 *"  2- Initial blocks execute in parallel and it is better so separate the initial blocks of the clock, reset and running tests in order to keep "*
 *"     the code clean                                                                                                                            "*
 *"                                                                                                                                               "*
 *"  3- We Reset the dut so that all the regesters in aligner are initiazlied to zero                                                             "*
 *"                                                                                                                                               "*
 *"  4- The test should be chosen from the run command in the batch file, this is better than typing the name of the test inside the testbench    "*
 *"                                                                                                                                               "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                         --- "Implementation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"  1- Start by creating three initial blocks, one for the clock, another for reset and the third to call run_test("") function.                 "*
 *"  2- Create an instance of the dut and connect the testbench clock and reset signals to the corresponding clock and reset ports of the dut     "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                               --- "Merge info" ---                                                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- import aligner test package, as the testbench includes all the tests                                                                     "*
 *"   2- include the test package file outside the testbench module, since the alginer test package was imported                                  "*
 *"   3- import uvm package, since the tests inside the testbench will use uvm library                                                            "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */


//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                            --- "Diagarm Hierarchy" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   testbench                                                                                                <- We are here now         (o)     "*
 *"            tests                                                                                                                      (o)     "*
 *"                 environment                                                                                                           (o)     "*
 *"                            config                                                                                                             "*
 *"                            virtual_sequencer                                                                                                  "*
 *"                            scoreboard                                                                                                         "*
 *"                            coverage                                                                                                           "*
 *"                            model                                                                                                              "*
 *"                                 register_model                                                                                                "*
 *"                            predictor                                                                                                          "*
 *"                            rx_agent                                                                                                           "*
 *"                                    config                                                                                                     "*
 *"                                    coverage                                                                                                   "*
 *"                                    sequencer                                                                                                  "*
 *"                                    driver                                                                                                     "*
 *"                                    monitor                                                                                                    "*
 *"                                    interface                                                                                                  "*
 *"                            tx_agent                                                                                                           "*
 *"                                    config                                                                                                     "*
 *"                                    coverage                                                                                                   "*
 *"                                    sequencer                                                                                                  "*
 *"                                    driver                                                                                                     "*
 *"                                    monitor                                                                                                    "*
 *"                                    interface                                                                                                  "*
 *"                            apb_agent                                                                                                          "*
 *"                                     config                                                                                                    "*
 *"                                     coverage                                                                                                  "*
 *"                                     sequencer                                                                                                 "*
 *"                                     driver                                                                                                    "*
 *"                                     monitor                                                                                                   "*
 *"                                     interface                                                                                                 "*
 *"            dut                                                                                                                                "*
 *"                                                                                                                                               "*
 *"                                                                                                                                               "*
 *"                         For more better visualization, visit systemverilog.netlify.app to see the whole diagram                               "*
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */





//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                            --- "Compilation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *" open terminus -> go the scripts folder directory -> type file name -> press enter to compile and run files by questasim from sublime directly "*
 *" --------------------------------------------------------------------------------------------------------------------------------------------- "*
 *" C:\Users\ahmad\Desktop\aligner>scripts\run_batch.bat                   or                  C:\Users\ahmad\Desktop\aligner>scripts\run_gui.bat "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */