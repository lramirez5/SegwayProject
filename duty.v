module duty(ptch_err_sat, rev, ptch_D_diff_sat, ptch_err_I, mtr_duty);

input signed [6:0] ptch_D_diff_sat;
input signed [9:0] ptch_err_sat, ptch_err_I;

output [10:0] mtr_duty;
output rev;

wire [9:0] ptch_P_term, ptch_I_term;
wire [10:0] ptch_D_term;
wire [11:0] ptch_PID, ptch_PID_abs;

localparam MIN_DUTY = 15'h03D4;

//assign ptch_D_term = ptch_D_diff_sat[6] ? 
//			~((~(ptch_D_diff_sat << 3) + 1) + (~ptch_D_diff_sat + 1)) + 1 :
//			(ptch_D_diff_sat << 3) + ptch_D_diff_sat;
assign ptch_D_term = ptch_D_diff_sat * $signed(9);
assign ptch_P_term = {ptch_err_sat[9], ptch_err_sat[9:1]} + {{2{ptch_err_sat[9]}}, ptch_err_sat[9:2]};
assign ptch_I_term = {ptch_err_I[9], ptch_err_I[9:1]};

assign ptch_PID = {ptch_P_term[9], ptch_P_term} + {ptch_I_term[9], ptch_I_term} + ptch_D_term;

assign rev = ptch_PID[11];

assign ptch_PID_abs = ptch_PID[11] ? ~ptch_PID + 1 : ptch_PID;

assign mtr_duty = MIN_DUTY + ptch_PID_abs;

endmodule