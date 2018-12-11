task RunFullTest;
  begin
	Initialize();

	repeat (100) @(negedge clk);

	SendCmd_g();

	SendCmd_s();

	SendCmd_g();

	repeat (100) @(negedge clk);

	SetLoadCells(12'h400, 12'h000);

	repeat (100) @(negedge clk);

	//CheckSteerEn();

	repeat (100) @(negedge clk);
  end
endtask



//sends command to start up Segway
task SendCmd_g;
  begin
    	cmd = 8'h67;
    	send_cmd = 1;
    	@(negedge clk);
    	send_cmd = 0;
    	@(cmd_sent);

	if(iDUT.piezo_DUT.wave | ~iDUT.piezo_DUT.wave) begin
		$display("Why did this work?");
	end

	repeat (2) @(negedge clk);
	$display("'g' sent");
	if(!iDUT.pwr_up) begin
		$display("ERROR: pwr_up should be 1");
		$stop;
	end
	$display("Power up");
  end
endtask

//sends command to start up Segway
task SendCmd_s;
  begin
    	cmd = 8'h73;
    	send_cmd = 1;
    	@(negedge clk);
    	send_cmd = 0;
    	@(cmd_sent);

	repeat (2) @(negedge clk);
	$display("'s' sent");
	if(!iDUT.pwr_up & ~iDUT.rider_off) begin
		$display("ERROR: pwr_up should be 1 when rider_off is 0");
		$stop;
	end
	else if(iDUT.pwr_up & iDUT.rider_off) begin
		$display("ERROR: pwr_up should be 0 when rider_off is 1");
		$stop;
	end
	$display("'s' command done");
  end
endtask

task SetLoadCells;
  input reg [11:0] lft, rght;
  begin
	@(negedge clk);	
	lft_load = lft;
	rght_load = rght;
	@(negedge clk);
	$display("Load cells were set with values: %h and %h", iA2D.lft_ld, iA2D.rght_ld);
  end
endtask

task CheckSteerEn;
  begin
	//repeat (4) begin
	  $display("Checking steer_en_SM");
	  @(negedge clk);
	  $display("starting checks");
	  if (iDUT.steer_en_DUT.sum_lt_min & (iDUT.en_steer | ~iDUT.rider_off)) begin
	    $display("ERROR: no outputs should occur until rider exceed min weight");
		$stop();
	  end
	  $display("1 check passed");
	  if (iDUT.steer_en_DUT.sum_gt_min & !iDUT.steer_en_clr_tmr) begin
	  	$display("ERROR: clr_tmr should be asserted after sum_gt_min becomes true");
	  	$stop();
	  end
	  $display("2 check passed");
	  if (iDUT.steer_en_DUT.diff_gt_1_4 & ~iDUT.steer_en_DUT.diff_gt_15_16 & (iDUT.en_steer | iDUT.rider_off)) begin
	    $display("ERROR: no outputs should occur until rider exceed min weight");
		$stop();
	  end
	  $display("3 check passed");
	  if (iDUT.steer_en_DUT.diff_gt_1_4 & ~iDUT.steer_en_DUT.diff_gt_15_16 & !iDUT.clr_tmr) begin
	    $display("ERROR: clr_tmr should be asserted this time");
	    $stop();
	  end
	  $display("4 check passed");
	  if (iDUT.steer_en_DUT.sum_gt_min & ~iDUT.steer_en_tmr_full & (iDUT.en_steer | iDUT.rider_off)) begin
	    $display("ERROR: no outputs should occur until timer expires");
		$stop();
	  end
	  $display("5 check passed");
	//  @(iDUT.steer_en_tmr_full);
	//  @(negedge clk);
	  if (iDUT.steer_en_DUT.sum_gt_min & ~iDUT.steer_en_DUT.diff_gt_1_4 & !iDUT.en_steer) begin
		$display("ERROR: en_steer should be set now");
		$stop();
	  end
	  $display("6 check passed");
	  if (iDUT.en_steer & ~iDUT.steer_en_DUT.diff_gt_15_16 & (!iDUT.en_steer | iDUT.rider_off)) begin
		$display("ERROR: no outputs should change until diff_gt_15_16");
		$stop();
	  end
	  $display("7 check passed");
	  if (iDUT.steer_en_DUT.diff_gt_15_16 & iDUT.en_steer) begin
		$display("ERROR: clr_en_steer should be set now");
		$stop();
	  end
	  $display("8 check passed");
	  if (iDUT.steer_en_DUT.state!=0 & iDUT.steer_en_DUT.sum_lt_min) begin
		$display("ERROR: steer_en_SM should be in the idle state now");
		$stop();
	  end
	  $display("9 check passed");
	  @(negedge clk);
	  $display("All steer_en_SM checks passed");
	//end
  end
endtask

//initialize all signals and apply reset
task Initialize;
  begin
    	clk = 0;
    	cmd = 8'h00;
    	send_cmd = 0;
    	rider_lean = 16'h0000;
    	lft_load = 12'h000;
    	rght_load = 12'h000;
    	battery_level = 12'hFFF;
    	RST_n = 0;
    	repeat (2) @(negedge clk);
    	RST_n = 1;
    	$display("Initialization finished");
  end
endtask
