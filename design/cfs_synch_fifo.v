///////////////////////////////////////////////////////////////////////////////
// File:        cfs_synch_fifo.v
// Instructor:  Cristian Florin Slav
// Date:        2023-06-26
// Description: Syncronization FIFO to move data from the 'push_clk' clock 
//              domain to the 'pop_clk' clock domain.
//              When used in a Clock Domain Crossing scenario (CDC = 1), 
//              due to synchronization requirements, data is passed slower so 
//              delay cycles are to be expected.
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_SYNCH_FIFO_V
  `define CFS_SYNCH_FIFO_V

  module cfs_synch_fifo #(
     parameter DATA_WIDTH = 32,
     parameter FIFO_DEPTH = 8,
     //Clock Domain Crossing
     //Set this parameter to 0 only if push_clk and pop_clk are tied to the same clock signal.
     parameter CDC        = 1,
    
    localparam CNT_WIDTH = $clog2(FIFO_DEPTH)
  ) (
    input                       reset_n,

    input                       push_clk,
    input                       push_valid,
    input[DATA_WIDTH-1:0]       push_data,
    output wire                 push_ready,

    //Full flag - in PUSH clock domain
    output wire                 push_full,

    //Empty flag - in PUSH clock domain
    output wire                 push_empty,
    
    //FIFO level - in PUSH clock domain
    output reg[CNT_WIDTH:0]     push_fifo_lvl,

    input                       pop_clk,
    output wire                 pop_valid,
    output wire[DATA_WIDTH-1:0] pop_data,
    input                       pop_ready,

    //Full flag - in POP clock domain
    output wire                 pop_full,

    //Empty flag - in POP clock domain
    output wire                 pop_empty,
    
    //FIFO level - in POP clock domain
    output reg[CNT_WIDTH:0]     pop_fifo_lvl
  );

    initial begin
      assert(DATA_WIDTH >= 1) else begin
        $error($sformatf("Legal values for DATA_WIDTH parameter must greater of equal than 1 but found 'd%0d", DATA_WIDTH));
      end

      assert(FIFO_DEPTH >= 1) else begin
        $error($sformatf("Legal values for FIFO_DEPTH parameter must greater of equal than 1 but found 'd%0d", FIFO_DEPTH));
      end
    end

    //Memory containing the FIFO information
    reg[DATA_WIDTH-1:0] fifo[0:FIFO_DEPTH-1];


    //Read pointer - in PUSH clock domain
    wire[CNT_WIDTH-1:0] rd_ptr_push;

    //Read pointer - in POP clock domain
    reg[CNT_WIDTH-1:0]  rd_ptr_pop;


    //Next write pointer - in PUSH clock domain
    reg[CNT_WIDTH-1:0] next_wr_ptr_push;

    //Next read pointer - in POP clock domain
    reg[CNT_WIDTH-1:0] next_rd_ptr_pop;

    //Write pointer - in PUSH clock domain
    reg[CNT_WIDTH-1:0] wr_ptr_push;

    //Write pointer - in POP clock domain
    wire[CNT_WIDTH-1:0] wr_ptr_pop;

    //FIFO level - in PUSH clock domain, delayed
    reg[CNT_WIDTH:0] push_fifo_lvl_dly;

    //FIFO level - in POP clock domain, delayed
    reg[CNT_WIDTH:0] pop_fifo_lvl_dly;

    always_comb begin
      if(wr_ptr_push == FIFO_DEPTH - 1) begin
        next_wr_ptr_push = 0;
      end
      else begin
        next_wr_ptr_push = wr_ptr_push + 1;
      end
    end
    
    always@(posedge push_clk or negedge reset_n) begin
      if(reset_n == 0) begin
        push_fifo_lvl_dly  <= 0;
      end
      else begin
        push_fifo_lvl_dly <= push_fifo_lvl;
      end
    end
    
    always@(posedge pop_clk or negedge reset_n) begin
      if(reset_n == 0) begin
        pop_fifo_lvl_dly  <= 0;
      end
      else begin
        pop_fifo_lvl_dly <= pop_fifo_lvl;
      end
    end
    
    assign push_empty = (push_fifo_lvl == 0);
    assign push_full  = (push_fifo_lvl == FIFO_DEPTH);
    
    always@(posedge push_clk or negedge reset_n) begin
      if(reset_n == 0) begin
        wr_ptr_push <= 0;
      end
      else begin
        if(push_valid & push_ready) begin
          fifo[wr_ptr_push] <= push_data;
          wr_ptr_push       <= next_wr_ptr_push;
        end
      end
    end

    assign push_ready = push_valid & !push_full;

    always_comb begin
      if(rd_ptr_pop == FIFO_DEPTH - 1) begin
        next_rd_ptr_pop = 0;
      end
      else begin
        next_rd_ptr_pop = rd_ptr_pop + 1;
      end
    end

    assign pop_empty = (pop_fifo_lvl == 0);
    assign pop_full  = (pop_fifo_lvl == FIFO_DEPTH);
    
    always@(posedge pop_clk or negedge reset_n) begin
      if(reset_n == 0) begin
        rd_ptr_pop <= 0;
      end
      else begin
        if(pop_valid & pop_ready) begin
          rd_ptr_pop <= next_rd_ptr_pop;
        end
      end
    end
    
    always_comb begin
      if(wr_ptr_push == rd_ptr_push) begin
        if(push_fifo_lvl_dly >= FIFO_DEPTH - 1) begin
          push_fifo_lvl = FIFO_DEPTH;
        end
        else begin
          push_fifo_lvl = 0;
        end
      end
      else if(wr_ptr_push > rd_ptr_push) begin
        push_fifo_lvl = wr_ptr_push - rd_ptr_push;
      end
      else begin
        push_fifo_lvl = FIFO_DEPTH - (rd_ptr_push - wr_ptr_push);
      end
    end

    always_comb begin
      if(wr_ptr_pop == rd_ptr_pop) begin
        if(pop_fifo_lvl_dly >= FIFO_DEPTH - 1) begin
          pop_fifo_lvl = FIFO_DEPTH;
        end
        else begin
          pop_fifo_lvl = 0;
        end
      end
      else if(wr_ptr_pop > rd_ptr_pop) begin
        pop_fifo_lvl = wr_ptr_pop - rd_ptr_pop;
      end
      else begin
        pop_fifo_lvl = FIFO_DEPTH - (rd_ptr_pop - wr_ptr_pop);
      end
    end

    assign pop_valid = !pop_empty;
    assign pop_data  = fifo[rd_ptr_pop];

    if(CDC == 1) begin
      //Synchronizer to move the wr_ptr information from PUSH clock domain to POP clock domain
      cfs_synch#(CNT_WIDTH) synch_wr_ptr_push2pop(
        .clk(pop_clk),
        .i(wr_ptr_push),
        .o(wr_ptr_pop)
      );

      //Synchronizer to move the rd_ptr information from POP clock domain to PUSH clock domain
      cfs_synch#(CNT_WIDTH) synch_rd_ptr_pop2push(
        .clk(push_clk),
        .i(rd_ptr_pop),
        .o(rd_ptr_push)
      );
    end
    else begin
       assign wr_ptr_pop  = wr_ptr_push;
       assign rd_ptr_push = rd_ptr_pop;
    end

  endmodule

`endif