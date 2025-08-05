///////////////////////////////////////////////////////////////////////////////
// File:        cfs_edge_detect.v
// Instructor:  Cristian Florin Slav
// Date:        2023-06-27
// Description: Edge detector module. It detects a particular edge of the input
//              signal.
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_EDGE_DETECT_V
  `define CFS_EDGE_DETECT_V
  
  module cfs_edge_detect #(parameter bit EDGE = 1, parameter bit RESET_VAL = !EDGE)(
    input clk,
    input reset_n,
    input data,
    
    output reg detected
  );
    
    reg dly1_data;
    
    always@(posedge clk or negedge reset_n) begin
      if(reset_n == 0) begin
        dly1_data <= RESET_VAL;
      end
      else begin
        dly1_data <= data;
      end
    end
    
    assign detected = ((data == EDGE) & (dly1_data == !EDGE));
    
  endmodule

`endif