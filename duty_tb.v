module duty_tb();

reg signed [6:0] ptch_D_diff_sat;
reg signed [9:0] ptch_err_sat, ptch_err_I;

wire [10:0] mtr_duty;
wire rev;

duty iDUT(.ptch_D_diff_sat(ptch_D_diff_sat), .ptch_err_sat(ptch_err_sat), .ptch_err_I(ptch_err_I),
		.mtr_duty(mtr_duty), .rev(rev));

initial begin
	ptch_D_diff_sat = 1;
	ptch_err_sat = 4;
	ptch_err_I = -4;
	#5;
	ptch_D_diff_sat = -8;
	ptch_err_sat = -16;
	ptch_err_I = 6;
	#5;
end

endmodule
