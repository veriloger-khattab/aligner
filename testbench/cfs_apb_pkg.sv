//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 8/1/25
// File      : cfs_apb_pkg.sv
// Status    : finished
// Goal      : wrapping all apb files in a single package
// Instructor: Cristian Slav
// Tips      : read the code documentation below to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef CFS_APB_PKG_SV
  `define CFS_APB_PKG_SV


  `include "uvm_macros.svh"
  `include "cfs_apb_if.sv"                                                                                                                           // note that it is included outside the package & should not be imported inside
  package cfs_apb_pkg;
    import uvm_pkg::*;

    `include "cfs_apb_types.sv"
    `include "cfs_apb_reset_handler.sv"
    `include "cfs_apb_item_base.sv"
    `include "cfs_apb_item_drv.sv"
    `include "cfs_apb_item_mon.sv"
    `include "cfs_apb_agent_config.sv"
    `include "cfs_apb_monitor.sv"
    `include "cfs_apb_coverage.sv"
    `include "cfs_apb_driver.sv"
    `include "cfs_apb_sequencer.sv"
    `include "cfs_apb_agent.sv"

    `include "cfs_apb_sequence_base.sv"
    `include "cfs_apb_sequence_simple.sv"
    `include "cfs_apb_sequence_rw.sv"
    `include "cfs_apb_sequence_random.sv"
  endpackage

`endif




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                         --- "Implementation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1-  import uvm package inside the apb package and include "uvm_macros.svh" outside                                                          "*
 *"   2-  include apb interface outside apb package                                                                                               "*
 *"   3-  include apb types inside apb package                                                                                                    "*
 *"   4-  include apb agent configuration inside apb package                                                                                      "*
 *"   5-  include apb agent inside apb package                                                                                                    "*
 *"   6-  include apb base item inside apb package                                                                                                "*
 *"   7-  include apb drive item inside apb package                                                                                               "*
 *"   8-  Include apb sequencer inside apb package                                                                                                "*
 *"   9-  include apb driver inside apb package                                                                                                   "*
 *"   10- include apb base sequence inside apb package (must be included after sequencer)                                                         "*
 *"   11- include apb simple sequence inside apb package                                                                                          "*
 *"   12- include apb monitor item inside apb package                                                                                             "*
 *"   13- include apb monitor inside apb package                                                                                                  "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                               --- "Merge info" ---                                                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- import apb package inside the environment package and include it outside                                                                 "*
 *"   2- import apb package inside the test package                                                                                               "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                            --- "Diagarm Hierarchy" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   testbench                                                                                                                                   "*
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
 *"                                                                                                                                               "*
 *"            apb_if.sv       macros.svh                                                                                                         "*
 *"                ↓           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                          "*
 *"                ↓           | apb_pkg                                                                               |                  (o)     "*
 *"                ↓           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                          "*
 *"                ↓set        | uvm_pkg::*                                                                            |                          "*
 *"         -----------------  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                          "*
 *"         | uvm_config_db |  |                                                                                       |                          "*
 *"         |               |  |                             ~--- cfs_apb_sequence_random<<<                           |                          "*
 *"         |    apb_vif    |  |                             |                             ^                           |                          "*
 *"         -----------------  |     cfs_apb_sequence_base <-~--- cfs_apb_sequence_rw      ^                       <   |                          "*
 *"                ↓           |                   ↑  ^      |                             ^                       ^   |                          "*
 *"                ↓           |                   ↑  ^      ~--- cfs_apb_sequence_simple>>>                       ^   |                          "*
 *"                ↓       get |                   ↑  ^                        ^                                   ^   |                          "*
 *"                 → → → → → →|   > cfs_apb_agent ↑  <<<<<<<<<<<<<<<<<<<<<<<<<^                    <              ^   |                          "*
 *"                            |   ^              cfs_apb_sequencer           <^                   <^              ^   |                          "*
 *"                            |   ^>      >      cfs_apb_driver              <^                   <^              ^   |                          "*
 *"                            |   ^>      ^>     cfs_apb_coverage             ^       <           <^              ^   |                          "*
 *"                            |   ^>      ^>     cfs_apb_monitor              ^      <^           <^              ^   |                          "*
 *"                            |   ^>      <<<<<<<cfs_apb_agent_config         ^       ^            ^              ^   |                          "*
 *"                            |   ^                                           ^       ^            ^              ^   |                          "*
 *"                            |   ^                     ~-- cfs_apb_item_drv>>>       ^            ^              ^   |                          "*
 *"                            |   ^                     |                             ^            ^              ^   |                          "*
 *"                            |   ^>cfs_apb_item_base <-~                             ^            ^              ^   |                          "*
 *"                            |   ^                     |                             ^            ^              ^   |                          "*
 *"                            |   ^                     ~-- cfs_apb_item_mon>>>>>>>>>>>            ^              ^   |                          "*
 *"                            |   ^                         ^                                      ^              ^   |                          "*
 *"                            |   ^                         ^                              cfs_apb_reset_handler  ^   |                          "*
 *"                            |   ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<cfs_apb_types>>>>>>>>>>>   |                          "*
 *"                            |                                                                                       |                          "*
 *"                            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                          "*
 *"            dut                                                                                                                                "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
