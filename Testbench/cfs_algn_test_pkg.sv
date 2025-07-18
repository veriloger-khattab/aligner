//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 8/8/25
// File      : cfs_algn_test_pkg.sv
// Status    : In progress
// Goal      : Creating a package for aligner tests
// Instructor: Cristian Slav
// Tips      : Read the code guide to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef CFS_ALGN_TEST_PKG_SV
  `define CFS_ALGN_TEST_PKG_SV

  `include "uvm_macros.svh"                                                                        // Enables uvm macros usage in tests
  `include "cfs_algn_pkg.sv"

  package cfs_algn_test_pkg;
    import uvm_pkg::*;                                                                             // Gives tests uvm access
    import cfs_algn_pkg::*;                                                                        // Gives tests env access
    `include "cfs_algn_test_base.sv"
    `include "cfs_algn_test_reg_access.sv"
  endpackage

`endif



//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                               --- "Merge info" ---                                                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- include base test and register access test files inside the test package                                                                 "*
 *"   2- import uvm papckage as uvm will be used by the tests and import the environment package as the environment is inside the tests           "*
 *"   3- include uvm_macros.svh file and cfs_algn_pkg.sv file outside the test package as uvm_pkg and cfs_algn_pkg were imported inside           "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                            --- "Diagarm Hierarchy" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   testbench                                                                                                                           (o)     "*
 *"            tests                                                                             package       <- We are here now         (o)     "*
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

