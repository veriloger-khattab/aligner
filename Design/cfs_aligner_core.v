///////////////////////////////////////////////////////////////////////////////
// File:        cfs_aligner_core.v
// Instructor : Cristian Florin Slav
// Date:        2023-06-27
// Description: Module to align RX data and send it on the TX interface.
//              
//              This module has three interfaces:
//                1. A standard AMBA 3 APB slave interface for accessing 
//                   control and status registers.
//                2. A slave memory data (MD) through which the module receives
//                   the unaligned information.
//                3. A master memory data (MD) through which the module 
//                   transmits the aligned information.
//              
//              The memory data (MD) protocol has the following rules:
//                1. Valid (OFFSET, SIZE) combinations are the ones for which 
//                   the following rules are true at the same time:
//                   1.1. SIZE > 0
//                   1.2. ((ALGN_DATA_WIDTH / 8) + OFFSET) % SIZE = 0
//                2. A transfer starts when VALID becomes 1
//                3. A transfer ends when VALID is 1 and READY is 1
//                4. Once VALID is 1, it must stay constant until READY becomes 1.
//                5. DATA, OFFSET and SIZE must be constant fro mthe begining 
//                   to the end of the transfer.
//                6. ERR is valid only at the end of the transfer, 
//                   when READY is 1.
//              
//              
//              The alignment is done according to the CTRL.OFFSET and 
//              CTRL.SIZE configuration.
//              
//              Any received transfer is dropped if the (OFFSET, SIZE) 
//              combination is not valid. The number of dropped transfers are 
//              counted in STATUS.DROP_CNT field.
//              
//              The module has two FIFOs - one for holding the incomming 
//              transfers and one for holding the outgoing transfers.
//              The current level of each of the FIFO can be read from the 
//              STATUS register, via STATUS.RX_LVL and STATUS.TX_LVL.
//              
//              The module also has a sticky interrupts register, IRQ with the 
//              following interrupts:
//                RX_FIFO_EMPTY - becomes 1 when RX_FIFO became 1 - will remain
//                                1 until it is cleared by software, regardless 
//                                if RX_FIFO became not empty
//                RX_FIFO_FULL  - becomes 1 when RX_FIFO became 1 - will remain 
//                                1 until it is cleared by software, regardless 
//                                if RX_FIFO became not full
//                TX_FIFO_EMPTY - becomes 1 when TX_FIFO became 1 - will remain 
//                                1 until it is cleared by software, regardless 
//                                if TX_FIFO became not empty
//                TX_FIFO_FULL  - becomes 1 when TX_FIFO became 1 - will remain 
//                                1 until it is cleared by software, regardless 
//                                if TX_FIFO became not full
//                MAX_DROP      - becomes 1 when STATUS.CNT_DROP reached its 
//                                maximum value - will remain 1 until it is 
//                                cleared by software.
//              
//              All the interrupts are ORed to generate a pulse irq output.
//              
//              The interrupts which are taking part in the generation of the 
//              irq output are controled via IRQ_EN register.
//              
//              The registers available through the APB interface are:
//              
//              CTRL   @'h0000
//                CTRL[2:0]   = SIZE          - Size, in bytes, of the aligned data.
//                                              Value 0 is illegal and a write atempt
//                                              with value 0 will be rejected.
//                CTRL[7:3]   = reserved
//                CTRL[9:8]   = OFFSET        - Offset, in bytes, of the aligned data.
//                CTRL[15:10] = reserved
//                CTRL[16:16] = CLR           - Clear the status counter (CNT_DROP) 
//                                              when writing 1.
//                                              Writing 0 has no effect.
//                                              This is a write-only register field,
//                                              a read will always return 0.
//                CTRL[31:17]  = reserved
//              
//              
//              STATUS @'h000C
//                STATUS[7:0]   = CNT_DROP    - Number of dropped unaligned accesses. 
//                                              The counter does not wrap once it reaches 
//                                              the maximum value.
//                STATUS[11:8]  = RX_LVL      - Fill level of the RX FIFO
//                STATUS[15:12] = reserved
//                STATUS[19:16] = TX_LVL      - Fill level of the TX FIFO
//                STATUS[31:20] = reserved
//              
//              
//              IRQEN @'h00F0
//                IRQEN[0:0]    = RX_FIFO_EMPTY - Enable IRQ.RX_FIFO_EMPTY in the irq output.
//                IRQEN[1:1]    = RX_FIFO_FULL  - Enable IRQ.RX_FIFO_FULL in the irq output.
//                IRQEN[2:2]    = TX_FIFO_EMPTY - Enable IRQ.TX_FIFO_EMPTY in the irq output.
//                IRQEN[3:3]    = TX_FIFO_FULL  - Enable IRQ.TX_FIFO_FULL in the irq output.
//                IRQEN[4:4]    = MAX_DROP      - Enable IRQ.MAX_DROP in the irq output.
//                IRQEN[31:5]   = reserved
//              
//              
//              IRQ @'h00F4
//                IRQ[0:0]    = RX_FIFO_EMPTY - RX FIFO became empty (sticky). 
//                                              If cleared while RX FIFO is still empty 
//                                              interrupt will not be set immediately. 
//                                              It will be set again once the RX FIFO 
//                                              becomes empty (e.g. STATUS.RX_LVL 
//                                              transitions from 1 to 0).
//                IRQ[1:1]    = RX_FIFO_FULL  - RX FIFO became full (sticky).
//                                              If cleared while RX FIFO is still full 
//                                              interrupt will not be set immediately. 
//                                              It will be set again once the RX FIFO becomes
//                                              full (e.g. STATUS.RX_LVL transitions from MAX-1 to MAX).
//                IRQ[2:2]    = TX_FIFO_EMPTY - TX FIFO became empty (sticky).
//                                              If cleared while TX FIFO is still 
//                                              empty interrupt will not be set immediately. 
//                                              It will be set again once the TX FIFO 
//                                              becomes empty (e.g. STATUS.TX_LVL transitions from 1 to 0).
//                IRQ[3:3]    = TX_FIFO_FULL  - TX FIFO became full (sticky).
//                                              If cleared while TX FIFO is still 
//                                              full interrupt will not be set immediately. 
//                                              It will be set again once the TX 
//                                              FIFO becomes full (e.g. STATUS.TX_LVL 
//                                              transitions from MAX-1 to MAX).
//                IRQ[4:4]    = MAX_DROP      - STATUS.CNT_DROP reached its maximum value (sticky).
//                                              If cleared while STATUS.CNT_DROP 
//                                              is still MAX interrupt will not be set immediately. 
//                                              It will be set again once the STATUS.CNT_DROP 
//                                              becomes MAX (e.g. STATUS.CNT_DROP 
//                                              transitions from MAX-1 to MAX).
//                IRQ[31:5]   = reserved
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_ALIGNER_CORE_V
  `define CFS_ALIGNER_CORE_V
  module cfs_aligner_core#(
    parameter APB_ADDR_WIDTH  = 16,
    parameter ALGN_DATA_WIDTH = 32,
    parameter FIFO_DEPTH      = 8,
    
     //Clock Domain Crossing - RX domain to register access domain
     //Set this parameter to 0 only if md_rx_clk and pclk are tied to the same clock signal.
     parameter CDC_RX_TO_REG  = 1,

     //Clock Domain Crossing - register access domain to TX domain
     //Set this parameter to 0 only if pclk and md_tx_clk are tied to the same clock signal.
     parameter CDC_REG_TO_TX  = 1,

    localparam int unsigned STATUS_CNT_DROP_WIDTH = 8,

    localparam int unsigned APB_DATA_WIDTH  = 32,

    localparam int unsigned ALGN_OFFSET_WIDTH = ALGN_DATA_WIDTH <= 8 ? 1 : $clog2(ALGN_DATA_WIDTH/8),
    localparam int unsigned ALGN_SIZE_WIDTH   = $clog2(ALGN_DATA_WIDTH/8)+1
  ) (
    input wire pclk,
    input wire preset_n,

    input wire[APB_ADDR_WIDTH-1:0]    paddr,
    input wire                        pwrite,
    input wire                        psel,
    input wire                        penable,
    input wire[APB_DATA_WIDTH-1:0]    pwdata,
    output wire                       pready,
    output reg[APB_DATA_WIDTH-1:0]    prdata,
    output reg                        pslverr,

    input                             md_rx_clk,
    input                             md_rx_valid,
    input[ALGN_DATA_WIDTH-1:0]        md_rx_data,
    input[ALGN_OFFSET_WIDTH-1:0]      md_rx_offset,
    input[ALGN_SIZE_WIDTH-1:0]        md_rx_size,
    output reg                        md_rx_ready,
    output reg                        md_rx_err,

    input                             md_tx_clk,
    output reg                        md_tx_valid,
    output reg[ALGN_DATA_WIDTH-1:0]   md_tx_data,
    output reg[ALGN_OFFSET_WIDTH-1:0] md_tx_offset,
    output reg[ALGN_SIZE_WIDTH-1:0]   md_tx_size,
    input                             md_tx_ready,
    input                             md_tx_err,

    output wire                       irq
  );

    localparam int unsigned FIFO_WIDTH        = ALGN_DATA_WIDTH + ALGN_OFFSET_WIDTH + ALGN_SIZE_WIDTH;
    localparam int unsigned FIFO_LVL_WIDTH    = $clog2(FIFO_DEPTH) + 1;

    initial begin
      assert(APB_ADDR_WIDTH >= 12) else begin
        $error($sformatf("Legal values for APB_ADDR_WIDTH parameter must greater of equal than 12 but found 'd%0d", APB_ADDR_WIDTH));
      end

      assert($countones(ALGN_DATA_WIDTH) == 1) else begin
        $error($sformatf("Legal values for ALGN_DATA_WIDTH parameter must be a power of two but found 'd%0d", ALGN_DATA_WIDTH));
      end

      assert(ALGN_DATA_WIDTH >= 8) else begin
        $error($sformatf("Legal values for ALGN_DATA_WIDTH parameter must be greater or equal than 8 but found 'd%0d", ALGN_DATA_WIDTH));
      end
    end

    wire[STATUS_CNT_DROP_WIDTH-1:0] rx_ctrl_2_regs_status_cnt_drop;
    wire                            regs_2_rx_ctrl_ctrl_clr;
    wire                            rx_ctrl_2_rx_fifo_push_valid;
    wire[FIFO_WIDTH-1:0]            rx_ctrl_2_rx_fifo_push_data;
    wire                            rx_fifo_2_rx_ctrl_push_ready;
    wire                            rx_fifo_2_rx_ctrl_push_full;
    wire                            rx_fifo_2_regs_fifo_full;
    wire                            rx_fifo_2_regs_fifo_empty;
    wire[FIFO_LVL_WIDTH-1:0]        rx_fifo_2_regs_fifo_lvl;
    wire[FIFO_LVL_WIDTH-1:0]        tx_fifo_2_regs_fifo_lvl;
    wire                            tx_fifo_2_regs_fifo_empty;
    wire                            tx_fifo_2_regs_fifo_full;
    wire                            tx_fifo_2_tx_ctrl_pop_valid;
    wire[FIFO_WIDTH-1:0]            tx_fifo_2_tx_ctrl_pop_data;
    wire                            tx_fifo_2_tx_ctrl_pop_ready;
    wire                            rx_fifo_2_ctrl_pop_valid;
    wire[FIFO_WIDTH-1:0]            rx_fifo_2_ctrl_pop_data;
    wire                            rx_fifo_2_ctrl_pop_ready;
    wire                            ctrl_2_tx_fifo_push_valid;
    wire[FIFO_WIDTH-1:0]            ctrl_2_tx_fifo_push_data;
    wire                            ctrl_2_tx_fifo_push_ready;
    wire[ALGN_OFFSET_WIDTH-1:0]     regs_2_ctrl_ctrl_offset;
    wire[ALGN_SIZE_WIDTH-1:0]       regs_2_ctrl_ctrl_size;

    cfs_rx_ctrl #(
      .ALGN_DATA_WIDTH      (ALGN_DATA_WIDTH),
      .STATUS_CNT_DROP_WIDTH(STATUS_CNT_DROP_WIDTH)
    ) rx_ctrl (
      .preset_n       (preset_n),
      .pclk           (pclk),

      .status_cnt_drop(rx_ctrl_2_regs_status_cnt_drop),
      .clr_cnt_dop    (regs_2_rx_ctrl_ctrl_clr),

      .md_rx_clk      (md_rx_clk),
      .md_rx_valid    (md_rx_valid),
      .md_rx_data     (md_rx_data),
      .md_rx_offset   (md_rx_offset),
      .md_rx_size     (md_rx_size),
      .md_rx_ready    (md_rx_ready),
      .md_rx_err      (md_rx_err),

      .push_valid     (rx_ctrl_2_rx_fifo_push_valid),
      .push_data      (rx_ctrl_2_rx_fifo_push_data),
      .push_ready     (rx_fifo_2_rx_ctrl_push_ready),

      .rx_fifo_full   (rx_fifo_2_rx_ctrl_push_full)
    );

    cfs_synch_fifo #(
      .DATA_WIDTH(FIFO_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH),
      .CDC(       CDC_RX_TO_REG)) rx_fifo (
      .reset_n      (preset_n),

      .push_clk     (md_rx_clk),
      .push_valid   (rx_ctrl_2_rx_fifo_push_valid),
      .push_data    (rx_ctrl_2_rx_fifo_push_data),
      .push_ready   (rx_fifo_2_rx_ctrl_push_ready),

      .push_full    (rx_fifo_2_rx_ctrl_push_full),

      .push_empty   (),

      .push_fifo_lvl(),

      .pop_clk      (pclk),
      .pop_valid    (rx_fifo_2_ctrl_pop_valid),
      .pop_data     (rx_fifo_2_ctrl_pop_data),
      .pop_ready    (rx_fifo_2_ctrl_pop_ready),

      .pop_full     (rx_fifo_2_regs_fifo_full),

      .pop_empty    (rx_fifo_2_regs_fifo_empty),

      .pop_fifo_lvl (rx_fifo_2_regs_fifo_lvl)
    );

    cfs_synch_fifo #(
      .DATA_WIDTH(FIFO_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH),
      .CDC(       CDC_REG_TO_TX)) tx_fifo (
      .reset_n   (preset_n),

      .push_clk  (pclk),
      .push_valid(ctrl_2_tx_fifo_push_valid),
      .push_data (ctrl_2_tx_fifo_push_data),
      .push_ready(ctrl_2_tx_fifo_push_ready),

      .push_full (tx_fifo_2_regs_fifo_full),

      .push_empty(tx_fifo_2_regs_fifo_empty),

      .push_fifo_lvl(tx_fifo_2_regs_fifo_lvl),

      .pop_clk   (md_tx_clk),
      .pop_valid (tx_fifo_2_tx_ctrl_pop_valid),
      .pop_data  (tx_fifo_2_tx_ctrl_pop_data),
      .pop_ready (tx_fifo_2_tx_ctrl_pop_ready),

      .pop_full  (),

      .pop_empty (),

      .pop_fifo_lvl ()
    );

    cfs_tx_ctrl #(
      .ALGN_DATA_WIDTH(ALGN_DATA_WIDTH)
    ) tx_ctrl (
      .pop_valid   (tx_fifo_2_tx_ctrl_pop_valid),
      .pop_data    (tx_fifo_2_tx_ctrl_pop_data),
      .pop_ready   (tx_fifo_2_tx_ctrl_pop_ready),

      .md_tx_valid (md_tx_valid),
      .md_tx_data  (md_tx_data),
      .md_tx_offset(md_tx_offset),
      .md_tx_size  (md_tx_size),
      .md_tx_ready (md_tx_ready)
    );

    cfs_ctrl #(
      .ALGN_DATA_WIDTH(ALGN_DATA_WIDTH)
    ) ctrl(
      .reset_n    (preset_n),
      .clk        (pclk),

      .pop_valid  (rx_fifo_2_ctrl_pop_valid),
      .pop_data   (rx_fifo_2_ctrl_pop_data),
      .pop_ready  (rx_fifo_2_ctrl_pop_ready),

      .push_valid (ctrl_2_tx_fifo_push_valid),
      .push_data  (ctrl_2_tx_fifo_push_data),
      .push_ready (ctrl_2_tx_fifo_push_ready),

      .ctrl_offset(regs_2_ctrl_ctrl_offset),
      .ctrl_size  (regs_2_ctrl_ctrl_size)
      );

    cfs_regs#(
      .APB_ADDR_WIDTH       (APB_ADDR_WIDTH),
      .STATUS_CNT_DROP_WIDTH(STATUS_CNT_DROP_WIDTH),
      .ALGN_DATA_WIDTH      (ALGN_DATA_WIDTH)) regs (
      .pclk           (pclk),
      .presetn        (preset_n),
      .paddr          (paddr),
      .pwrite         (pwrite),
      .psel           (psel),
      .penable        (penable),
      .pwdata         (pwdata),
      .pready         (pready),
      .prdata         (prdata),
      .pslverr        (pslverr),

      .ctrl_offset    (regs_2_ctrl_ctrl_offset),
      .ctrl_size      (regs_2_ctrl_ctrl_size),
      .ctrl_clr       (regs_2_rx_ctrl_ctrl_clr),

      .status_cnt_drop(rx_ctrl_2_regs_status_cnt_drop),
      .status_rx_lvl  (rx_fifo_2_regs_fifo_lvl),
      .status_tx_lvl  (tx_fifo_2_regs_fifo_lvl),

      .rx_fifo_empty  (rx_fifo_2_regs_fifo_empty),
      .rx_fifo_full   (rx_fifo_2_regs_fifo_full),
      .tx_fifo_empty  (tx_fifo_2_regs_fifo_empty),
      .tx_fifo_full   (tx_fifo_2_regs_fifo_full),
      .max_drop       (rx_ctrl_2_regs_status_cnt_drop == (('h1 << STATUS_CNT_DROP_WIDTH) - 1)),
      
      .irq            (irq)
    );
  endmodule

`endif