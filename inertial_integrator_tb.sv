// Lorenzo Ramirez & George Akpan

module inertial_integrator_tb();

reg clk, rst_n, valid;
reg [15:0] pitch_rate, accel_Z;

wire [15:0] pitch;

localparam PTCH_RT_OFFSET = 16'h03C2;

inertial_integrator iDUT(.clk(clk), .rst_n(rst_n), .vld(valid), .ptch_rt(pitch_rate), .AZ(accel_Z), .ptch(pitch));

initial begin
	clk = 0;
	rst_n = 0;

	repeat (2) @(negedge clk);
	rst_n = 1;

	pitch_rate = 16'h1000 + PTCH_RT_OFFSET;
	accel_Z = 16'h0000;
	valid = 1;

	repeat (501) @(negedge clk);

	pitch_rate = PTCH_RT_OFFSET;

	repeat (1001) @(negedge clk);

	pitch_rate = PTCH_RT_OFFSET - 16'h1000;

	repeat (501) @(negedge clk);

	pitch_rate = PTCH_RT_OFFSET;

	repeat (1001) @(negedge clk);

	accel_Z = 16'h0800;

	repeat (1001) @(negedge clk);
	$stop;

end

always
	#5 clk <= ~clk;

endmodule
