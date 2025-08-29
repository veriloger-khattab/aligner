//////////////////////////////////////////////////////////////////////////////////////////////////
// Author    : Ahmad Khattab
// Date      : 8/6/25
// File      : cfs_apb_coverage.sv
// Status    : finished
// Goal      : measuring verification progress of all possible scenarios in apb protocol
// Instructor: Cristian Slav
// Tips      : read the code documentation below to understand how the code works
//////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef CFS_APB_COVERAGE_SV
  `define CFS_APB_COVERAGE_SV

  `uvm_analysis_imp_decl(_item);

  virtual class cfs_apb_cover_index_wrapper_base extends uvm_component;
    function new(string name ="", uvm_component parent);
      super.new(name, parent);
    endfunction

    pure virtual function void sample(int unsigned value);

    pure virtual function string coverage2string();

  endclass

  class cfs_apb_cover_index_wrapper#(int unsigned MAX_VALUE_PLUS_1 = 16) extends cfs_apb_cover_index_wrapper_base;

    `uvm_component_param_utils(cfs_apb_cover_index_wrapper#(MAX_VALUE_PLUS_1))                                                                       // APB cover index wrapper is now registered with parameter aware uvm factory & can use all utility methods & features

    covergroup cover_index with function sample(int unsigned value);

      option.per_instance = 1;

      index : coverpoint value {
      option.comment = "Index";
      bins values[MAX_VALUE_PLUS_1] = {[0: MAX_VALUE_PLUS_1-1]};
      }
    endgroup


    function new(string name = "", uvm_component parent);
      super.new(name, parent);

      cover_index = new();
      cover_index.set_inst_name($sformatf("%s_%s", get_full_name(), "cover_index"));
    endfunction

    virtual function void sample (int unsigned value);
      cover_index.sample(value);
    endfunction

    virtual function string coverage2string();
      string result = {
        $sformatf("\n  cover_index:            %03.2f%%", cover_index.get_inst_coverage()),
        $sformatf("\n          index:          %03.2f%%", cover_index.index.get_inst_coverage())
      };
      return result;
    endfunction

  endclass





  class cfs_apb_coverage extends uvm_component implements cfs_apb_reset_handler;

    cfs_apb_agent_config agent_config;
    uvm_analysis_imp_item#(cfs_apb_item_mon, cfs_apb_coverage) port_item;                                                                            // Declaring an analysis port, through which the information will be received by the coverage from the monitor

    cfs_apb_cover_index_wrapper#(`CFS_APB_MAX_ADDR_WIDTH) wrap_cover_addr_0;
    cfs_apb_cover_index_wrapper#(`CFS_APB_MAX_ADDR_WIDTH) wrap_cover_addr_1;
    cfs_apb_cover_index_wrapper#(`CFS_APB_MAX_DATA_WIDTH) wrap_cover_wr_data_0;
    cfs_apb_cover_index_wrapper#(`CFS_APB_MAX_DATA_WIDTH) wrap_cover_wr_data_1;
    cfs_apb_cover_index_wrapper#(`CFS_APB_MAX_DATA_WIDTH) wrap_cover_rd_data_0;
    cfs_apb_cover_index_wrapper#(`CFS_APB_MAX_DATA_WIDTH) wrap_cover_rd_data_1;

    `uvm_component_utils(cfs_apb_coverage)                                                                                                           // APB coverage is now registered with uvm factory & can use all utility methods & features

    covergroup cover_item with function sample(cfs_apb_item_mon item);
      option.per_instance = 1;                                                                                                                       // Collect coverage for each instance of the agent

      direction : coverpoint item.dir {
      option.comment = "Direction of the APB access";
      }

      response : coverpoint item.response {
      option.comment = "Response of the APB access";
      }

      length : coverpoint item.length {
      option.comment = "Length of the APB access";

      bins length_eq_2     = {2};
      bins length_le_10[8] = {[3:10]};
      bins length_gt_10    = {[11:$]};
      }

      prev_item_delay : coverpoint item.prev_item_delay {
      option.comment = "Delay, in clock cycles between two consecutive apb accesses";

      bins back2back  = {0};
      bins delay_le_5 = {[1:5]};
      bins delay_gt_5 = {[6:$]};
      }

      response_x_direction : cross response, direction;

      trans_direction : coverpoint item.dir {
        option.comment = "Transitions of the APB direction";
        bins direction_trans[] = (CFS_APB_READ, CFS_APB_WRITE => CFS_APB_READ, CFS_APB_WRITE);
      }

    endgroup

    covergroup cover_reset with function sample(bit psel);                                                                                           // To cover if reset came while a transaction was ongoing 
      option.per_instance = 1;

      access_ongoing : coverpoint psel {
      option.comment = "reset was applied while an APB access was ongoing";
      }

    endgroup

    function new(string name = "", uvm_component parent);
      super.new(name, parent);
      port_item  = new("port_item", this);                                                                                                           // Creating an instance of port item, through which the information will be received by the coverage from the monitor
      cover_item = new();                                                                                                                            // Creating an instance of the cover group in the constructor of the coverage component
      cover_item.set_inst_name($sformatf("%s_%s", get_full_name(), "cover_item"));
      cover_reset = new();
      cover_reset.set_inst_name($sformatf("%s_%s", get_full_name(), "cover_reset"));
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      wrap_cover_addr_0    = cfs_apb_cover_index_wrapper#(`CFS_APB_MAX_ADDR_WIDTH)::type_id::create("wrap_cover_addr_0",    this);
      wrap_cover_addr_1    = cfs_apb_cover_index_wrapper#(`CFS_APB_MAX_ADDR_WIDTH)::type_id::create("wrap_cover_addr_1",    this);
      wrap_cover_wr_data_0 = cfs_apb_cover_index_wrapper#(`CFS_APB_MAX_DATA_WIDTH)::type_id::create("wrap_cover_wr_data_0", this);
      wrap_cover_wr_data_1 = cfs_apb_cover_index_wrapper#(`CFS_APB_MAX_DATA_WIDTH)::type_id::create("wrap_cover_wr_data_1", this);
      wrap_cover_rd_data_0 = cfs_apb_cover_index_wrapper#(`CFS_APB_MAX_DATA_WIDTH)::type_id::create("wrap_cover_rd_data_0", this);
      wrap_cover_rd_data_1 = cfs_apb_cover_index_wrapper#(`CFS_APB_MAX_DATA_WIDTH)::type_id::create("wrap_cover_rd_data_1", this);
    endfunction

    virtual function void handle_reset(uvm_phase phase);
      cfs_apb_vif vif = agent_config.get_vif();
      cover_reset.sample(vif.psel);
    endfunction

    virtual function string coverage2string();                                                                                                       // This should not be implemented in real projects as tools have built in ways to print the coverage
      string result = {
        $sformatf("\n  cover_item:                 %03.2f%%", cover_item.get_inst_coverage()),
        $sformatf("\n      direction:              %03.2f%%", cover_item.direction.get_inst_coverage()),
        $sformatf("\n      response:               %03.2f%%", cover_item.response.get_inst_coverage()),
        $sformatf("\n      length:                 %03.2f%%", cover_item.length.get_inst_coverage()),
        $sformatf("\n      prev_item_delay:        %03.2f%%", cover_item.prev_item_delay.get_inst_coverage()),
        $sformatf("\n      response_x_direction:   %03.2f%%", cover_item.response_x_direction.get_inst_coverage()),
        $sformatf("\n      trans_direction:        %03.2f%%", cover_item.trans_direction.get_inst_coverage()),
        $sformatf("\n"),
        $sformatf("\n  cover_reset:                %03.2f%%", cover_reset.get_inst_coverage()),
        $sformatf("\n      access_ongoing:         %03.2f%%", cover_reset.access_ongoing.get_inst_coverage())

      };

      uvm_component children[$];
      get_children(children);

      foreach (children[idx]) begin
        cfs_apb_cover_index_wrapper_base wrapper;

        if($cast(wrapper, children[idx])) begin
          result = $sformatf("%0s\n\nChild component: %0s %0s", result, wrapper.get_name(), wrapper.coverage2string());
        end
      end
      return result;
    endfunction

    virtual function void write_item(cfs_apb_item_mon item);                                                                                         // Write function associated with port item
      cover_item.sample(item);

      for(int i = 0 ; i < `CFS_APB_MAX_ADDR_WIDTH; i++) begin
        if(item.addr[i]) begin
          wrap_cover_addr_1.sample(i);
        end
        else begin
          wrap_cover_addr_0.sample(i);
        end
      end

       for(int i = 0 ; i < `CFS_APB_MAX_DATA_WIDTH; i++) begin
         case(item.dir)
           CFS_APB_WRITE : begin
              if(item.data[i]) begin
                wrap_cover_wr_data_1.sample(i);
              end
              else begin
                wrap_cover_wr_data_0.sample(i);
              end
           end

           CFS_APB_READ : begin
              if(item.data[i]) begin
                wrap_cover_rd_data_1.sample(i);
              end
              else begin
                wrap_cover_rd_data_0.sample(i);
              end
           end

           default : begin
             `uvm_error("ALGORITHM_ISSUE", $sformatf("Current version of the code does not support item_dir: %0s", item.dir.name()))
           end
         endcase
      end


      `uvm_info("DEBUG", $sformatf("Coverage: %0s", coverage2string()), UVM_NONE)                                                                    // This should not be implemented in real projects as tools have built in ways to print the coverage
    endfunction
  endclass

`endif








//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                         --- "Implementation steps" ---                                                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1-  extend apb coverage from uvm component                                                                                                  "*
 *"   2-  write mandatory code for uvm components                                                                                                 "*
 *"   3-  create covergroup called cover item and create cover points with information coming from the monitor inside it                          "*
 *"   4-  create an instance of the covergroup in the constructor of the coverage component                                                       "*
 *"   5-  declare an analysis port, through which we will get information from the monitor                                                        "*
 *"   6-  create an instance of the analysis port                                                                                                 "*
 *"   7-  implement the write function associated with item port                                                                                  "*
 *"   8-  keep adding cover items like length, prev_item_delay, cross coverage between response & length, transition coverage for direction       "*                                                                          
 *"   9-  implement coverage2string() function to print coverage information                                                                      "*
 *"   10- implement cfs_apb_cover_index_wrapper to calculate coverage for the addresses and data                                                  "*
 *"   11- implement coverage2string() function for wrapper class                                                                                  "*
 *"   12- declare and create 6 instances of the wrapper class two for address and four for data                                                   "*
 *"   13- sample all bit in address and all bits in data inside the write method                                                                  "*
 *"   14- implement sample function inside the wrapper                                                                                            "*
 *"   15- declare a virtual class for the wrapper to make casting easier and print the coverage without writing too much code                     "*
 *"   16- create a covergroup called cover_reset to cover when a reset is triggered during an active transcation                                  "*
 *"   17- declare a pointer to apb agent configuration class                                                                                      "*
 *"   18- implement handle_reset() function in apb coverage and specify that the coverage class implements reset_handler class during declaration "*
 *                                                                                                                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */




//////////////////////////////////////////////////////ENABLE DOCS BY REMOVING "/" IN THE NEXT LINE//////////////////////////////////////////////////
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                               --- "Merge info" ---                                                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                                                                                                                 *
 *"   1- include apb coverage inside apb package                                                                                                  "*
 *"   2- declare a handler to apb coverage inside apb agent                                                                                       "*
 *"   3- create an instance of apb coverage inside apb agent in the build phase based on the has_coverage field from agent configuration          "*
 *"   4- connect output port in the monitor with item port in the coverage                                                                        "*
 *"   5- connect coverage and agent configuration in apb agent inside connect phase                                                               "*
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
 *"                            |   ^>      ^>     cfs_apb_coverage             ^       <           <^              ^   |                  (o)     "*
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
