///////////////////////////////////////////////////////////////////////////////
// File:        cfs_aligner.v
// Instructor:  Cristian Florin Slav
// Date:        2023-06-26
// Description: Aligner module. This module is a wrapper over the 
//              cfs_aligner_core module in order to fix different parameters
//              or to handle different signal connections (e.g. single clock
//              domain).
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_ALIGNER_V
  `define CFS_ALIGNER_V
  module cfs_aligner#(
    parameter ALGN_DATA_WIDTH = 32,
    parameter FIFO_DEPTH      = 8,
    
    localparam int unsigned APB_ADDR_WIDTH    = 16,
    localparam int unsigned APB_DATA_WIDTH    = 32,
    localparam int unsigned ALGN_OFFSET_WIDTH = ALGN_DATA_WIDTH <= 8 ? 1 : $clog2(ALGN_DATA_WIDTH/8),
    localparam int unsigned ALGN_SIZE_WIDTH   = $clog2(ALGN_DATA_WIDTH/8)+1
  ) (
    input wire clk,
    input wire reset_n,
    
    input wire[APB_ADDR_WIDTH-1:0]    paddr,
    input wire                        pwrite,
    input wire                        psel,
    input wire                        penable,
    input wire[APB_DATA_WIDTH-1:0]    pwdata,
    output wire                       pready,
    output reg[APB_DATA_WIDTH-1:0]    prdata,
    output reg                        pslverr,
    
    input                             md_rx_valid,
    input[ALGN_DATA_WIDTH-1:0]        md_rx_data,
    input[ALGN_OFFSET_WIDTH-1:0]      md_rx_offset,
    input[ALGN_SIZE_WIDTH-1:0]        md_rx_size,
    output reg                        md_rx_ready,
    output reg                        md_rx_err,
    
    output reg                        md_tx_valid,
    output reg[ALGN_DATA_WIDTH-1:0]   md_tx_data,
    output reg[ALGN_OFFSET_WIDTH-1:0] md_tx_offset,
    output reg[ALGN_SIZE_WIDTH-1:0]   md_tx_size,
    input                             md_tx_ready,
    input                             md_tx_err,
    
    output reg                        irq
  );
    
    localparam int unsigned STATUS_CNT_DROP_WIDTH = 8;
    
    cfs_aligner_core#(
      .APB_ADDR_WIDTH( APB_ADDR_WIDTH),
      .ALGN_DATA_WIDTH(ALGN_DATA_WIDTH),
      .FIFO_DEPTH(     FIFO_DEPTH),
      .CDC_RX_TO_REG(  0),
      .CDC_REG_TO_TX(  0)) core (
      .pclk        (clk),
      .preset_n    (reset_n),
    
      .paddr       (paddr),
      .pwrite      (pwrite),
      .psel        (psel),
      .penable     (penable),
      .pwdata      (pwdata),
      .pready      (pready),
      .prdata      (prdata),
      .pslverr     (pslverr),
  
      .md_rx_clk   (clk),
      .md_rx_valid (md_rx_valid),
      .md_rx_data  (md_rx_data),
      .md_rx_offset(md_rx_offset),
      .md_rx_size  (md_rx_size),
      .md_rx_ready (md_rx_ready),
      .md_rx_err   (md_rx_err),
  
      .md_tx_clk   (clk),
      .md_tx_valid (md_tx_valid),
      .md_tx_data  (md_tx_data),
      .md_tx_offset(md_tx_offset),
      .md_tx_size  (md_tx_size),
      .md_tx_ready (md_tx_ready),
      .md_tx_err   (md_tx_err),
  
      .irq         (irq)
    );
  endmodule
`endif