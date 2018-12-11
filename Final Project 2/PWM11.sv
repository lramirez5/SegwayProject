//Lucas Wysiatko
module PWM11(clk, rst_n, duty, PWM_sig);

  input clk, rst_n;
  input [10:0] duty;
  output reg PWM_sig;

  reg [10:0] cnt;
  wire set, reset;

  //11-bit counter
  always_ff@(posedge clk, negedge rst_n) begin
    if(!rst_n)
      cnt <= 11'h000;
    else
      cnt <= cnt + 1;
  end

  //set and reset logic based on count
  assign set  = |cnt;
  assign reset = (cnt >= duty) ? 1'b1 : 1'b0;

  //set reset flop that holds PWM_sig
  always_ff@(posedge clk, negedge rst_n) begin
    if(!rst_n)              //asynch reset has highest priority
      PWM_sig <= 1'b0;
    else if(reset)          //reset has higher priority than set
      PWM_sig <= 1'b0;
    else if(set)
      PWM_sig <= 1'b1;
    //otherwise implied recirculation
  end

endmodule
