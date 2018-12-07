module piezo_tb();

reg clk, rst_n, en_steer, ovr_spd, batt_low;

wire piezo, piezo_n, en_steer_piezo, en_steer_piezo_n, ovr_spd_piezo, ovr_spd_piezo_n, batt_low_piezo, batt_low_piezo_n;

piezo iDUT_en_steer(.clk(clk), .rst_n(rst_n), .en_steer(en_steer), .ovr_spd(1'b0), .batt_low(1'b0), .piezo(en_steer_piezo), .piezo_n(en_steer_piezo_n));
piezo iDUT_ovr_spd (.clk(clk), .rst_n(rst_n), .en_steer(1'b0), .ovr_spd(ovr_spd), .batt_low(1'b0), .piezo(ovr_spd_piezo), .piezo_n(ovr_spd_piezo_n));
piezo iDUT_batt_low(.clk(clk), .rst_n(rst_n), .en_steer(1'b0), .ovr_spd(1'b0), .batt_low(batt_low), .piezo(batt_low_piezo), .piezo_n(batt_low_piezo_n));

initial begin
	clk = 0;
	rst_n = 0;
	
	en_steer = 0;
	ovr_spd = 0;
	batt_low = 0;

	repeat (2) @(negedge clk);
	rst_n = 1;

	en_steer = 1;
	ovr_spd = 1;
	batt_low = 1;

	repeat (2000000000) @(negedge clk);
	$stop;

end

always
	#1 clk <= ~clk;

endmodule
