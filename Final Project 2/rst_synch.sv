module rst_synch(RST_n, clk, rst_n);

  input RST_n, clk;
  output reg rst_n;

  reg flop;

  always_ff@(negedge clk, negedge RST_n)
    if(!RST_n)
      flop <= 1'b0;
    else
      flop <= 1'b1;

  always_ff@(negedge clk, negedge RST_n)
    if(!RST_n)
      rst_n <= 1'b0;
    else
      rst_n <= flop;

endmodule
