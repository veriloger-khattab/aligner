///////////////////////////////////////////////////////////////////////////////
// File:        cfs_ctrl.v
// Instructor:  Cristian Florin Slav
// Date:        2023-06-26
// Description: Controller. The role of this module is to align any MD packets
//              found in the RX FIFO and push the aligned information in the 
//              TX FIFO.
///////////////////////////////////////////////////////////////////////////////
`ifndef CFS_CTRL_V
  `define CFS_CTRL_V

  module cfs_ctrl #(
    parameter ALGN_DATA_WIDTH = 32,

    localparam int unsigned ALGN_OFFSET_WIDTH = ALGN_DATA_WIDTH <= 8 ? 1 : $clog2(ALGN_DATA_WIDTH/8),
    localparam int unsigned ALGN_SIZE_WIDTH   = $clog2(ALGN_DATA_WIDTH/8)+1,
    localparam int unsigned FIFO_WIDTH        = ALGN_DATA_WIDTH + ALGN_OFFSET_WIDTH + ALGN_SIZE_WIDTH
  )(
    
    input                        reset_n,
    input                        clk,

    input                        pop_valid,
    input[FIFO_WIDTH-1:0]        pop_data,
    output reg                   pop_ready,

    output reg                   push_valid,
    output reg[FIFO_WIDTH-1:0]   push_data,
    input                        push_ready,
    
    input[ALGN_OFFSET_WIDTH-1:0] ctrl_offset,
    input[ALGN_SIZE_WIDTH-1:0]   ctrl_size
    );
    
    localparam int unsigned DATA_MSB = ALGN_DATA_WIDTH-1;
    localparam int unsigned DATA_LSB = 0;
    
    localparam int unsigned OFFSET_MSB = ALGN_DATA_WIDTH+ALGN_OFFSET_WIDTH-1;
    localparam int unsigned OFFSET_LSB = ALGN_DATA_WIDTH;
    
    localparam int unsigned SIZE_MSB = ALGN_DATA_WIDTH+ALGN_OFFSET_WIDTH+ALGN_SIZE_WIDTH-1;
    localparam int unsigned SIZE_LSB = ALGN_DATA_WIDTH+ALGN_OFFSET_WIDTH;
    
    //Current offset to be aligned
    reg[ALGN_OFFSET_WIDTH-1:0] unaligned_offset;
    
    //Current size to be aligned
    reg[ALGN_SIZE_WIDTH-1:0] unaligned_size;
    
    //Current data to be aligned
    reg[ALGN_DATA_WIDTH-1:0] unaligned_data;
    
    //Current number of bytes from the unaligned data which were already processed
    reg[ALGN_SIZE_WIDTH-1:0] unaligned_bytes_processed;
    
    //Current number of bytes in the aligned data so far
    reg[ALGN_SIZE_WIDTH-1:0] aligned_bytes_processed;
    
    always@(posedge clk or negedge reset_n) begin
      if(reset_n == 0) begin
        pop_ready                 <= 1;
        
        push_valid                <= 0;
        push_data                 <= 0;
        
        unaligned_offset          <= 0;
        unaligned_size            <= 0;
        unaligned_data            <= 0;
        unaligned_bytes_processed <= 0;
        
        aligned_bytes_processed   <= 0;
      end
      else begin
        if((push_valid == 1) & (push_ready == 0)) begin
          //Aligned data is waiting to be accepted
          
          if(unaligned_bytes_processed >= unaligned_size) begin
            //All the buffered unaligned bytes were processed - try to take new ones
            
            if((pop_valid == 1) && (pop_ready == 1)) begin
              //Transfer the unaligned data to the internal buffer
              
              pop_ready                 <= 0;
              
              unaligned_offset          <= pop_data[OFFSET_MSB:OFFSET_LSB];
              unaligned_size            <= pop_data[SIZE_MSB:SIZE_LSB];
              unaligned_data            <= pop_data[DATA_MSB:DATA_LSB];
              unaligned_bytes_processed <= 0;
        
            end
            else if((pop_valid == 1) && (pop_ready == 0)) begin
              //Accept the unaligned data
              
              pop_ready <= 1;
            end
            else begin
              //Already accept the future unaligned data which will come
              
              pop_ready <= 1;
            end
          end
          else begin
            //There is no room to save any incomming unaligned data, so stop the flow
            
            pop_ready <= 0;
          end
          
        end
        else if((push_valid == 1) & (push_ready == 1)) begin
          //Aligned data was accepted
          
          if(unaligned_bytes_processed >= unaligned_size) begin
            //All the buffered unaligned bytes were processed
            
            if((pop_valid == 1) && (pop_ready == 1)) begin
              //Incomming unaligned bytes are ready to be processed
              
              if(pop_data[SIZE_MSB:SIZE_LSB] >= ctrl_size) begin
                //There is enough information on the incomming unaligned bytes to aligned it
                
                push_valid                       <= 1;
                push_data[DATA_MSB:DATA_LSB]     <= ((('h1 << (ctrl_size * 8)) - 1) & (pop_data[DATA_MSB:DATA_LSB] >> (pop_data[OFFSET_MSB:OFFSET_LSB] * 8))) << (8 * ctrl_offset);
                push_data[SIZE_MSB:SIZE_LSB]     <= ctrl_size;
                push_data[OFFSET_MSB:OFFSET_LSB] <= ctrl_offset;
                
                unaligned_offset                 <= pop_data[OFFSET_MSB:OFFSET_LSB];
                unaligned_size                   <= pop_data[SIZE_MSB:SIZE_LSB];
                unaligned_data                   <= pop_data[DATA_MSB:DATA_LSB];
                unaligned_bytes_processed        <= ctrl_size;
                aligned_bytes_processed          <= 0;
                
                if(pop_data[SIZE_MSB:SIZE_LSB] > ctrl_size) begin
                  //There is too much data in the incomming unaligned packet. Stop the reception
                  //to have time to align it all.
                  pop_ready <= 0;
                end
                else begin
                  pop_ready <= 1;
                end
              end
              else begin
                //There is no enough information on the incomming unaligned bytes to aligned it - just prepare what is available for alignment
                
                push_valid              <= 0;
                push_data               <= ((('h1 << (pop_data[SIZE_MSB:SIZE_LSB] * 8)) - 1) & (pop_data[DATA_MSB:DATA_LSB] >> (pop_data[OFFSET_MSB:OFFSET_LSB] * 8))) << (8 * ctrl_offset);
                aligned_bytes_processed <= pop_data[SIZE_MSB:SIZE_LSB];
              end
            end
            else if((pop_valid == 1) && (pop_ready == 0)) begin
              //There is a request to get incomming unaligned data so accept it
              
              pop_ready               <= 1;
              push_valid              <= 0;
              push_data               <= 0;
              aligned_bytes_processed <= 0;
            end
            else begin
              //Already accept the future unaligned data which will come
              
              pop_ready               <= 1;
              push_valid              <= 0;
              push_data               <= 0;
              aligned_bytes_processed <= 0;
            end
          end
          else begin
            //There is still some unaligned bytes not processed
            
            if((unaligned_size - unaligned_bytes_processed) >= ctrl_size) begin
              //There is enough information on the buffered unaligned bytes to aligned it
              
              push_valid                       <= 1;
              push_data[DATA_MSB:DATA_LSB]     <= ((('h1 << (ctrl_size * 8)) - 1) & (unaligned_data >> ((unaligned_offset + unaligned_bytes_processed) * 8))) << (8 * ctrl_offset);
              push_data[SIZE_MSB:SIZE_LSB]     <= ctrl_size;
              push_data[OFFSET_MSB:OFFSET_LSB] <= ctrl_offset;
              unaligned_bytes_processed        <= unaligned_bytes_processed + ctrl_size;
              aligned_bytes_processed          <= 0;
              
              if(unaligned_bytes_processed + ctrl_size >= unaligned_size) begin
                //The buffered unaligned data was completly processed, get ready for new incomming unaligned data
                
                pop_ready <= 1;
              end
            end
            else begin
              //There is no enough information on the buffered unaligned bytes to aligned it - just prepare what is available for alignment
              
              push_valid                <= 0;
              push_data                 <= ((('h1 << ((unaligned_size - unaligned_bytes_processed) * 8)) - 1) & (unaligned_data >> ((unaligned_offset + unaligned_bytes_processed) * 8))) << (8 * ctrl_offset);
              unaligned_bytes_processed <= unaligned_size;
              aligned_bytes_processed   <= unaligned_size - unaligned_bytes_processed;
              
              //Already accept any incomming unaligned data
              pop_ready <= 1;
            end
          end
        end
        else begin
          //There is no aligned data sent so far
          
          if(unaligned_bytes_processed >= unaligned_size) begin
            //All the buffered unaligned bytes were processed
            
            if((pop_valid == 1) && (pop_ready == 1)) begin
              if(pop_data[SIZE_MSB:SIZE_LSB] >= (ctrl_size - aligned_bytes_processed)) begin
                //There is enough information in the incomming unaligned data to send an aligned packet
                
                push_valid                       <= 1;
                push_data[DATA_MSB:DATA_LSB]     <= push_data[DATA_MSB:DATA_LSB] | (((('h1 << ((ctrl_size - aligned_bytes_processed) * 8)) - 1) & (pop_data[DATA_MSB:DATA_LSB] >> (pop_data[OFFSET_MSB:OFFSET_LSB] * 8))) << (8 * (ctrl_offset + aligned_bytes_processed)));
                push_data[SIZE_MSB:SIZE_LSB]     <= ctrl_size;
                push_data[OFFSET_MSB:OFFSET_LSB] <= ctrl_offset;
                
                unaligned_offset                 <= pop_data[OFFSET_MSB:OFFSET_LSB];
                unaligned_size                   <= pop_data[SIZE_MSB:SIZE_LSB];
                unaligned_data                   <= pop_data[DATA_MSB:DATA_LSB];
                unaligned_bytes_processed        <= ctrl_size - aligned_bytes_processed;
                
                if(pop_data[SIZE_MSB:SIZE_LSB] == (ctrl_size - aligned_bytes_processed)) begin
                  pop_ready <= 1;
                end
                else begin
                  pop_ready <= 0;
                end
                
              end
              else begin
                 //There is no enough information on the buffered unaligned bytes to aligned it - just prepare what is available for alignment
                
                push_valid                <= 0;
                push_data                 <= push_data | (((('h1 << (pop_data[SIZE_MSB:SIZE_LSB] * 8)) - 1) & (pop_data[DATA_MSB:DATA_LSB] >> (pop_data[OFFSET_MSB:OFFSET_LSB] * 8))) << (8 * (ctrl_offset + aligned_bytes_processed)));
                aligned_bytes_processed   <= aligned_bytes_processed + pop_data[SIZE_MSB:SIZE_LSB];
                
                unaligned_offset          <= pop_data[OFFSET_MSB:OFFSET_LSB];
                unaligned_size            <= pop_data[SIZE_MSB:SIZE_LSB];
                unaligned_data            <= pop_data[DATA_MSB:DATA_LSB];
                unaligned_bytes_processed <= pop_data[SIZE_MSB:SIZE_LSB];
                
                //Already accept any future incomming unaligned data
                pop_ready                 <= 1;
              end
            end
            else if((pop_valid == 1) && (pop_ready == 0)) begin
              //Accept any incomming unaligned data
              pop_ready <= 1;
            end
            else begin
              //Already accept any incomming unaligned data
              pop_ready <= 1;
            end
          end
          else begin
            //There is still some buffered unaligned bytes which can be processed
            
            if(unaligned_size - unaligned_bytes_processed >= (ctrl_size - aligned_bytes_processed)) begin
              //There is enough information in the buffered unaligned data to send an aligned packet
              
              push_valid                       <= 1;
              push_data[DATA_MSB:DATA_LSB]     <= push_data[DATA_MSB:DATA_LSB] | (((('h1 << ((ctrl_size - aligned_bytes_processed) * 8)) - 1) & (unaligned_data >> ((unaligned_offset + unaligned_bytes_processed) * 8))) << (8 * (ctrl_offset + aligned_bytes_processed)));
              push_data[SIZE_MSB:SIZE_LSB]     <= ctrl_size;
              push_data[OFFSET_MSB:OFFSET_LSB] <= ctrl_offset;
              
              unaligned_bytes_processed        <= unaligned_bytes_processed + ctrl_size - aligned_bytes_processed;

              if(unaligned_bytes_processed + ctrl_size - aligned_bytes_processed >= unaligned_size) begin
                //Already accept any incomming unaligned data
                pop_ready <= 1;
              end
              else begin
                pop_ready <= 0;
              end
            end
            else begin
              //There is no enough information on the buffered unaligned bytes to aligned it - just prepare what is available for alignment
              
              push_valid                <= 0;
              push_data                 <= push_data | (((('h1 << ((unaligned_size - unaligned_bytes_processed) * 8)) - 1) & (unaligned_data >> ((unaligned_offset + unaligned_bytes_processed) * 8))) << (8 * (ctrl_offset + aligned_bytes_processed)));
              aligned_bytes_processed   <= aligned_bytes_processed + (unaligned_size - unaligned_bytes_processed) ;
              
              unaligned_bytes_processed <= unaligned_size;

              //Already accept any incomming unaligned data
              pop_ready <= 1;
            end
          end
        end
      end
    end
    
  endmodule

`endif