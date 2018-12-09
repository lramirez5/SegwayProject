module steer_en_SM_tb();

  ////////////////////////////////////////////////
  // Declare any registers needed for stimulus //
  //////////////////////////////////////////////
  
  reg clk, rst_n;
  reg [11:0] lft_ld, rght_ld;

  ////////////////////////////////////////////
  // declare wires to hook SM output up to //
  //////////////////////////////////////////
  wire en_steer, rider_off;
  
  //////////////////////
  // Instantiate DUT //
  ////////////////////
  steer_en_SM #(1'b1)
		iDUT(.clk(clk),.rst_n(rst_n), .lft_load(lft_ld), .rght_load(rght_ld), .en_steer(en_steer), .rider_off(rider_off));
  
  initial begin
    clk=0;
	rst_n = 0;
	lft_ld = 12'h000;
	rght_ld = 12'h000;
	
	@(posedge clk);
	@(negedge clk);
	rst_n = 1;			// deassert reset at negedge of clock
	/////////////////////////////////////////////////////////////
	// First check no outputs occur when both differences are //
	// less than, but sum_gt_min has not yet occurred.       //
	//////////////////////////////////////////////////////////
	repeat (4) begin
	  if (en_steer | ~rider_off) begin
	    $display("ERROR: no outputs should occur until rider exceed min weight\n");
		$stop();
	  end
	  @(negedge clk);
	end
	
	//////////////////////////////////////////////////////////
	// Now assert lft_ld and check for clr_tmr //
	////////////////////////////////////////////////////////
	lft_ld = 12'h400;
//	sum_gt_min = 1;
//	sum_lt_min = 0;
//	diff_gt_eigth = 1;
	@(negedge clk);
	if (!iDUT.clr_tmr) begin
	  $display("ERROR: clr_tmr should be asserted after sum_gt_min becomes true\n");
	  $stop();
	end

	//////////////////////////////////////////////////////////////
	// Check no outputs occur when diff_gt_eigth is asserted.  //
	// Also check that clr_tmr is asserted in this condition. //
	///////////////////////////////////////////////////////////
	repeat (6) begin
	  if (en_steer | rider_off) begin
	    $display("ERROR: no outputs should occur until rider exceed min weight\n");
		$stop();
	  end
	  if (!iDUT.clr_tmr) begin
	    $display("ERROR: clr_tmr should be asserted this time\n");
	    $stop();
	  end
	  @(negedge clk);
	end
	
	////////////////////////////////////////////////////////////
	// Now ensure that timer has to expire prior to en_steer //
	//////////////////////////////////////////////////////////
	rght_ld = 12'h400;
//	diff_gt_eigth = 0;
	repeat (4) begin
	  if (en_steer | rider_off) begin
	    $display("ERROR: no outputs should occur until timer expires\n");
		$stop();
	  end
	  @(negedge clk);
	end	

	/////////////////////////////////////////////////////////////////////////////
	// When tmr_full becomes true en_steer should become true one clock later //
	///////////////////////////////////////////////////////////////////////////	
	@(iDUT.tmr_full);
	@(negedge clk);
	if (!en_steer) begin
	  $display("ERROR: en_steer should be set now\n");
	  $stop();
	end	

	//////////////////////////////////////////////////////////////	
    // Nothing should happend until diff_gt_15_16 becomes true //
    ////////////////////////////////////////////////////////////
	@(negedge clk);
	rght_ld = 12'h200;
//	diff_gt_eigth = 1;
	@(negedge clk);
	repeat (4) begin
	  if (!en_steer | rider_off) begin
	    $display("ERROR: no outputs should change until diff_gt_15_16\n");
		$stop();
	  end
	  @(negedge clk);
	end	
	
	/////////////////////////////////////////////////////////////////
	// Now diff_gt_15_16 is asserted and it should clear en_steer //
	///////////////////////////////////////////////////////////////
	rght_ld = 12'h008;
//	diff_gt_15_16 = 1;
	@(negedge clk)
	if (en_steer) begin
	  $display("ERROR: clr_en_steer should be set now\n");
	  $stop();
	end	
	
	///////////////////////////////////////////////////////
	// should now be waiting for sum_lt_min (rider off) //
	/////////////////////////////////////////////////////
	@(negedge clk);
	if (iDUT.state==2'b00) begin
	  $display("ERROR: you should not be in first state again, you\n");
	  $display("       need to wait for sum_lt_min to rise first.\n");
	  $stop();
	end

	///////////////////////////////////////////////////////////////////////////
	// Now assert sum_lt_min and it should transition back to initial state //
	/////////////////////////////////////////////////////////////////////////
	lft_ld = 12'h100;
//	sum_gt_min = 0;
//    sum_lt_min = 1;
    @(negedge clk);
	if (iDUT.state==2'b00) begin
	  $display("Yahoo! test passed!\n");
	  $display("However, We did not test that when in normal mode with\n");
	  $display("steering enabled you transition to the initial state and\n");
	  $display("assert rider_off if sum_lt_min occurs.  You should test that\n");
//	  $stop();
	end	else begin
	  $display("ERROR: You should be back to reset state\n");
	  $stop();
	end

/////////////////////////////////////////////
	lft_ld = 12'h000;
	rght_ld = 12'h000;
//	diff_gt_15_16 = 0;
//	diff_gt_eigth = 0;
	repeat (4) begin
	  if (en_steer | ~rider_off) begin
	    $display("ERROR: only rider_off output should occur until rider exceed min weight\n");
		$stop();
	  end
	  @(negedge clk);
	end
	
	//////////////////////////////////////////////////
	// Now assert sum_gt_min and check for clr_tmr //
	////////////////////////////////////////////////
	rght_ld = 12'h300;
//	sum_gt_min = 1;
//	sum_lt_min = 0;
//	diff_gt_eigth = 1;
	@(negedge clk);
	if (!iDUT.clr_tmr) begin
	  $display("ERROR: clr_tmr should be asserted after sum_gt_min becomes true\n");
	  $stop();
	end

	//////////////////////////////////////////////////////////////
	// Check no outputs occur when diff_gt_eigth is asserted.  //
	// Also check that clr_tmr is asserted in this condition. //
	///////////////////////////////////////////////////////////
	repeat (6) begin
	  if (en_steer | rider_off) begin
	    $display("ERROR: no outputs should occur until rider exceed min weight\n");
		$stop();
	  end
	  if (!iDUT.clr_tmr) begin
	    $display("ERROR: clr_tmr should be asserted this time\n");
	    $stop();
	  end
	  @(negedge clk);
	end
	
	////////////////////////////////////////////////////////////
	// Now ensure that timer has to expire prior to en_steer //
	//////////////////////////////////////////////////////////
	lft_ld = 12'h280;
//	diff_gt_eigth = 0;
	repeat (4) begin
	  if (en_steer | rider_off) begin
	    $display("ERROR: no outputs should occur until timer expires\n");
		$stop();
	  end
	  @(negedge clk);
	end	

	/////////////////////////////////////////////////////////////////////////////
	// When tmr_full becomes true en_steer should become true one clock later //
	///////////////////////////////////////////////////////////////////////////	
	@(iDUT.tmr_full);
	@(negedge clk);
	if (!en_steer) begin
	  $display("ERROR: en_steer should be set now\n");
	  $stop();
	end	
	@(negedge clk);
	//////////////////////////////////////////////////////////////	
    // Nothing should happend until diff_gt_15_16 becomes true //
    ////////////////////////////////////////////////////////////
	lft_ld = 12'h120;
//	diff_gt_eigth = 1;
	@(negedge clk);

	repeat (4) begin
	  if (!en_steer | rider_off) begin
	    $display("ERROR: no outputs should change until diff_gt_15_16\n");
		$stop();
	  end
	  @(negedge clk);
	end	

	rght_ld = 12'h040;
//	sum_gt_min = 0;
//    sum_lt_min = 1;
    @(negedge clk);
	if (iDUT.state==2'b00 & rider_off) begin
	  $display("Yahoo! test passed!\n");
	  $display("We DID test that when in normal mode with\n");
	  $display("steering enabled you transition to the initial state and\n");
	  $display("assert rider_off if sum_lt_min occurs.\n");
	  $stop();
	end	else begin
	  $display("ERROR: You should be back to reset state with rider_off asserted\n");
	  $stop();
	end

	
  end
  
  always
    #20 clk = ~clk;
	
endmodule