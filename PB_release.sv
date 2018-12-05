module PB_release(PB, clk, rst_n, released);

input PB, clk, rst_n;
output released;

wire out1, out2, out3;

dff_pre	flop1(.q(out1), .d(PB), .rst_n(rst_n), .clk(clk)),
	flop2(.q(out2), .d(out1), .rst_n(rst_n), .clk(clk)),
	flop3(.q(out3), .d(out2), .rst_n(rst_n), .clk(clk));

assign released = out2 & ~out3;

endmodule


module dff_pre(q, d, rst_n, clk);

input d, clk, rst_n;
output reg q;

always @(posedge clk, negedge rst_n)
  if(!rst_n)
    q <= 1;
  else
    q <= d;

endmodule