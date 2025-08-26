//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 7/8/25
// File      : cfs_algn_test_reg_access.sv
// Status    : not finalized
// Goal      : testing accessing aligner's registers
// Instructor: Cristian Slav
// Tips      : read the code documentation below to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef CFS_ALGN_TEST_REG_ACCESS_SV
  `define CFS_ALGN_TEST_REG_ACCESS_SV

  class cfs_algn_test_reg_access extends cfs_algn_test_base;                                                                                         // Reg access test inherit from base test

    `uvm_component_utils(cfs_algn_test_reg_access)                                                                                                   // Aligner register access test is now registered with uvm factory & can use all utility methods & features

    function new(string name = "", uvm_component parent);                                                                                            // Mandatory code for uvm components (declaration of constructor)
      super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);                                                                                                         // Simulation stops when the objection counter drops to 0
      phase.raise_objection(this, "TEST_DONE");                                                                                                      // It acts as an up counter
      #(100ns);


      fork                                                                                                                                           // Now all the sequences are running in parallel. Hence, the test is more random
        begin                                                                                                                                        // This tests what happen to the components and signals when reset is applied
          cfs_apb_vif vif = env.apb_agent.agent_config.get_vif();
          repeat(3) begin
            @(posedge vif.psel);
          end
          #11ns;
          vif.preset_n <= 0;
          repeat(4) begin
            @(posedge vif.pclk);
          end
          vif.preset_n <= 1;
        end
        begin
          cfs_apb_sequence_simple seq_simple = cfs_apb_sequence_simple::type_id::create("seq_simple");
          void'(seq_simple.randomize() with{
            item.addr == 'h0;                                                                                                                        // Constraining the simple sequence to access the control register
            item.dir  == CFS_APB_WRITE;
            item.data == 'h11;
            });

          seq_simple.start(env.apb_agent.sequencer);
        end

        begin
          cfs_apb_sequence_rw seq_rw = cfs_apb_sequence_rw::type_id::create("seq_rw");
          void'(seq_rw.randomize() with{
            addr == 'hC;                                                                                                                             // Constraining the read write sequence to access the status register (writing returns p slave error)
            });

          seq_rw.start(env.apb_agent.sequencer);

        end

        begin
          cfs_apb_sequence_random seq_random = cfs_apb_sequence_random::type_id::create("seq_random");
          void'(seq_random.randomize() with{
            num_items == 3;
            });

          seq_random.start(env.apb_agent.sequencer);
        end
      join

      begin
        cfs_apb_sequence_random seq_random = cfs_apb_sequence_random::type_id::create("seq_random");
        void'(seq_random.randomize() with{
          num_items == 3;
        });

       seq_random.start(env.apb_agent.sequencer);
      end

      #(100ns);

      `uvm_info("DEBUG", "end of test", UVM_LOW)
      phase.drop_objection(this, "TEST_DONE");                                                     // It acts as a down counter
    endtask

  endclass

`endif




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                              --- "Code Guide" ---                                                               *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"  The reg access test will access the registers inside the aligner, for now the test prints start of test, waits 100ns and prints end of test  "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                         --- "Implementation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- declare aligner register access test class and extend it from alinger base test                                                          "*
 *"   2- Write mandatory code                                                                                                                     "*
 *"   3- implement virtual task run_phase() and this is what will run during the simulation starting from raising objection to dropping it        "*
 *"   4- create an instance of apb simple sequence in register access test inside run phase                                                       "*
 *"   5- start the simple sequence by sending it to the sequencer                                                                                 "*
 *"   6- create an instance of apb read write sequence in register access test inside run phase                                                   "*
 *"   7- start the read write sequence by sending it to the sequencer                                                                             "*
 *"   8- create an instance of apb random sequence in register access test inside run phase                                                       "*
 *"   9- start the random sequence by sending 3 simple sequences to the sequencer                                                                 "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                               --- "Merge info" ---                                                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- include register access test files inside the test package                                                                               "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */



//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                        --- "Test inheritance tree" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"                                                                                                                                               "*
 *"                                     ~--- cfs_algn_test_random                                                                                 "*
 *"                                     |                                                                                                         "*
 *"   uvm_test <- cfs_algn_test_base <--~--- cfs_algn_test_reg_access                                             We are here now         (o)     "*
 *"                                     |                                                                                                         "*
 *"                                     ~--- cfs_algn_test_illegal_rx                                                                             "*
 *"                                                                                                                                               "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */





//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                            --- "Diagarm Hierarchy" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   testbench                                                                                                                                   "*
 *"            tests                                                                         reg access        <- We are here now         (o)     "*
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

