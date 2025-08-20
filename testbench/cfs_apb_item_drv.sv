//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 8/3/25
// File      : cfs_apb_item_drv.sv
// Status    : finished
// Goal      : creating a transaction object that contains driving infomation about apb transfer
// Instructor: Cristian Slav
// Tips      : read the code documentation below to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef CFS_APB_ITEM_DRV_SV
  `define CFS_APB_ITEM_DRV_SV
  class cfs_apb_item_drv extends cfs_apb_item_base;

    rand int unsigned pre_drive_delay;
    rand int unsigned post_drive_delay;

    constraint pre_drive_delay_default {
      soft pre_drive_delay <= 5;
    }

    constraint post_drive_delay_default {
      soft post_drive_delay <= 5;
    }

    `uvm_object_utils(cfs_apb_item_drv)                                                                                                              // APB drive item is now registered with uvm factory & can use core utility methods & features

    function new(string name = "");                                                                                                                  // Mandatory code for uvm objects (declaration of constructor)
      super.new(name);
    endfunction

    virtual function string convert2string();                                                                                                        // Overriding convert2string() function
      string result = super.convert2string();

      if(dir == CFS_APB_WRITE) begin
        result = $sformatf("%0s, data:%0x", result, data);                                                                                           // Data should be printed in hex, not as a string
      end

      result = $sformatf("%0s, pre_drive_delay: %0d, post_drive_delay: %0d", result, pre_drive_delay, post_drive_delay);
      return result;
    endfunction

  endclass
`endif








//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                         --- "Implementation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"  1- declare apb drive item class and extend it from apb base item                                                                             "*
 *"  2- write mandatory code                                                                                                                      "*
 *"  3- declare pre_drive_delay and post_drive_delay as random unsigned integers. remember that common fields are declared inside apb_item_base   "*
 *"  4- override convert2string() function to print addr, data, pre-drive and post-drive delays                                                   "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                               --- "Merge info" ---                                                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- include apb drive item inside apb package                                                                                                "*
 *"   2- create an instance of apb item drive inside drive transactions task inside apb driver                                                    "*
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
 *"                            |   ^              cfs_apb_sequencer           <^                   <^              ^   |                          "*
 *"                            |   ^>      >      cfs_apb_driver              <^                   <^              ^   |                          "*
 *"                            |   ^>      ^>     cfs_apb_coverage             ^       <           <^              ^   |                          "*
 *"                            |   ^>      ^>     cfs_apb_monitor              ^      <^           <^              ^   |                          "*
 *"                            |   ^>      <<<<<<<cfs_apb_agent_config         ^       ^            ^              ^   |                          "*
 *"                            |   ^                                           ^       ^            ^              ^   |                          "*
 *"                            |   ^                     ~-- cfs_apb_item_drv>>>       ^            ^              ^   |                  (o)     "*
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
