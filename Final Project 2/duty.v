//Lucas Wysiatko
module duty(ptch_D_diff_sat, ptch_err_sat, ptch_err_I, rev, mtr_duty);

  input signed [6:0] ptch_D_diff_sat;
  input signed [9:0] ptch_err_sat, ptch_err_I;
  output rev;
  output [10:0] mtr_duty;

  wire signed [11:0] ptch_D_term; //7 bits from ptch_D_diff_sat and 5 from times 9 (4 bits plus one for signed)
  wire signed [9:0] ptch_P_term;
  wire signed [9:0] ptch_I_term;
  wire signed [12:0] ptch_PID;
  wire [13:0] pos_ptch_PID;
  wire [10:0] ptch_PID_abs;

  localparam MIN_DUTY = 15'h03D4;

  assign ptch_D_term = ptch_D_diff_sat * $signed(9);

  assign ptch_P_term = (ptch_err_sat >>> 1) + (ptch_err_sat >>> 2);

  assign ptch_I_term = ptch_err_I >>> 1;

  assign ptch_PID = ptch_D_term + ptch_P_term + ptch_I_term;

  assign rev = ptch_PID[12];

  assign pos_ptch_PID = ~ptch_PID + 1;

  assign ptch_PID_abs = rev ? pos_ptch_PID[10:0]: ptch_PID[10:0];

  assign mtr_duty = MIN_DUTY + ptch_PID_abs;

endmodule
