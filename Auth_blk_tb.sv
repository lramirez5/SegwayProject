module Auth_blk_tb();

reg trmt, rider_off, clk,rst_n;
reg [7:0] tx_data;
wire immX, power_up, tx_done;

UART_tx iX(.clk(clk), .rst_n(rst_n), .trmt(trmt), .tx_data(tx_data), .TX(immX), .tx_done(tx_done));


Auth_blk iDUT(.clk(clk), .rst_n(rst_n), .RX(immX), .rider_off(rider_off), .pwr_up(pwr_up));

initial begin
	clk = 0;
	rst_n = 0;
	trmt = 0;
	rider_off = 0;

	repeat (2) @(negedge clk);
	rst_n = 1;

	tx_data = 8'h33;	// Stay in IDLE
	trmt=1;
	@(negedge clk);
	trmt = 0;
	@(tx_done);
	//@(iDUT.rx_rdy);

	repeat (2) @(negedge clk);
	$display("State: %h", iDUT.state);
	if(pwr_up) begin
		$display("pwr_up should be 0");
		$stop;
	end

	repeat (2) @(negedge clk);
	tx_data = 8'h67;	// Send 'g' and move to PWR1
	trmt=1;
	@(negedge clk);
	trmt = 0;
	@(tx_done);
	//@(iDUT.rx_rdy);

	repeat (2) @(negedge clk);
	$display("State: %h", iDUT.state);
	if(!pwr_up) begin
		$display("pwr_up should be 1");
		$stop;
	end

	repeat (2) @(negedge clk);
	tx_data = 8'h00;	// Stay in PWR1
	trmt=1;
	@(negedge clk);
	trmt = 0;
	@(tx_done);

	repeat (2) @(negedge clk);
	$display("State: %h", iDUT.state);
	if(!pwr_up) begin
		$display("pwr_up should be 1");
		$stop;
	end

	repeat (2) @(negedge clk);
	tx_data = 8'h73;	// Send 's' and move to PWR2
	trmt=1;
	@(negedge clk);
	trmt = 0;
	@(tx_done);

	repeat (2) @(negedge clk);
	$display("State: %h", iDUT.state);
	if(!pwr_up) begin
		$display("pwr_up should be 1");
		$stop;
	end

	repeat (2) @(negedge clk);
	tx_data = 8'h67;	// Send 'g' and move to PWR1
	trmt=1;
	@(negedge clk);
	trmt = 0;
	@(tx_done);

	repeat (2) @(negedge clk);
	$display("State: %h", iDUT.state);
	if(!pwr_up) begin
		$display("pwr_up should be 1");
		$stop;
	end
	
	repeat (2) @(negedge clk);
	tx_data = 8'h73;	// Send 's' and move to PWR2
	trmt=1;
	@(negedge clk);
	trmt = 0;
	@(tx_done);

	repeat (2) @(negedge clk);
	$display("State: %h", iDUT.state);
	if(!pwr_up) begin
		$display("pwr_up should be 1");
		$stop;
	end

	repeat (50) @(negedge clk);	// Stay in PWR2
	$display("State: %h", iDUT.state);
	if(!pwr_up) begin
		$display("pwr_up should be 1");
		$stop;
	end

	rider_off = 1;		// Move to OFF
	
	repeat (2) @(negedge clk);
	$display("State: %h", iDUT.state);
	if(pwr_up) begin
		$display("pwr_up should be 0");
		$stop;
	end

	repeat (50) @(negedge clk);	// Stay in IDLE
	$display("State: %h", iDUT.state);
	if(pwr_up) begin
		$display("pwr_up should be 0");
		$stop;
	end

	$stop;
	 
end

always 
	#5 clk = ~clk;

endmodule 