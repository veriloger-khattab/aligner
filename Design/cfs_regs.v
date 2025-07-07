///////////////////////////////////////////////////////////////////////////////
// File:        cfs_regs.v
// Instructor:  Cristian Florin Slav
// Date:        2023-06-27
// Description: Registers module. This module contains all the registers of the
//              Aligner module. It handles the register accesses on the APB 
//              interface. There are several scenarios in which the access to
//              the registers will return an error:
//                 1. Access to an unmapped location.
//                 2. Write access to STATUS register.
//                 3. Write access to CTRL register for which the new values
//                    for CTRL.SIZE and CTRL.OFFSET are illegal.
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_REGS_V
  `define CFS_REGS_V

  module cfs_regs#(
    parameter APB_ADDR_WIDTH        = 16,
    parameter ALGN_DATA_WIDTH       = 32,
    
    parameter STATUS_CNT_DROP_WIDTH = 8,
    parameter STATUS_RX_LVL_WIDTH   = 4,
    parameter STATUS_TX_LVL_WIDTH   = 4,
    
    localparam int unsigned APB_DATA_WIDTH  = 32,
    localparam int unsigned ALGN_OFFSET_WIDTH = ALGN_DATA_WIDTH <= 8 ? 1 : $clog2(ALGN_DATA_WIDTH/8),
    localparam int unsigned ALGN_SIZE_WIDTH   = $clog2(ALGN_DATA_WIDTH/8)+1) (
    
    input wire                            pclk,
    input wire                            presetn,

    input wire[APB_ADDR_WIDTH-1:0]        paddr,
    input wire                            pwrite,
    input wire                            psel,
    input wire                            penable,
    input wire[APB_DATA_WIDTH-1:0]        pwdata,
    output reg                            pready,
    output reg[APB_DATA_WIDTH-1:0]        prdata,
    output reg                            pslverr,
      
    output reg[ALGN_OFFSET_WIDTH-1:0]     ctrl_offset,
    output reg[ALGN_SIZE_WIDTH-1:0]       ctrl_size,
    output reg                            ctrl_clr,
    
    input wire[STATUS_CNT_DROP_WIDTH-1:0] status_cnt_drop,
    input wire[STATUS_RX_LVL_WIDTH-1:0]   status_rx_lvl,
    input wire[STATUS_TX_LVL_WIDTH-1:0]   status_tx_lvl,
    
    input wire                            rx_fifo_empty,
    input wire                            rx_fifo_full,
    input wire                            tx_fifo_empty,
    input wire                            tx_fifo_full,
    input wire                            max_drop,
    
    output wire                           irq
  );
    
    localparam ADDR_CTRL    = 'h0000;
    localparam ADDR_STATUS  = 'h000c;
    localparam ADDR_IRQEN   = 'h00f0;
    localparam ADDR_IRQ     = 'h00f4;
    
    localparam LSB_CTRL_SIZE   = 0;
    localparam LSB_CTRL_OFFSET = 8;
    localparam LSB_CTRL_CLR    = 16;
    
    localparam LSB_STATUS_CNT_DROP = 0;
    localparam LSB_STATUS_RX_LVL   = 8;
    localparam LSB_STATUS_TX_LVL   = 16;
    
    localparam LSB_IRQEN_RX_FIFO_EMPTY = 0;
    localparam LSB_IRQEN_RX_FIFO_FULL  = 1;
    localparam LSB_IRQEN_TX_FIFO_EMPTY = 2;
    localparam LSB_IRQEN_TX_FIFO_FULL  = 3;
    localparam LSB_IRQEN_MAX_DROP      = 4;
    
    localparam LSB_IRQ_RX_FIFO_EMPTY = LSB_IRQEN_RX_FIFO_EMPTY;
    localparam LSB_IRQ_RX_FIFO_FULL  = LSB_IRQEN_RX_FIFO_FULL;
    localparam LSB_IRQ_TX_FIFO_EMPTY = LSB_IRQEN_TX_FIFO_EMPTY;
    localparam LSB_IRQ_TX_FIFO_FULL  = LSB_IRQEN_TX_FIFO_FULL;
    localparam LSB_IRQ_MAX_DROP      = LSB_IRQEN_MAX_DROP;
    
    wire[APB_ADDR_WIDTH-1:0] addr_aligned;
  
    assign addr_aligned = {paddr[APB_ADDR_WIDTH-1:2], 2'b00};
    
    reg wr_ctrl_is_illegal;
    
    wire[ALGN_SIZE_WIDTH-1:0] ctrl_size_wr_val;
    
    assign ctrl_size_wr_val = pwdata[LSB_CTRL_SIZE + ALGN_SIZE_WIDTH - 1 : LSB_CTRL_SIZE];
                      
    wire[ALGN_OFFSET_WIDTH-1:0] ctrl_offset_wr_val;
    
    assign ctrl_offset_wr_val = pwdata[LSB_CTRL_OFFSET + ALGN_OFFSET_WIDTH - 1 : LSB_CTRL_OFFSET];
    
    reg[APB_DATA_WIDTH-1:0] ctrl_rd_val;
    
    reg irqen_rx_fifo_empty;
    reg irqen_rx_fifo_full;
    reg irqen_tx_fifo_empty;
    reg irqen_tx_fifo_full;
    reg irqen_max_drop;
    
    reg irq_rx_fifo_empty;
    reg irq_rx_fifo_full;
    reg irq_tx_fifo_empty;
    reg irq_tx_fifo_full;
    reg irq_max_drop;
    
    always_comb begin
      ctrl_rd_val = 0;
      
      ctrl_rd_val[LSB_CTRL_SIZE   + ALGN_SIZE_WIDTH   - 1 : LSB_CTRL_SIZE]   = ctrl_size;
      ctrl_rd_val[LSB_CTRL_OFFSET + ALGN_OFFSET_WIDTH - 1 : LSB_CTRL_OFFSET] = ctrl_offset;
    end
    
    reg[APB_DATA_WIDTH-1:0] status_rd_val;
    
    always_comb begin
      status_rd_val = 0;
      
      status_rd_val[LSB_STATUS_CNT_DROP+ STATUS_CNT_DROP_WIDTH-1:LSB_STATUS_CNT_DROP] = status_cnt_drop;
      status_rd_val[LSB_STATUS_RX_LVL  + STATUS_RX_LVL_WIDTH-1  :LSB_STATUS_RX_LVL]   = status_rx_lvl;
      status_rd_val[LSB_STATUS_TX_LVL  + STATUS_TX_LVL_WIDTH-1  :LSB_STATUS_TX_LVL]   = status_tx_lvl;
    end
    
    reg[APB_DATA_WIDTH-1:0] irqen_rd_val;
    
    always_comb begin
      irqen_rd_val = 0;
      
      irqen_rd_val[LSB_IRQEN_RX_FIFO_EMPTY] = irqen_rx_fifo_empty;
      irqen_rd_val[LSB_IRQEN_RX_FIFO_FULL]  = irqen_rx_fifo_full;
      irqen_rd_val[LSB_IRQEN_TX_FIFO_EMPTY] = irqen_tx_fifo_empty;
      irqen_rd_val[LSB_IRQEN_TX_FIFO_FULL]  = irqen_tx_fifo_full;
      irqen_rd_val[LSB_IRQEN_MAX_DROP]      = irqen_max_drop;
    end
    
    reg[APB_DATA_WIDTH-1:0] irq_rd_val;
    
    always_comb begin
      irq_rd_val = 0;
      
      irq_rd_val[LSB_IRQEN_RX_FIFO_EMPTY] = irq_rx_fifo_empty;
      irq_rd_val[LSB_IRQEN_RX_FIFO_FULL]  = irq_rx_fifo_full;
      irq_rd_val[LSB_IRQEN_TX_FIFO_EMPTY] = irq_tx_fifo_empty;
      irq_rd_val[LSB_IRQEN_TX_FIFO_FULL]  = irq_tx_fifo_full;
      irq_rd_val[LSB_IRQEN_MAX_DROP]      = irq_max_drop;
    end
    
    wire edge_rx_fifo_empty;
    wire edge_rx_fifo_full;
    wire edge_tx_fifo_empty;
    wire edge_tx_fifo_full;
    wire edge_max_drop;
    
    cfs_edge_detect #(.EDGE(1), .RESET_VAL(1)) edge_detect_rx_fifo_empty(.clk(pclk), .reset_n(presetn), .data(rx_fifo_empty), .detected(edge_rx_fifo_empty));
    cfs_edge_detect #(.EDGE(1), .RESET_VAL(0)) edge_detect_rx_fifo_full( .clk(pclk), .reset_n(presetn), .data(rx_fifo_full),  .detected(edge_rx_fifo_full));
    cfs_edge_detect #(.EDGE(1), .RESET_VAL(1)) edge_detect_tx_fifo_empty(.clk(pclk), .reset_n(presetn), .data(tx_fifo_empty), .detected(edge_tx_fifo_empty));
    cfs_edge_detect #(.EDGE(1), .RESET_VAL(0)) edge_detect_tx_fifo_full( .clk(pclk), .reset_n(presetn), .data(tx_fifo_full),  .detected(edge_tx_fifo_full));
    cfs_edge_detect #(.EDGE(1), .RESET_VAL(0)) edge_detect_max_drop(     .clk(pclk), .reset_n(presetn), .data(max_drop),      .detected(edge_max_drop));
    
    assign irq = 
      (edge_rx_fifo_empty & irqen_rx_fifo_empty) | 
      (edge_rx_fifo_full  & irqen_rx_fifo_full)  | 
      (edge_tx_fifo_empty & irqen_tx_fifo_empty) | 
      (edge_tx_fifo_full  & irqen_tx_fifo_full);
    
    always@(posedge pclk or negedge presetn) begin
      if(presetn == 0) begin
        ctrl_offset <= 0;
        ctrl_size   <= 1;
        
        irqen_rx_fifo_empty <= 1;
        irqen_rx_fifo_full  <= 1;
        irqen_tx_fifo_empty <= 1;
        irqen_tx_fifo_full  <= 1;
        irqen_max_drop      <= 1;
        
        irq_rx_fifo_empty <= 0;
        irq_rx_fifo_full  <= 0;
        irq_tx_fifo_empty <= 0;
        irq_tx_fifo_full  <= 0;
        irq_max_drop      <= 0;
        
        wr_ctrl_is_illegal <= 0;
        
        ctrl_clr           <= 0;
      end
      else begin
        ctrl_clr <= 0;
        
        if(psel == 1 && penable == 1) begin
          if(pready == 0) begin
            case(addr_aligned) 
              ADDR_CTRL : begin
                if(pwrite) begin
                  if(wr_ctrl_is_illegal == 0) begin
                    if(ctrl_size_wr_val == 0) begin
                      wr_ctrl_is_illegal <= 1;
                      pready             <= 0;
                      pslverr            <= 0;
                    end
                    else if(((ALGN_DATA_WIDTH / 8) + ctrl_offset_wr_val) % ctrl_size_wr_val != 0) begin
                      wr_ctrl_is_illegal <= 1;
                      pready             <= 0;
                      pslverr            <= 0;
                    end
                    else begin
                      wr_ctrl_is_illegal <= 0;
                      pready             <= 1;
                      pslverr            <= 0;
                      
                      ctrl_size          <= ctrl_size_wr_val;
                      ctrl_offset        <= ctrl_offset_wr_val;
                      ctrl_clr           <= pwdata[LSB_CTRL_CLR];
                    end
                  end
                  else begin
                    wr_ctrl_is_illegal <= 0;
                    pready             <= 1;
                    pslverr            <= 1;
                  end
                end
                else begin
                  prdata <= ctrl_rd_val;
                  pready <= 1;
                end
              end
              ADDR_STATUS : begin
                if(pwrite) begin
                  pready  <= 1;
                  pslverr <= 1;
                  prdata  <= 0;
                end
                else begin
                  pready  <= 1;
                  pslverr <= 0;
                  prdata  <= status_rd_val;
                end
              end
              ADDR_IRQEN : begin
                if(pwrite) begin
                  pready  <= 1;
                  pslverr <= 0;
                  
                  irqen_rx_fifo_empty <= pwdata[LSB_IRQEN_RX_FIFO_EMPTY];
                  irqen_rx_fifo_full  <= pwdata[LSB_IRQEN_RX_FIFO_FULL];
                  irqen_tx_fifo_empty <= pwdata[LSB_IRQEN_TX_FIFO_EMPTY];
                  irqen_tx_fifo_full  <= pwdata[LSB_IRQEN_TX_FIFO_FULL];
                  irqen_max_drop      <= pwdata[LSB_IRQEN_MAX_DROP];
                end
                else begin
                  pready  <= 1;
                  pslverr <= 0;
                  prdata  <= irqen_rd_val;
                end
              end
              ADDR_IRQ : begin
                if(pwrite) begin
                  pready  <= 1;
                  pslverr <= 0;
                  
                  irq_rx_fifo_empty <= irq_rx_fifo_empty & !pwdata[LSB_IRQEN_RX_FIFO_EMPTY];
                  irq_rx_fifo_full  <= irq_rx_fifo_full  & !pwdata[LSB_IRQEN_RX_FIFO_FULL];
                  irq_tx_fifo_empty <= irq_tx_fifo_empty & !pwdata[LSB_IRQEN_TX_FIFO_EMPTY];
                  irq_tx_fifo_full  <= irq_tx_fifo_full  & !pwdata[LSB_IRQEN_TX_FIFO_FULL];
                  irq_max_drop      <= irq_max_drop      & !pwdata[LSB_IRQEN_MAX_DROP];
                end
                else begin
                  pready  <= 1;
                  pslverr <= 0;
                  prdata  <= irq_rd_val;
                end
              end
              default : begin
                pready  <= 1;
                pslverr <= 1;
                prdata  <= 0;
              end
            endcase
          end
          else begin
            pready  <= 0;
            pslverr <= 0;
            prdata  <= 0;
          end
        end
        else begin
          pready  <= 0;
          pslverr <= 0;
          prdata  <= 0;
        end
        
        if(edge_rx_fifo_empty) begin
          irq_rx_fifo_empty <= 1;
        end
        
        if(edge_rx_fifo_full) begin
          irq_rx_fifo_full <= 1;
        end
        
        if(edge_tx_fifo_empty) begin
          irq_tx_fifo_empty <= 1;
        end
        
        if(edge_tx_fifo_full) begin
          irq_tx_fifo_full <= 1;
        end
        
        if(edge_max_drop) begin
          irq_max_drop <= 1;
        end
      end
    end

  endmodule

`endif