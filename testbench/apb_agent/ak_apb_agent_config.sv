//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 8/1/25
// File      : ak_apb_agent_config.sv
// Status    : finished
// Goal      : configure apb agent and control how it operates
// Instructor: Cristian Slav
// Tips      : read the code documentation below to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef AK_APB_AGENT_CONFIG_SV
  `define AK_APB_AGENT_CONFIG_SV

  class ak_apb_agent_config extends uvm_component;                                                                                                   // Extend as a component to use features like uvm_phases and override

    local ak_apb_vif vif;                                                                                                                            // Declare as local apb agent config (can be accessed by getters and setters)

    local uvm_active_passive_enum active_passive;                                                                                                    // Determines if the agent is active or passive

    local bit has_checks;                                                                                                                            // Controls if the checks are active or not (checks switch)

    local bit has_coverage;                                                                                                                          // Controls if the agent has coverage or not (coverage switch)

    local int unsigned stuck_threshold;
                                                                                                                                                     // Start of uvm component's mandatory code
    `uvm_component_utils(ak_apb_agent_config)                                                                                                        // APB agent configuration is now registered with uvm factory & can use all utility methods & features
    function new(string name = "", uvm_component parent);                                                                                            // Mandatory code for uvm components
      super.new(name, parent);

      active_passive  = UVM_ACTIVE;                                                                                                                  // Agent is chosen to be active
      has_checks      = 1;                                                                                                                           // Checks are now enabled
      has_coverage    = 1;                                                                                                                           // Coverage is now enabled
      stuck_threshold = 1000;                                                                                                                        // #Max cycles for apb transaction
    endfunction
                                                                                                                                                     // End of mandatory code
    virtual function ak_apb_vif get_vif();
      return vif;
    endfunction

    virtual function void set_vif(ak_apb_vif value);
      if(vif == null) begin
        vif = value;
        set_has_checks(get_has_checks());
      end

      else begin
        `uvm_error("ALGORITHM ISSUE", "trying to set APB virtual interface more than once")
      end
    endfunction

    virtual function uvm_active_passive_enum get_active_passive();
    return active_passive;
    endfunction

    virtual function void set_active_passive(uvm_active_passive_enum value);
      active_passive = value;
    endfunction

    virtual function bit get_has_checks();
      return has_checks;
    endfunction

    virtual function void set_has_checks(bit value);
      has_checks = value;

      if(vif == null) begin
        vif.has_checks = has_checks;
      end
    endfunction

    virtual function bit get_has_coverage();
      return has_coverage;
    endfunction

    virtual function void set_has_coverage(bit value);
      has_coverage = value;
    endfunction

    virtual function void set_stuck_threshold(int unsigned value);
      if(value <= 2) begin                                                                                                                           // Duration of apb transfer must always be greater than 2 clock cycles
        `uvm_error("ALGORITHM_ISSUE", $sformatf("Trying to set the stuck threshold to %0d while the minimum transfer length in APB is 3 clock cycles", value))
      end
      stuck_threshold = value;
    endfunction

    virtual function int unsigned get_stuck_threshold();
      return stuck_threshold;
    endfunction


    virtual function void start_of_simulation_phase(uvm_phase phase);                                                                                // To make sure that vif is configured before run_phase()
      super.start_of_simulation_phase(phase);
      if(get_vif() == null) begin
        `uvm_error("ALGORITHM_ISSUE", "The apb virtual interface is not configured before run phase")
      end
      else begin
        `uvm_info("APB_CONFIG", "The apb virtual interface is configured at start of simulation phase", UVM_LOW)
      end

    endfunction

    virtual task run_phase(uvm_phase phase);
      forever begin
        @(vif.has_checks);
        if(vif.has_checks != get_has_checks()) begin                                                                                                 // Checks that the field from the virtual interface is the same to that of the agent configuration class
          `uvm_error("ALGORITHM_ISSUE", $sformatf("Cannot change \"has_checks\" from APB interface directly use %0s.set_has_checks()", get_full_name()))
        end
      end
    endtask

    virtual task wait_reset_start();
      if(vif.preset_n !== 0) begin
        @(negedge vif.preset_n);
      end
    endtask

    virtual task wait_reset_end();
      while(vif.preset_n === 0) begin
        @(posedge vif.pclk);
      end
    endtask
  endclass
`endif








//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                         --- "Implementation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1-  declare apb agent config class and extend as a component not as an object                                                               "*
 *"   2-  write the mandatory code                                                                                                                "*
 *"   3-  declare the virtual interface as a local variable                                                                                       "*
 *"   4-  implement get_vif() and set_vif() functions                                                                                             "*
 *"   5-  implement start_of_simulation() function to make sure that vif is configured correctly before run_phase()                               "*
 *"   6-  create an instance of active passive enum to choose whether the agent is active or passive                                              "*
 *"   7-  choose whether the agent is active or passive inside the constructor                                                                    "*
 *"   8-  inside the constructor choose whether the agent is active or passive                                                                    "*
 *"   9-  implement setters and getters for active_passive                                                                                        "*
 *"   10- declare has checks field to enable/disable checks                                                                                       "*
 *"   11- implement get_has_checks() and set_has_checks() functions                                                                               "*
 *"   12- check that has_checks field from the virtual interface is the same to that of agent configuration class in the run phase                "*
 *"   13- declare stuck_threshold field to control the maximum length of an apb transaction                                                       "*
 *"   14- implement get_stuck_threshold() and set_stuck_threshold() functions                                                                     "*
 *"   15- declare has_coverage field to enable/disable coverage                                                                                   "*
 *"   16- implement get_has_coverage() and set_has_coverage() functions                                                                           "*
 *"   17- implement wait_reset_start() to wait for the asynchronous reset signal to start                                                         "*
 *"   18- implement wait_reset_end() to wait for the asynchronous reset signal to end                                                             "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                               --- "Merge info" ---                                                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- include apb agent configuration inside apb package                                                                                       "*
 *"   2- instantiate apb agent configuration class by declaring a handler inside apb agent                                                        "*
 *"   3- create an apb agent configuration object inside build phase of apb agent                                                                 "*
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
 *"                            |   ^>      ^>     ak_apb_driver               <^                   <^              ^   |                          "*
 *"                            |   ^>      ^>     ak_apb_coverage              ^       <           <^              ^   |                          "*
 *"                            |   ^>      ^>     ak_apb_monitor               ^      <^           <^              ^   |                          "*
 *"                            |   ^>      <<<<<<<ak_apb_agent_config          ^       ^            ^              ^   |                  (o)     "*
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
