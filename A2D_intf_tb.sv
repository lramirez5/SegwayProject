module A2D_intf_tb();

reg clk, rst_n, nxt, write;
reg [11:0] lft_load_in, rght_load_in, battery_level_in;

wire MISO, a2d_SS_n, SCLK, MOSI;
wire [11:0] lft_ld, rght_ld, batt;

A2D_intf iDUT(.clk(clk), .rst_n(rst_n), .nxt(nxt), .MISO(MISO), .lft_ld(lft_ld), .rght_ld(rght_ld), .batt(batt), .a2d_SS_n(a2d_SS_n), .SCLK(SCLK), .MOSI(MOSI));

ADC128S A2D(.clk(clk), .rst_n(rst_n), .SS_n(a2d_SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI),
			.lft_ld_val(lft_load_in),
			.rght_ld_val(rght_load_in),
			.batt_val(battery_level_in),
			.write(write));

initial begin
	clk = 0;
	rst_n = 0;
	nxt = 0;
	write = 0;
	lft_load_in = 12'h400;
	rght_load_in = 12'h400;
	battery_level_in = 12'hFFE;

	repeat (2) @(negedge clk);
	rst_n = 1;

	@(negedge clk);
	write = 1;
	@(negedge clk);
	write = 0;

repeat (1100) begin
	@(negedge clk) nxt = 1;
	@(negedge clk) nxt = 0;

	@(lft_ld)
	repeat (2) @(negedge clk);

	$display("lft_ld = %h", lft_ld);

	@(negedge clk) nxt = 1;
	@(negedge clk) nxt = 0;

	@(rght_ld)
	repeat (2) @(negedge clk);

	$display("rght_ld = %h", rght_ld);

	@(negedge clk) nxt = 1;
	@(negedge clk) nxt = 0;

	@(batt);

	repeat (2) @(negedge clk);

	$display("batt = %h", batt);

	@(negedge clk);

	lft_load_in = lft_load_in - 4;
	rght_load_in = rght_load_in - 3;
	battery_level_in = battery_level_in - 1;

	write = 1;
	@(negedge clk);
	write = 0;
end
	$stop;

end

always
	#5 clk <= ~clk;

endmodule
