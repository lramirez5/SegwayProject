module PW11_tb();

reg clk, rst_n;
reg [10:0] duty;

wire pwm_sig;

PWM11 pwm(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM_sig(pwm_sig));

initial begin
  clk = 0;
  rst_n = 1;
  duty = 0;
  #81920;
  rst_n = 0;
  #40 rst_n = 1;
  duty = 11'b01111111111;
  #81920;
  rst_n = 0;
  #40 rst_n = 1;
  duty = 11'b11111111111;
  #81920;
  $stop();
end

always begin
  #10 clk <= ~clk;
end

endmodule
