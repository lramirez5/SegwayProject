
module balance_cntrl_chk_tb();

reg clk;
reg [31:0] stim;
reg [23:0] expected;
wire [23:0] resp;

// Memories
reg [31:0] stim_mem[0:999];
reg [23:0] resp_mem[0:999];

reg [10:0] i;	// Used in for loop

balance_cntrl iDUT(.clk(clk), .rst_n(stim[31]), .vld(stim[30]), .ptch(stim[29:14]),
			.ld_cell_diff(stim[13:2]), .lft_spd(resp[22:12]), .lft_rev(resp[23]),
			.rght_spd(resp[10:0]), .rght_rev(resp[11]), .rider_off(stim[1]), .en_steer(stim[0]));

initial begin
	$readmemh("balance_cntrl_stim.hex", stim_mem);
	$readmemh("balance_cntrl_resp.hex", resp_mem);

	clk = 0;

	for(i = 0; i < 1000; i = i + 1) begin
		//@(negedge clk);
		stim = stim_mem[i];
		@(posedge clk);
		expected = resp_mem[i];	// Can use 'expected' for waveform debugging
		#1;
		if(resp != expected) begin
			$display("Response doesn't match expected response: resp = %h, expected = %h", resp, expected);
			$stop;
		end
	end
	
	$display("TEST PASSED");
	$stop;

end

always
	#5 clk <= ~clk;

endmodule