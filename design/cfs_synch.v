///////////////////////////////////////////////////////////////////////////////
// File:        cfs_synch.v
// Instructor:  Cristian Florin Slav
// Date:        2023-06-26
// Description: Syncronization module to bring to input signal 'i' to the clock
//              domain defined by signal clock 'clk'.
//              The output 'o' is a synchronous signal working on 'clk'.
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_SYNCH_V
  `define CFS_SYNCH_V

  module cfs_synch#(
    parameter DATA_WIDTH = 32
  ) (
    input                       clk,
    input     [DATA_WIDTH-1:0]  i,
    output reg[DATA_WIDTH-1:0]  o
  );

    always@(posedge clk) begin
      o <= i;
    end

  endmodule

`endif