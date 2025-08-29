//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 8/1/25
// File      : ak_apb_agent.sv
// Status    : finished
// Goal      : creating an agent for apb protocol
// Instructor: Cristian Slav
// Tips      : read the code documentation below to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef AK_APB_AGENT_SV
  `define AK_APB_AGENT_SV
  class ak_apb_agent extends uvm_agent implements ak_apb_reset_handler;

    ak_apb_agent_config agent_config;                                                                                                                // Declaring a handler to apb agent configuration class
    ak_apb_sequencer sequencer;                                                                                                                      // Declaring a handler to apb sequencer class
    ak_apb_driver driver;                                                                                                                            // Declaring a handler to apb driver class
    ak_apb_monitor monitor;                                                                                                                          // Declaring a handler to apb monitor
    ak_apb_coverage coverage;                                                                                                                        // Declaring a handler to apb coverage
                                                                                                                                                     // Start of uvm component's mandatory code
    `uvm_component_utils(ak_apb_agent)                                                                                                               // APB agent is now registered with uvm factory & can use all utility methods & features

    function new(string name = "", uvm_component parent);                                                                                            // Declaration of constructor
      super.new(name, parent);
    endfunction
                                                                                                                                                     // End of mandatory code
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent_config = ak_apb_agent_config::type_id::create("agent_config", this);                                                                     // Creating an instance of apb agent configuration object inside apb agent
      monitor      = ak_apb_monitor::type_id::create("monitor", this);                                                                               // Creating an instance of apb monitor

      if(agent_config.get_has_coverage()) begin                                                                                                      // Checking if coverage is enabled
        coverage = ak_apb_coverage::type_id::create("coverage", this);                                                                               // Creating an instance of apb coverage
      end
      if(agent_config.get_active_passive() == UVM_ACTIVE) begin                                                                                      // Checking if the agent is active
        sequencer = ak_apb_sequencer::type_id::create("sequencer", this);                                                                            // Creating an instance of apb sequencer inside apb agent
        driver    = ak_apb_driver::type_id::create("driver", this);                                                                                  // Creating an instance of apb driver inside apb agent
      end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      ak_apb_vif vif;                                                                                                                                // Declaring a virtual interface to store apb virtual interface we got from uvm configuration
      super.connect_phase(phase);
      if(uvm_config_db#(ak_apb_vif)::get(this,"", "vif", vif) == 0) begin                                                                            // Getting apb virtual interface from uvm configuration database and checking if we get it successfully
        `uvm_fatal("APB_NO_VIF", "could not get APB virtual interface from the database")
      end
      else begin
        agent_config.set_vif(vif);
      end
      monitor.agent_config = agent_config;

      if(agent_config.get_has_coverage()) begin
        coverage.agent_config = agent_config;
        monitor.output_port.connect(coverage.port_item);
      end

      if(agent_config.get_active_passive() == UVM_ACTIVE) begin
        driver.agent_config = agent_config;
        driver.seq_item_port.connect(sequencer.seq_item_export);
      end

    endfunction

    virtual function void handle_reset(uvm_phase phase);
      uvm_component children[$];
      get_children(children);

      foreach (children[idx]) begin
        ak_apb_reset_handler reset_handler;

        if($cast(reset_handler, children[idx])) begin
          reset_handler.handle_reset(phase);
        end

      end
    endfunction

    virtual task wait_reset_start();
      agent_config.wait_reset_start();
    endtask

    virtual task wait_reset_end();
      agent_config.wait_reset_end();
    endtask

    virtual task run_phase(uvm_phase phase);
      forever begin
        wait_reset_start();
        handle_reset(phase);
        wait_reset_end();
      end
    endtask

  endclass
`endif








//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                         --- "Implementation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1-  extend apb agent from uvm agent                                                                                                         "*
 *"   2-  write mandatory code for uvm components                                                                                                 "*
 *"   3-  instantiate apb agent configuration class by declaring a handler inside apb agent                                                       "*
 *"   4-  create an agent configuration object inside build phase of apb agent                                                                    "*
 *"   5-  declare a virtual interface in the connect phase of apb agent to store apb virtual interface                                            "*
 *"   6-  get apb virtual interface (stored by the testbench inside uvm configuration database)                                                   "*
 *"   7-  set apb virtual interface inside apb agent configuration by using the set_vif() function                                                "*
 *"   8-  declare a handler to apb sequencer inside apb agent                                                                                     "*
 *"   9-  declare a handler to apb driver inside apb agent                                                                                        "*
 *"   11- create an instance of apb sequencer inside apb agent in the build phase based on the active passive field from agent configuration      "*
 *"   12- create an instance of apb driver inside apb agent in the build phase based on the active passive field from agent configuration         "*
 *"   13- connect sequence item port and sequence item export in apb agent inside connect phase                                                   "*
 *"   14- connect driver and agent configuration in apb agent inside connect phase                                                                "*
 *"   15- declare a handler to apb monitor inside apb agent                                                                                       "*
 *"   16- create an instance of apb monitor inside apb agent in the build phase                                                                   "*
 *"   17- connect monitor and agent configuration in apb agent inside connect phase                                                               "*
 *"   18- declare a handler to apb coverage inside apb agent                                                                                      "*
 *"   19- create an instance of apb coverage inside apb agent in the build phase based on the has_coverage field from agent configuration         "*
 *"   20- connect output port in the monitor with item port in the coverage                                                                       "*
 *"   21- connect coverage and agent configuration in apb agent inside connect phase                                                              "*
 *"   22- implement handle_reset() function in apb agent and specify that the agent class implements reset_handler class during declaration       "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                               --- "Merge info" ---                                                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- include apb agent inside apb package                                                                                                     "*
 *"   2- instantiate apb agent class by declaring a handler inside alinger environment                                                            "*
 *"   3- create an apb agent object inside build phase of alinger environment                                                                     "*
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
 *"            apb_if.sv       macros.svh                                                                               connections               "*
 *"                ↓           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+~~~~~~~~~~~               "*
 *"                ↓           | apb_pkg                                                                               | 1!, 2                    "*
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
 *"                 → → → → → →|   > ak_apb_agent  ↑  <<<<<<<<<<<<<<<<<<<<<<<<<^                    <              ^   |                  (o)     "*
 *"                            |   ^       ^      ak_apb_sequencer            <^                   <^              ^   |1----                     "*
 *"                            |   ^>      ^>     ak_apb_driver               <^                   <^              ^   |     ----1                "*
 *"                            |   ^>      ^>     ak_apb_coverage              ^       <           <^              ^   |     ----2                "*
 *"                            |   ^>      ^>     ak_apb_monitor               ^      <^           <^              ^   |2----                     "*
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
