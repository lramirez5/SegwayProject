module inert_intf_tb();

reg clk, rst_n;

wire INT, MISO, MOSI, SCLK, SS_n;

wire valid;
wire [15:0] pitch;

inert_intf iDUT(.clk(clk), .rst_n(rst_n), .INT(INT), .MISO(MISO), .MOSI(MOSI), .SCLK(SCLK), .SS_n(SS_n), .vld(valid), .ptch(pitch));

SegwayModel model(.clk(clk), .RST_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT),
			.PWM_rev_rght(1'b0), .PWM_frwrd_rght(1'b0), .PWM_rev_lft(1'b0), .PWM_frwrd_lft(1'b0), .rider_lean(-14'h0100));

reg setup_done;

initial begin
	clk = 0;
	rst_n = 0;
	setup_done = 0;

	repeat (2) @(negedge clk);
	rst_n = 1;

	@(posedge model.NEMO_setup) $display("Inertial sensor setup complete");
	setup_done = 1;

	forever @(posedge valid) $display("PITCH = %h", pitch);
end

initial begin
	@(posedge setup_done);
	repeat (500000) @(posedge clk);
	$stop; 
end

always
	#5 clk <= ~clk;

endmodule
