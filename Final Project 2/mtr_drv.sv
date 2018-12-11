//Lucas Wysiatko
module mtr_drv(clk, rst_n, lft_spd, lft_rev, PWM_rev_lft, PWM_frwrd_lft,
               rght_spd, rght_rev, PWM_rev_rght, PWM_frwrd_rght);

  input clk, rst_n;
  input [10:0] lft_spd, rght_spd;  //duty cycles of the two motors
  input lft_rev, rght_rev;  //drive motor in reverse if signal is high
  wire PWM_lft_out, PWM_rght_out;  //outputs of the 2 PWM11 instances
  output PWM_rev_lft, PWM_frwrd_lft;  //one gets PWM_lft_out depends on lft_rev
  output PWM_rev_rght, PWM_frwrd_rght; //one gets PWM_rght_out depends on rght_rev

  //instantiate left and right PWM11
  PWM11 lftPWM(.clk(clk), .rst_n(rst_n), .duty(lft_spd), .PWM_sig(PWM_lft_out));
  PWM11 rghtPWM(.clk(clk), .rst_n(rst_n), .duty(rght_spd), .PWM_sig(PWM_rght_out));
  
  //if lft_rev is high, PWM_rev_lft gets PWM_lft_out
  assign PWM_rev_lft = lft_rev ? PWM_lft_out : 11'h000;
  //else if it is low PWM_lft_out gets assigned to PWM_frwrd_lft
  assign PWM_frwrd_lft = lft_rev ? 11'h000 : PWM_lft_out;

  //if rght_rev is high, PWM_rev_rght gets PWM_rght_out
  assign PWM_rev_rght = rght_rev ? PWM_rght_out : 11'h000;
  //else if it is low PWM_rght_out gets assigned to PWM_frwrd_rght
  assign PWM_frwrd_rght = rght_rev ? 11'h000 : PWM_rght_out;

endmodule
