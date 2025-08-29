//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 8/5/25
// File      : ak_apb_monitor.sv
// Status    : finished
// Goal      : observing dut signals and broadcasting them to other components
// Instructor: Cristian Slav
// Tips      : read the code documentation below to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef AK_APB_MONITOR_SV
  `define AK_APB_MONITOR_SV

  class ak_apb_monitor extends uvm_monitor implements ak_apb_reset_handler;

    ak_apb_agent_config agent_config;                                                                                                                // Pointer to apb agent configuration class
    uvm_analysis_port#(ak_apb_item_mon) output_port;

    protected process process_collect_transactions;
                                                                                                                                                     // Start of uvm component's mandatory code
    `uvm_component_utils(ak_apb_monitor)                                                                                                             // APB monitor is now registered with uvm factory & can use all utility methods & features

    function new(string name = "", uvm_component parent);                                                                                            // Declaration of constructor
      super.new(name, parent);
      output_port = new("output_port", this);
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
            collect_transactions();
            disable fork;
          end
        join
      end
    endtask


    protected virtual task collect_transaction();
      ak_apb_vif vif = agent_config.get_vif();                                                                                                       // Getting the pointer to the virtual interface
      ak_apb_item_mon item = ak_apb_item_mon::type_id::create("item");

      while(vif.psel !== 1) begin                                                                                                                    // Counting how many cycles it take before the item starts
        @(posedge vif.pclk);
        item.prev_item_delay++;
      end
                                                                                                                                                     // Start of item transaction
      item.addr = vif.paddr;
      item.dir  = ak_apb_dir'(vif.pwrite);
      if(item.dir == AK_APB_WRITE) begin
        item.data = vif.pwdata;
      end

      item.length = 1;                                                                                                                               // The length of the transaction item is one at this point
      @(posedge vif.pclk);
      item.length++;

      while(vif.pready !== 1) begin
        @(posedge vif.pclk);
        item.length++;
        if(agent_config.get_has_checks()) begin
          if(item.length >= agent_config.get_stuck_threshold()) begin
            `uvm_error("PROTOCOL ERROR", $sformatf("The APB transfer is stuck and it has reaches its threshold of %0d clock cycles", item.length))
          end
        end
      end
                                                                                                                                                     // End of item transaction
      item.response = ak_apb_response'(vif.pslverr);
      if(item.dir == AK_APB_READ) begin
        item.data = vif.prdata;
      end

      output_port.write(item);                                                                                                                       // Sending all collected information on output port
      `uvm_info("DEBUG", $sformatf("Monitored item: %0s", item.convert2string()), UVM_NONE)                                                          // Printing collected information after sending it to output port
      @(posedge vif.pclk);

    endtask

    protected virtual task collect_transactions();
      fork
        begin
          process_collect_transactions = process::self();
          forever begin
            collect_transaction();
          end
        end
      join
    endtask

    virtual function void handle_reset(uvm_phase phase);
      if(process_collect_transactions != null) begin
        process_collect_transactions.kill();
      end
      process_collect_transactions = null;
    endfunction
  endclass
`endif




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                              --- "Code Guide" ---                                                               *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"  The aligner environment will basically include all other components as we move forward, remember that it must be included in the base test   "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                         --- "Implementation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1-  declare apb monitor class and extend it from uvm monitor                                                                                "*
 *"   2-  write mandatory code for uvm components                                                                                                 "*
 *"   3-  declare a pointer to apb agent configuration class                                                                                      "*
 *"   4-  inside run phase, wait until reset ends then start to collect transactions                                                              "*
 *"   5-  implement collect transactions task                                                                                                     "*
 *"   6-  implement collect transaction task                                                                                                      "*
 *"   7-  implement handle_reset() function in apb monitor and specify that the monitor class implements reset_handler class during declaration   "*
 *"   8-  implement wait_reset_end() task                                                                                                         "*
 *"   9-  wait for reset to end before collecting transactions in the run phase                                                                   "*
 *"   10- create a process pointer to collect_transactions task                                                                                   "*
 *"   11- move initialization code inside handle_reset() function and do not forget to kill the process of collecting transactions                "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                               --- "Merge info" ---                                                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- include apb monitor inside apb package                                                                                                   "*
 *"   2- declare a handler to apb monitor inside apb agent                                                                                        "*
 *"   3- create an instance of apb monitor inside apb agent in the build phase                                                                    "*
 *"   4- connect monitor and agent configuration in apb agent inside connect phase                                                                "*
 *"   5- connect output port in the monitor with item port in the coverage                                                                        "*
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
 *"                            |   ^>      >      ak_apb_driver               <^                   <^              ^   |                          "*
 *"                            |   ^>      ^>     ak_apb_coverage              ^       <           <^              ^   |                          "*
 *"                            |   ^>      ^>     ak_apb_monitor               ^      <^           <^              ^   |                  (o)     "*
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
