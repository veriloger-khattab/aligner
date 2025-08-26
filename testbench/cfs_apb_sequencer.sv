//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 8/4/25
// File      : cfs_apb_sequencer.sv
// Status    : finished
// Goal      : control, queue and arbitrate all transactions between apb sequences and apb driver
// Instructor: Cristian Slav
// Tips      : read the code documentation below to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef CFS_APB_SEQUENCER_SV
  `define CFS_APB_SEQUENCER_SV

    class cfs_apb_sequencer extends uvm_sequencer#(.REQ(cfs_apb_item_drv)) implements cfs_apb_reset_handler;
                                                                                                                                                     // Start of uvm component's mandatory code
      `uvm_component_utils(cfs_apb_sequencer)                                                                                                        // APB sequencer is now registered with uvm factory & can use all utility methods & features

      function new(string name = "", uvm_component parent);                                                                                          // Declaration of constructor
        super.new(name, parent);
      endfunction
                                                                                                                                                     // End of mandatory code
      virtual function void handle_reset(uvm_phase phase);                                                                                           // Clears the logic insdie the sequencer as item done would not trigger an error when it is not called in the driver
        int objections_count;
        stop_sequences();
        objections_count = uvm_test_done.get_objection_count(this);

        if(objections_count > 0) begin
          uvm_test_done.drop_objection(this, $sformatf("Dropping %0d objections at reset", objections_count), objections_count);
        end

        start_phase_sequence(phase);
      endfunction

    endclass

`endif







//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                         --- "Implementation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- declare apb sequencer and extend it from uvm sequencer that is parameterized with apb item drive                                         "*
 *"   2- write mandatory code for uvm component                                                                                                   "*
 *"   3- implement handle_reset() function in apb sequencer and specify that the sequencer class implements reset_handler class during declaration"*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                               --- "Merge info" ---                                                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- Include apb sequencer inside apb package                                                                                                 "*
 *"   2- declare a handler to apb sequencer inside apb agent                                                                                      "*
 *"   3- create an instance of apb sequencer inside apb agent in the build phase based on the active passive field from agent configuration       "*
 *"   4- connect sequence item port and sequence item export in apb agent inside connect phase                                                    "*
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
 *"                ↓           | apb_pkg                                                                               |                          "*
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
 *"                            |   ^              cfs_apb_sequencer           <^                   <^              ^   |                  (o)     "*
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
