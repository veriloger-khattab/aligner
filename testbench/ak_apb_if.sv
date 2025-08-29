//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 8/1/25
// File      : cfs_apb_if.sv
// Status    : finished
// Goal      : connecting apb agent's components with dut's apb signals using interface signals
// Instructor: Cristian Slav
// Tips      : read the code documentation below to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef CFS_APB_IF_SV
  `define CFS_APB_IF_SV

  `ifndef CFS_APB_MAX_ADDR_WIDTH
    `define CFS_APB_MAX_ADDR_WIDTH 16
  `endif

  `ifndef CFS_APB_MAX_DATA_WIDTH
    `define CFS_APB_MAX_DATA_WIDTH 32
  `endif

  interface cfs_apb_if(input pclk);                                                                                                                  // clock signal is never driven by the environment

    logic preset_n;
    logic [`CFS_APB_MAX_ADDR_WIDTH-1:0] paddr;
    logic [`CFS_APB_MAX_DATA_WIDTH-1:0] prdata;
    logic [`CFS_APB_MAX_DATA_WIDTH-1:0] pwdata;
    logic penable;
    logic psel;
    logic pready;
    logic pwrite;
    logic pslverr;

    bit has_checks;                                                                                                                                  // This field must also be declared here, has_checks from the agent configuration class cannot be accessed from here

    initial begin
      has_checks = 1;
    end

    sequence setup_phase_s;
      (psel == 1) && (($past(psel) == 0) || (($past(psel) == 1) & ($past(pready) == 1)));
    endsequence

    sequence access_phase_s;
      (psel == 1) && (penable == 1);
    endsequence

    property penable_at_setup_phase_p;                                                                                                               // penable must be zero in setup phase
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      setup_phase_s |-> penable == 0;
    endproperty

    PENABLE_AT_SETUP_PHASE_A : assert property(penable_at_setup_phase_p) else $error("penable at \"Setup Phase\" is not equal to zero");


    property penable_entering_access_phase_p;                                                                                                        // penable must be one in access phase (one clock cycle after setup phase)
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      setup_phase_s |=> penable == 1;
    endproperty

    PENABLE_ENTERING_ACCESS_PHASE_A : assert property(penable_entering_access_phase_p) else $error("penable upon entering \"Access Phase\" is not equal to one");


    property penable_exiting_access_phase_p;                                                                                                         // penable must be zero after exiting the access phase
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      access_phase_s and (pready ==1) |=> penable == 0;
    endproperty

    PENABLE_EXITING_ACCESS_PHASE_A : assert property(penable_exiting_access_phase_p) else $error("penable when exiting \"Access Phase\" is not equal to zero");


    property penable_stable_at_access_phase_p;                                                                                                       // penable must be asserted during access phase (redundant property)
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      access_phase_s |-> penable == 1;
    endproperty

    PENABLE_STALBE_AT_ACCESS_PHASE_A : assert property(penable_stable_at_access_phase_p) else $error("penable was not stable during \"Access Phase\"");


    property pwrite_stable_at_access_phase_p;                                                                                                        // pwrite must be stable during access phase
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      access_phase_s |-> $stable(pwrite);
    endproperty

    PWRITE_STABLE_AT_ACCESS_PHASE_A : assert property(pwrite_stable_at_access_phase_p) else $error("pwrite was not stable during \"Access Phase\"");


    property paddr_stable_at_access_phase_p;                                                                                                         // paddr must be stable during access phase
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      access_phase_s |-> $stable(paddr);
    endproperty

    PADDR_STABLE_AT_ACCESS_PHASE_A : assert property(paddr_stable_at_access_phase_p) else $error("paddr was not stable during \"Access Phase\"");


    property pwdata_stable_at_access_phase_p;                                                                                                        // pwdata must be stable during access phase
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      access_phase_s and (pwrite == 1) |-> $stable(pwdata);
    endproperty

    PWDATA_STABLE_AT_ACCESS_PHASE_A : assert property(pwdata_stable_at_access_phase_p) else $error("pwdata was not stable during \"Access Phase\"");


    property unknown_value_psel_p;                                                                                                                   // psel cannot be unknown
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      $isunknown(psel) == 0;
    endproperty

    UNKNOWN_VALUE_PSEL_A : assert property(unknown_value_psel_p) else $error("Unknown value for psel was detected");


    property unknown_value_penable_p;                                                                                                                // penable cannot be unknown in access phase
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      psel == 1 |-> $isunknown(penable) == 0;
    endproperty

    UNKNOWN_VALUE_PENABLE_A : assert property(unknown_value_penable_p) else $error("Unknown value for penable was detected");


    property unknown_value_pwrite_p;                                                                                                                 // pwrite cannot be unknown in access phase
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      psel == 1 |-> $isunknown(pwrite) == 0;
    endproperty

    UNKNOWN_VALUE_PWRITE_A : assert property(unknown_value_pwrite_p) else $error("Unknown value for pwrite was detected");


    property unknown_value_paddr_p;                                                                                                                  // paddr cannot be unknown in access phase
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      psel == 1 |-> $isunknown(paddr) == 0;
    endproperty

    UNKNOWN_VALUE_PADDR_A : assert property(unknown_value_paddr_p) else $error("Unknown value for paddr was detected");


    property unknown_value_pwdata_p;                                                                                                                 // pwdata cannot be unknown during write accesses
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      (psel == 1) && (pwrite == 1) |-> $isunknown(pwdata) == 0;
    endproperty

    UNKNOWN_VALUE_PWDATA_A : assert property(unknown_value_pwdata_p) else $error("Unknown value for pwdata was detected");


    property unknown_value_prdata_p;                                                                                                                 // prdata cannot be unknown when the read data is returned and pready is one and pslverr is zero
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      (psel == 1) && (pwrite == 0) && (pslverr == 0) && (pready == 1) |-> $isunknown(prdata) == 0;
    endproperty

    UNKKNOWN_VALUE_PRDATA_A : assert property(unknown_value_prdata_p) else $error("Unknown value for prdata was detected");


    property unknown_value_pready_p;                                                                                                                 // pready cannot have unkown value throughout the transfer
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      psel == 1 |-> $isunknown(pready) == 0;
    endproperty

    UNKNOWN_VALUE_PREADY_A : assert property(unknown_value_pready_p) else $error("Unknown value for pready was detected");


    property unknown_value_pslverr_p;                                                                                                                // pslverr cannot have an unknown value when ter response is ready
      @(posedge pclk) disable iff(!preset_n || !has_checks)
      (psel == 1) && (pready == 1) |-> $isunknown(pslverr) == 0;
    endproperty

    UNKNOWN_VALUE_PSLVERR_A : assert property(unknown_value_pslverr_p) else $error("Unknown value for pslverr was detected");

  endinterface

`endif




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                              --- "Code Guide" ---                                                               *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"  This interface enables apb_agent to communicate with aligner.                                                                                "*
 *"  In reality the interface is instantiated inside the testbench as it cannot be created inside a systemverilog class like apb_agent.           "*
 *"  To access it we need a pointer of it inside apb_agent. This can be done by the help of uvm_config_db                                         "*
 *"                                                                                                                                               "*
 *      uvm_config_db#(data_type_of_stored_thing)::set(this, "full_name_from_next_component", "stored_thing_name", stored_thing)                   *
 *"                                                                                                                                               "*
 *"     Priority is for highest heirarchy component if get happens during build phase                                                             "*
 *"     Priority is for the last value set the in database during run_phase                                                                       "*
 *"     The set function supports the star notation :) which means that the stored_thing can be stored in current and lower heirarchy components  "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                         --- "Implementation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *                                                                                                                                                 *
 *"   1- declare interface with the testbench clock as input                                                                                      "*
 *"   2- declare all apb signals inside the interface and parameterize parameters outside the interface using `define statements for flexibility  "*
 *                                                                                                                                                 *
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                --- "Phases" ---                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *                                                                                                                                                 *
 *"   1- Setup phase                                                                                                                              "*
 *"                   - psel must be one in the current cycle and psel must be zero in the previous cycle                                         "*
 *"      OR           - psel must be one in the current cycle and both psel and pready must be one in the previous cycle (back2back transaction)  "*
 *"                                                                                                                                               "*
 *"                                                                                                                                               "*
 *"   2- Access phase                                                                                                                             "*
 *"                   - both psel and penable must be one simultaneously                                                                          "*
 *                                                                                                                                                 *
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                            --- "Protocol checks" ---                                                            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *                                                                                                                                                 *
 *"   1- PEMABLE must be asserted in the second cycle of transfer                                                     (implemented in interface)  "*
 *"                                                                                                                                               "*
 *"   2- PEMABLE must be deasserted at the end of transfer                                                            (implemented in interface)  "*
 *"                                                                                                                                               "*
 *"   3- Master driven signals must remain constant throughout the transfer                                           (implemented in interface)  "*
 *"                                                                                                                                               "*
 *"   4- APB signals cannot have unknown values (x or z)                                                              (implemented in interface)  "*
 *"                                                                                                                                               "*
 *"   5- APB transfer cannot have an infinite length                                                                  (implemented in monitor)    "*
 *                                                                                                                                                 *
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                               --- "Merge info" ---                                                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- include apb interface outside apb package                                                                                                "*
 *"   2- instantiate apb interface inside the testbench                                                                                           "*
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
 *"     (o)    apb_if.sv       macros.svh                                                                                                         "*
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
