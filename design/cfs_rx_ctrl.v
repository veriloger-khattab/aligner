///////////////////////////////////////////////////////////////////////////////
// File:        cfs_rx_ctrl.v
// Instructor:  Cristian Florin Slav
// Date:        2023-06-26
// Description: RX Controller. The role of this module is to handle the RX
//              interface of the Aligner. This means that the RX Controller
//              must perform the following tasks:
//                 1. Block the RX interface if the RX FIFO is full by 
//                    deasserting the md_rx_ready signal.
//                 2. Reject any incomming MD packet if it is illegal and
//                    increment STATUS.CNT_DROP (if it is not already at its 
//                    maximum value).
//                 3. Push to RX FIFO any incomming MD packet, if it is legal 
//                    and if there is room in the RX FIFO.
//                 4. Clear the STATUS.CNT_DROP counter when it receives this 
//                    request from the Registers module.
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_RX_CTRL_V
  `define CFS_RX_CTRL_V
  
  module cfs_rx_ctrl #(
    parameter ALGN_DATA_WIDTH       = 32,
    parameter STATUS_CNT_DROP_WIDTH = 8,

    localparam int unsigned ALGN_OFFSET_WIDTH = ALGN_DATA_WIDTH <= 8 ? 1 : $clog2(ALGN_DATA_WIDTH/8),
    localparam int unsigned ALGN_SIZE_WIDTH   = $clog2(ALGN_DATA_WIDTH/8)+1,
    localparam int unsigned FIFO_DATA_WIDTH   = ALGN_DATA_WIDTH + ALGN_OFFSET_WIDTH + ALGN_SIZE_WIDTH
  )(
    input                                  preset_n,
    input                                  pclk,

    input                                  clr_cnt_dop,

    output wire[STATUS_CNT_DROP_WIDTH-1:0] status_cnt_drop,

    input                                  md_rx_clk,
    input                                  md_rx_valid,
    input[ALGN_DATA_WIDTH-1:0]             md_rx_data,
    input[ALGN_OFFSET_WIDTH-1:0]           md_rx_offset,
    input[ALGN_SIZE_WIDTH-1:0]             md_rx_size,
    output wire                            md_rx_ready,
    output reg                             md_rx_err,

    output wire                            push_valid,
    output wire[FIFO_DATA_WIDTH-1:0]       push_data,
    input                                  push_ready,

    input                                  rx_fifo_full
    );

    localparam int unsigned DATA_MSB = ALGN_DATA_WIDTH-1;
    localparam int unsigned DATA_LSB = 0;
    
    localparam int unsigned OFFSET_MSB = ALGN_DATA_WIDTH+ALGN_OFFSET_WIDTH-1;
    localparam int unsigned OFFSET_LSB = ALGN_DATA_WIDTH;
    
    localparam int unsigned SIZE_MSB = ALGN_DATA_WIDTH+ALGN_OFFSET_WIDTH+ALGN_SIZE_WIDTH-1;
    localparam int unsigned SIZE_LSB = ALGN_DATA_WIDTH+ALGN_OFFSET_WIDTH;
    
    //STATUS.CNT_DROP in the md_rx_clk domain
    reg[STATUS_CNT_DROP_WIDTH-1:0] md_rx_clk_status_cnt_drop;

    //Synchronizer to move the STATUS.CNT_DROP information from md_rx_clk clock domain to pclk clock domain
    cfs_synch#(STATUS_CNT_DROP_WIDTH) synch_status_cnt_drop(
      .clk(pclk),
      .i  (md_rx_clk_status_cnt_drop),
      .o  (status_cnt_drop)
    );

    always@(posedge md_rx_clk or negedge preset_n or posedge clr_cnt_dop) begin
      if(!preset_n | clr_cnt_dop) begin
        md_rx_clk_status_cnt_drop <= 0;
      end
      else begin
        if(md_rx_valid & md_rx_ready & md_rx_err) begin
          if(md_rx_clk_status_cnt_drop < (('h1 << STATUS_CNT_DROP_WIDTH) - 1)) begin
            md_rx_clk_status_cnt_drop <= md_rx_clk_status_cnt_drop + 1;
          end
        end
      end
    end

    always_comb begin
      if(md_rx_valid == 1) begin
        if(md_rx_size == 0) begin
          md_rx_err = 1;
        end
        else if((((ALGN_DATA_WIDTH / 8) + md_rx_offset) % md_rx_size) != 0) begin
          md_rx_err = 1;
        end
        else begin
          md_rx_err = 0;
        end
      end
      else begin
        md_rx_err = 0;
      end
    end

    assign md_rx_ready = (push_valid & push_ready) | md_rx_err;

    assign push_valid = md_rx_valid & !md_rx_err;

    assign push_data[SIZE_MSB  :SIZE_LSB]   = md_rx_size;
    assign push_data[OFFSET_MSB:OFFSET_LSB] = md_rx_offset;
    assign push_data[DATA_MSB  :DATA_LSB]   = md_rx_data;

  endmodule

`endif