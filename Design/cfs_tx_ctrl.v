///////////////////////////////////////////////////////////////////////////////
// File:        cfs_tx_ctrl.v
// Instructor:  Cristian Florin Slav
// Date:        2023-06-26
// Description: TX Controller. The role of this module is to take the aligned
//              information from the TX FIFO an to send it on the TX interface.
//              When the TX FIFO is empty it signals this on the TX interface 
//              by deasserting the md_tx_valid signal.
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_TX_CTRL_V
  `define CFS_TX_CTRL_V

  module cfs_tx_ctrl #(
    parameter ALGN_DATA_WIDTH = 32,

    localparam int unsigned ALGN_OFFSET_WIDTH = ALGN_DATA_WIDTH <= 8 ? 1 : $clog2(ALGN_DATA_WIDTH/8),
    localparam int unsigned ALGN_SIZE_WIDTH   = $clog2(ALGN_DATA_WIDTH/8)+1,
    localparam int unsigned FIFO_DATA_WIDTH   = ALGN_DATA_WIDTH + ALGN_OFFSET_WIDTH + ALGN_SIZE_WIDTH
  )(
    input                              pop_valid,
    input[FIFO_DATA_WIDTH-1:0]         pop_data,
    output wire                        pop_ready,

    output wire                        md_tx_valid,
    output wire[ALGN_DATA_WIDTH-1:0]   md_tx_data,
    output wire[ALGN_OFFSET_WIDTH-1:0] md_tx_offset,
    output wire[ALGN_SIZE_WIDTH-1:0]   md_tx_size,
    input                              md_tx_ready
    );
    
    localparam int unsigned DATA_MSB = ALGN_DATA_WIDTH-1;
    localparam int unsigned DATA_LSB = 0;
    
    localparam int unsigned OFFSET_MSB = ALGN_DATA_WIDTH+ALGN_OFFSET_WIDTH-1;
    localparam int unsigned OFFSET_LSB = ALGN_DATA_WIDTH;
    
    localparam int unsigned SIZE_MSB = ALGN_DATA_WIDTH+ALGN_OFFSET_WIDTH+ALGN_SIZE_WIDTH-1;
    localparam int unsigned SIZE_LSB = ALGN_DATA_WIDTH+ALGN_OFFSET_WIDTH;
    
    assign pop_ready    = pop_valid & md_tx_ready;
    assign md_tx_valid  = pop_valid;
    assign md_tx_data   = pop_data[DATA_MSB:DATA_LSB];
    assign md_tx_offset = pop_data[OFFSET_MSB:OFFSET_LSB];
    assign md_tx_size   = pop_data[SIZE_MSB:SIZE_LSB];
    
  endmodule

`endif