module PWM11(clk, rst_n, duty, PWM_sig);

input clk, rst_n;
input unsigned [10:0] duty;

output PWM_sig;

wire set, reset;
reg unsigned [10:0] cnt;

sr_flipflop pwm_flop(.q(PWM_sig), .s(set), .r(reset), .rst_n(rst_n), .clk(clk));

assign reset = (cnt >= duty) ? 1 : 0;
assign set = ~|cnt;

initial cnt = 0;

always @(posedge clk, negedge rst_n)
  if(!rst_n)
    cnt <= 0;
  else
    cnt <= cnt + 1;

endmodule

// SR-FF with active low async reset and active high set/reset
module sr_flipflop(q, s, r, rst_n, clk);

input clk, s, r, rst_n;
output reg q;

always_ff @(posedge clk, negedge rst_n)
  if(!rst_n)
    q <= 0;
  else if(r)
    q <= 0;
  else if(s)
    q <= 1;
  else
    q <= q;

endmodule