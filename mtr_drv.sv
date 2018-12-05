module mtr_drv(clk, rst_n, lft_spd, rght_spd, lft_rev, rght_rev, PWM_rev_lft, PWM_rev_rght, PWM_frwrd_lft, PWM_frwrd_rght);

input clk, rst_n;
input [10:0] lft_spd, rght_spd;
input lft_rev, rght_rev;

output PWM_rev_lft, PWM_rev_rght;
output PWM_frwrd_lft, PWM_frwrd_rght;

wire lft_pwm_sig, rght_pwm_sig;

// pwm signals for forward/reverse on left and right
assign PWM_rev_lft = lft_rev & lft_pwm_sig;
assign PWM_frwrd_lft = ~lft_rev & lft_pwm_sig;
assign PWM_rev_rght = rght_rev & rght_pwm_sig;
assign PWM_frwrd_rght = ~rght_rev & rght_pwm_sig;

PWM11	l_pwm(.clk(clk), .rst_n(rst_n), .duty(lft_spd), .PWM_sig(lft_pwm_sig)),		// left motor pwm
	r_pwm(.clk(clk), .rst_n(rst_n), .duty(rght_spd), .PWM_sig(rght_pwm_sig));	// right motor pwm

endmodule
