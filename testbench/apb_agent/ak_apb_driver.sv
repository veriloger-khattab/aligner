//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 8/4/25
// File      : ak_apb_driver.sv
// Status    : finished
// Goal      : take transactions from the sequencer and drive them on the bus
// Instructor: Cristian Slav
// Tips      : read the code documentation below to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef AK_APB_DRIVER_SV
  `define AK_APB_DRIVER_SV

  class ak_apb_driver extends uvm_driver#(.REQ(ak_apb_item_drv)) implements ak_apb_reset_handler;

    ak_apb_agent_config agent_config;                                                                                                                // Pointer to apb agent configuration class

    protected process process_drive_transactions;
                                                                                                                                                     // Start of uvm component's mandatory code
    `uvm_component_utils(ak_apb_driver)                                                                                                              // APB driver is now registered with uvm factory & can use all utility methods & features

    function new(string name = "", uvm_component parent);                                                                                            // Declaration of constructor
      super.new(name, parent);
    endfunction
                                                                                                                                                     // End of mandatory code
    virtual task wait_reset_end();
      agent_config.wait_reset_end();
    endtask

    virtual task run_phase(uvm_phase phase);
      forever begin
        fork
          begin
            wait_reset_end();
            drive_transactions();
            disable fork;
          end
        join
      end

    endtask

    protected virtual task drive_transactions();
      fork
        begin
          process_drive_transactions = process::self();
          forever begin
            ak_apb_item_drv item;

            seq_item_port.get_next_item(item);                                                                                                       // Getting information driven by the sequence to driver through the item pointer
            drive_transaction(item);
            seq_item_port.item_done();
          end
        end
      join
    endtask

    protected virtual task drive_transaction(ak_apb_item_drv item);
      ak_apb_vif vif = agent_config.get_vif();                                                                                                       // Getting the pointer to the virtual interface
      `uvm_info("DEBUG", $sformatf("Driving \"%0s\": %s", item.get_full_name(), item.convert2string()), UVM_NONE)                                    // We can now see which sequence was driving a particular item
                                                                                                                                                     // Start of pre drive delay
      for(int i = 0; i < item.pre_drive_delay; i++) begin
        @(posedge vif.pclk);
      end
                                                                                                                                                     // End of pre drive delay
                                                                                                                                                     // Start of setup phase
      vif.psel   <= 1;
      vif.pwrite <= bit'(item.dir);
      vif.paddr  <= item.addr;

      if(item.dir == AK_APB_WRITE) begin
        vif.pwdata <= item.data;
      end
      @(posedge vif.pclk);
      vif.penable <= 1;
                                                                                                                                                     // End of setup phase
                                                                                                                                                     // Start of access phase
      @(posedge vif.pclk);

      while(vif.pready !== 1) begin
        @(posedge vif.pclk);
      end
                                                                                                                                                     // End of transfer
      vif.psel    <= 0;
      vif.penable <= 0;
      vif.pwrite  <= 0;
      vif.paddr   <= 0;
      vif.pwdata  <= 0;
                                                                                                                                                     // Start of post drive delay
      for(int i = 0; i < item.post_drive_delay; i++) begin
        @(posedge vif.pclk);
      end
                                                                                                                                                     // End of post drive delay
    endtask

    virtual function void handle_reset(uvm_phase phase);
      ak_apb_vif vif = agent_config.get_vif();
      if(process_drive_transactions != null) begin
        process_drive_transactions.kill();
        process_drive_transactions = null;
      end
                                                                                                                                                     // Always use non-blocking assignments to sample correctly at the dut
      vif.psel    <= 0;
      vif.penable <= 0;
      vif.pwrite  <= 0;
      vif.paddr   <= 0;
      vif.pwdata  <= 0;
    endfunction
  endclass
`endif








//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                         --- "Implementation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1-  declare apb driver and extend it from uvm driver that is parameterized with apb item drive                                              "*
 *"   2-  Write the mandatory code for uvm component                                                                                              "*
 *"   3-  declare a pointer to apb agent configuration class                                                                                      "*
 *"   4-  inside run phase, wait until reset ends then start to drive transactions                                                                "*
 *"   5-  implement drive transactions task                                                                                                       "*
 *"   6-  implement drive transaction task                                                                                                        "*
 *"   7-  implement handle_reset() function in apb driver and specify that the driver class implements reset_handler class during declaration     "*
 *"   8-  implement wait_reset_end() task                                                                                                         "*
 *"   9-  wait for reset to end before driving transactions in the run phase                                                                      "*
 *"   10- create a process pointer to drive_transactions task                                                                                     "*
 *"   11- move initialization code inside handle_reset() function and do not forget to kill the process of driving transactions                   "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                               --- "Merge info" ---                                                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- include apb driver inside apb package                                                                                                    "*
 *"   2- declare a handler to apb driver inside apb agent                                                                                         "*
 *"   3- create an instance of apb driver inside apb agent in the build phase based on the active passive field from agent configuration          "*
 *"   4- connect sequence item port and sequence item export in apb agent inside connect phase                                                    "*
 *"   5- connect driver and agent configuration in apb agent inside connect phase                                                                 "*
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
 *"                ↓           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+                          "*
 *"                ↓           | apb_pkg                                                                               |                          "*
 *"                ↓           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                          "*
 *"                ↓set        | uvm_pkg::*                                                                            |                          "*
 *"         -----------------  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                          "*
 *"         | uvm_config_db |  |                                                                                       |                          "*
 *"         |               |  |                            ~--- ak_apb_sequence_random <<<                            |                          "*
 *"         |    apb_vif    |  |                            |                             ^                            |                          "*
 *"         -----------------  |     ak_apb_sequence_base <-~--- ak_apb_sequence_rw       ^                        <   |                          "*
 *"                ↓           |                   ↑  ^     |                             ^                        ^   |                          "*
 *"                ↓           |                   ↑  ^     ~--- ak_apb_sequence_simple >>>                        ^   |                          "*
 *"                ↓       get |                   ↑  ^                        ^                                   ^   |                          "*
 *"                 → → → → → →|   > ak_apb_agent  ↑  <<<<<<<<<<<<<<<<<<<<<<<<<^                    <              ^   |                          "*
 *"                            |   ^       ^      ak_apb_sequencer            <^                   <^              ^   |                          "*
 *"                            |   ^>      >      ak_apb_driver               <^                   <^              ^   |                  (o)     "*
 *"                            |   ^>      ^>     ak_apb_coverage              ^       <           <^              ^   |                          "*
 *"                            |   ^>      ^>     ak_apb_monitor               ^      <^           <^              ^   |                          "*
 *"                            |   ^>      <<<<<<<ak_apb_agent_config          ^       ^            ^              ^   |                          "*
 *"                            |   ^                                           ^       ^            ^              ^   |                          "*
 *"                            |   ^                     ~-- ak_apb_item_drv >>>       ^            ^              ^   |                          "*
 *"                            |   ^                     |                             ^            ^              ^   |                          "*
 *"                            |   ^> ak_apb_item_base <-~                             ^            ^              ^   |                          "*
 *"                            |   ^                     |                             ^            ^              ^   |                          "*
 *"                            |   ^                     ~-- ak_apb_item_mon >>>>>>>>>>>            ^              ^   |                          "*
 *"                            |   ^                         ^                                      ^              ^   |                          "*
 *"                            |   ^                         ^                              ak_apb_reset_handler   ^   |                          "*
 *"                            |   ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ak_apb_types >>>>>>>>>>>   |                          "*
 *"                            |                                                                                       |                          "*
 *"                            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                          "*
 *"            dut                                                                                                                                "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
