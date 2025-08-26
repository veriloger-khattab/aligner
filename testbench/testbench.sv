//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 7/8/25
// File      : testbench.sv
// Status    : in progress
// Goal      : creating a testbench to verify aligner module
// Instructor: Cristian Slav
// Tips      : read the code documentation below to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`include "cfs_algn_test_pkg.sv"

module testbench();

  import uvm_pkg::*;                                                                                                                                 // To use run_test("") function
  import cfs_algn_test_pkg::*;                                                                                                                       // Testbench now have access to tests classes

  reg clk;

  cfs_apb_if apb_if(.pclk(clk));
  initial begin
    clk = 0;
    forever begin
      clk = #5ns ~clk;
    end
  end

  initial begin
    apb_if.preset_n = 1;
    #3ns;
    apb_if.preset_n = 0;                                                                                                                             // Aligner registers will get their initial values
    #30ns;
    apb_if.preset_n = 1;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;

    uvm_config_db#(virtual cfs_apb_if)::set(null, "uvm_test_top.env.apb_agent", "vif", apb_if);                                                      // Setting apb virtual interface inside uvm configuration database. The interface must be virtual now

    run_test("");                                                                                                                                    // Test name is specified in run_batch.bat file
  end


  cfs_aligner dut(
    .clk(clk),
    .reset_n(apb_if.preset_n),
    .paddr(apb_if.paddr),
    .prdata(apb_if.prdata),
    .pwdata(apb_if.pwdata),
    .psel(apb_if.psel),
    .penable(apb_if.penable),
    .pready(apb_if.pready),
    .pwrite(apb_if.pwrite),
    .pslverr(apb_if.pslverr)
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
 *"   1- testbench is not a class, it is a normal module                                                                                          "*
 *"                                                                                                                                               "*
 *"   2- initial blocks execute in parallel and it is better so separate the initial blocks of the clock, reset and running tests in order to keep"*
 *"      the code clean                                                                                                                           "*
 *"                                                                                                                                               "*
 *"   3- if we need to run a test we specify that the batch file, this is better than typing the name of the test directly inside the testbench   "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                         --- "Implementation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- create an instance of the dut (aligner)                                                                                                  "*
 *"   2- initialize the clock, set its frequency and connect it to the dut clock                                                                  "*
 *"   3- connect apb interface signals with dut's apb signals                                                                                     "*
 *"   4- import uvm package inside the testbench to use run_test("") function                                                                     "*
 *"   5- import the test package inside the testbench & include it outside                                                                        "*
 *"   5- instantiate apb interface inside the testbench                                                                                           "*
 *"   6- set apb interface inside uvm configuration database and give access to the apb agent                                                     "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */





//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                            --- "Diagarm Hierarchy" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   testbench                                                                                                <- We are here now         (o)     "*
 *"            tests                                                                                                                              "*
 *"                 environment                                                                                                                   "*
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