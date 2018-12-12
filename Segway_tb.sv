`timescale 1ns/1ps
module Segway_tb();
			
//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;				// to inertial sensor
wire A2D_SS_n,A2D_SCLK,A2D_MOSI,A2D_MISO;	// to A2D converter
wire RX_TX;
wire PWM_rev_rght, PWM_frwrd_rght, PWM_rev_lft, PWM_frwrd_lft;
wire piezo,piezo_n;

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] cmd;					// command host is sending to DUT
reg send_cmd;					// asserted to initiate sending of command
reg signed [15:0] rider_lean;	// forward/backward lean (goes to SegwayModel)
// Perhaps more needed?
reg [11:0] lft_load, rght_load, battery_level;
reg write;

/////// declare any internal signals needed at this level //////
wire cmd_sent;
// Perhaps more needed?


////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Segway with Inertial sensor //
//////////////////////////////////////////////////////////////	
SegwayModel iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),
                  .MISO(MISO),.MOSI(MOSI),.INT(INT),.PWM_rev_rght(PWM_rev_rght),
				  .PWM_frwrd_rght(PWM_frwrd_rght),.PWM_rev_lft(PWM_rev_lft),
				  .PWM_frwrd_lft(PWM_frwrd_lft),.rider_lean(rider_lean));				  

/////////////////////////////////////////////////////////
// Instantiate Model of A2D for load cell and battery //
///////////////////////////////////////////////////////
/*
  What is this?  You need to build some kind of wrapper around ADC128S.sv or perhaps
  around SPI_ADC128S.sv that mimics the behavior of the A2D converter on the DE0 used
  to read ld_cell_lft, ld_cell_rght and battery
*/  
ADC128S iA2D(.clk(clk),.rst_n(RST_n),//.ld_cell_lft(ld_cell_lft),.ld_cell_rght(ld_cell_rght),//inputs
			.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
			.MOSI(A2D_MOSI),//inputs
			.MISO(A2D_MISO),
			.lft_ld_val(lft_load),
			.rght_ld_val(rght_load),
			.batt_val(battery_level),
			.write(write));

  
////// Instantiate DUT ////////
Segway iDUT(.clk(clk),.RST_n(RST_n),.LED(),.INERT_SS_n(SS_n),.INERT_MOSI(MOSI),
            .INERT_SCLK(SCLK),.INERT_MISO(MISO),.A2D_SS_n(A2D_SS_n),
			.A2D_MOSI(A2D_MOSI),.A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),
			.INT(INT),.PWM_rev_rght(PWM_rev_rght),.PWM_frwrd_rght(PWM_frwrd_rght),
			.PWM_rev_lft(PWM_rev_lft),.PWM_frwrd_lft(PWM_frwrd_lft),
			.piezo_n(piezo_n),.piezo(piezo),.RX(RX_TX));


	
//// Instantiate UART_tx (mimics command from BLE module) //////
//// You need something to send the 'g' for go ////////////////
UART_tx iTX(.clk(clk),.rst_n(RST_n),.TX(RX_TX),.trmt(send_cmd),.tx_data(cmd),.tx_done(cmd_sent));


initial begin

  RunFullTest;

/*
  Initialize;		
 
	
  repeat(50000) @(posedge clk);
 
  SendCmd(8'h67);	// perhaps you have a task that sends 'g' 
 
  rider_lean = 16'h1FFF;
  
  //ewpwRCRO
  repeat(2000000) @(negedge clk);

  rider_lean = 16'h0000;
	
  repeat(2000000) @(negedge clk);
  
  SendCmd(8'h00);

  repeat(100) @(posedge clk);
  rider_lean = 16'h001; 
  

  //Checked at this point power should be up.
  $stop;
  
  repeat(200)@(negedge clk);
  SendCmd (8'h73);
  repeat(400000)@(negedge clk);
  //send_cmd = 1'b0;
  
  
  //check if auth blk is in pwr2 state
  $stop; 
*/  
  
/*
    .
	.	// this is the "guts" of your test
	.
*/	
  $display("YAHOO! test passed!");
  
  $stop();
end

always
  #10 clk = ~clk;

//`include "tasks.sv"	// perhaps you have a separate included file that has handy tasks.
// For some reason, these tasks don't run correctly if they're read from a separate file
task RunFullTest;
	GetReadyToDrive;

	SetLeanAndDrive(16'h1FFF, 32'd1000000);
	SetLeanAndDrive(16'h0000, 32'd1000000);

	Drive_ZigZag();
endtask

task GetReadyToDrive;
  begin
	Initialize();

	@(negedge clk);

	SendCmd_g();

	SendCmd_s();

	SendCmd_g();

	//repeat (100) @(negedge clk);

	SetLoadCells(12'h400, 12'h000);

	//repeat (10000) @(negedge clk);

	CheckSteerEn();

	//repeat (100) @(negedge clk);

	SetLoadCells(12'h400, 12'h400);

	//repeat (10000) @(negedge clk);

	CheckSteerEn();

	repeat (100) @(negedge clk);

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
    	battery_level = 12'hFFE;
	write = 0;
    	RST_n = 0;
    	repeat (2) @(negedge clk);
    	RST_n = 1;
	$display("Waiting for inertial sensor startup");
	wait(iDUT.inert_intf_DUT.state == 4'h5);
    	$display("Initialization finished");
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
	write = 1;
	@(negedge clk);
	write = 0;
	$display("Load cells were set with values: %h and %h", iA2D.lft_ld, iA2D.rght_ld);
	repeat (500000) @(negedge clk);
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
	  if (iDUT.steer_en_DUT.sum_gt_min & iDUT.steer_en_DUT.diff_gt_1_4 & !iDUT.steer_en_clr_tmr) begin
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
	  if (iDUT.steer_en_DUT.state==1 & iDUT.steer_en_DUT.sum_gt_min & ~iDUT.steer_en_tmr_full & (iDUT.en_steer | iDUT.rider_off)) begin
	    $display("ERROR: no outputs should occur until timer expires");
		$stop();
	  end
	  $display("5 check passed");
	  if(iDUT.steer_en_DUT.state==1 & iDUT.steer_en_DUT.sum_gt_min & ~iDUT.steer_en_DUT.diff_gt_1_4) begin
	    @(iDUT.steer_en_tmr_full);
	    @(negedge clk);
	    if (iDUT.steer_en_DUT.sum_gt_min & ~iDUT.steer_en_DUT.diff_gt_1_4 & !iDUT.en_steer) begin
		$display("ERROR: en_steer should be set now");
		$stop();
	    end
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
	  $display("steer_en_SM state = %h, rider_off = %b, en_steer = %b", iDUT.steer_en_DUT.state, iDUT.rider_off, iDUT.en_steer);
	//end
  end
endtask

task SetLeanAndDrive;
  input reg [15:0] lean;
  input reg [31:0] cycles;
  begin
	@(negedge clk);
	rider_lean = lean;

	while (cycles != 0) begin
		cycles = cycles - 1;
		@(negedge clk);
	end
  end
endtask

task Drive_ZigZag;
  begin
	
  end
endtask

endmodule	
