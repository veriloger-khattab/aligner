module test_array;

  int associative_array[*];
  int index;
  int hi=115;
  initial begin         
    repeat(4) begin
      associative_array[index] = index*2;
      $display("associative_array[%0d] = %0d", index, associative_array[index]);
      index = index+4;
    end
  $display("\t Number of entries in associative_array is %0d",associative_array.size());
  associative_array.last(hi);
  $display("\t The value of the last element in the array is %0d",hi);

  end 

 
endmodule : test_array



q.insert(2,4);





















