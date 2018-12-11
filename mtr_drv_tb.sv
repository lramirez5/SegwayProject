//Lucas Wysiatko
module mtr_drv_tb();

  reg clk, rst_n;
  reg [10:0] lft_spd_stm, rght_spd_stm;
  reg lft_rev_stm, rght_rev_stm;
  wire PWM_rev_lft, PWM_frwrd_lft, PWM_rev_rght, PWM_frwrd_rght;

  //instantiate mtr_drv module
  mtr_drv iDUT(.clk(clk), .rst_n(rst_n), .lft_spd(lft_spd_stm), .lft_rev(lft_rev_stm), 
               .PWM_rev_lft(PWM_rev_lft), .PWM_frwrd_lft(PWM_frwrd_lft),
               .rght_spd(rght_spd_stm), .rght_rev(rght_rev_stm), .PWM_rev_rght(PWM_rev_rght), 
               .PWM_frwrd_rght(PWM_frwrd_rght));

  initial begin
    clk = 0;
    rst_n = 0;
    #4;
    rst_n = 1;
   
   //left and right min duty 
    lft_spd_stm = 11'h000;
    rght_spd_stm = 11'h000;
    lft_rev_stm = 0;
    rght_rev_stm = 0;
    #8190;

    //left forward and right forward at mid duty(speed)
    lft_spd_stm = 11'h400;
    rght_spd_stm = 11'h400;
    lft_rev_stm = 0;
    rght_rev_stm = 0;
    #81900;

    //left forward and right reverse at mid duty(speed)
    lft_spd_stm = 11'h400;
    rght_spd_stm = 11'h400;
    lft_rev_stm = 1;
    rght_rev_stm = 1;
    #8190;

   //left forward and right reverse max duty 
    lft_spd_stm = 11'h7FF;
    rght_spd_stm = 11'h7FF;
    lft_rev_stm = 0;
    rght_rev_stm = 1;
    #8190;

    $stop();

  end

  always
    #2 clk = ~clk;

endmodule
