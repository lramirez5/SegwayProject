module rst_synch(RST_n, clk, rst_n);

input RST_n, clk;
output rst_n;

wire set, out1;
assign set = 1'b1;

d_flipflop 	flop1(.q(out1), .d(set), .rst_n(RST_n), .clk(clk)),
	flop2(.q(rst_n), .d(out1), .rst_n(RST_n), .clk(clk));

endmodule


module d_flipflop(q, d, rst_n, clk);

input d, clk, rst_n;
output reg q;

always @(posedge clk, negedge rst_n)
  if(!rst_n)
    q <= 0;
  else
    q <= d;

endmodule