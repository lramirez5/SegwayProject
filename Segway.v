module Segway(clk,RST_n,LED,INERT_SS_n,INERT_MOSI,
              INERT_SCLK,INERT_MISO,A2D_SS_n,A2D_MOSI,A2D_SCLK,
			  A2D_MISO,PWM_rev_rght,PWM_frwrd_rght,PWM_rev_lft,
			  PWM_frwrd_lft,piezo_n,piezo,INT,RX);
			  
  input clk,RST_n;
  input INERT_MISO;						// Serial in from inertial sensor
  input A2D_MISO;						// Serial in from A2D
  input INT;							// Interrupt from inertial indicating data ready
  input RX;								// UART input from BLE module

  
  output [7:0] LED;						// These are the 8 LEDs on the DE0, your choice what to do
  output A2D_SS_n, INERT_SS_n;			// Slave selects to A2D and inertial sensor
  output A2D_MOSI, INERT_MOSI;			// MOSI signals to A2D and inertial sensor
  output A2D_SCLK, INERT_SCLK;			// SCLK signals to A2D and inertial sensor
  output PWM_rev_rght, PWM_frwrd_rght;  // right motor speed controls
  output PWM_rev_lft, PWM_frwrd_lft;	// left motor speed controls
  output piezo_n,piezo;					// diff drive to piezo for sound
  
  ////////////////////////////////////////////////////////////////////////
  // fast_sim is asserted to speed up fullchip simulations.  Should be //
  // passed to both balance_cntrl and to steer_en.  Should be set to  //
  // 0 when we map to the DE0-Nano.                                  //
  ////////////////////////////////////////////////////////////////////
  localparam fast_sim = 1'b1;	// asserted to speed up simulations. 
  
  ///////////////////////////////////////////////////////////
  ////// Internal interconnecting sigals defined here //////
  /////////////////////////////////////////////////////////
  wire rst_n;                           // internal global reset that goes to all units
  
  // You will need to declare a bunch more interanl signals to hook up everything
  
  ////////////////////////////////////

  localparam BATT_THRESHOLD = 12'h800;

  wire [11:0] lft_ld, rght_ld, batt;

  wire pwr_up;

  wire [15:0] ptch;
  wire vld;

  wire [10:0] lft_spd, rght_spd;
  wire lft_rev, rght_rev, too_fast;

  wire rider_off, en_steer, clr_tmr;

  wire batt_low;
  assign batt_low = $unsigned(batt) < $unsigned(BATT_THRESHOLD);

  wire [11:0] load_cell_diff;
  wire steer_en_tmr_full, steer_en_clr_tmr;
   
  
  ///////////////////////////////////////////////////////
  // How you arrange the hierarchy of the top level is up to you.
  //
  // You could make a level of hierarchy called digital core
  // as shown in the block diagram in the spec.
  //
  // Or you could just instantiate all the components of the Segway
  // flat.
  //
  // Just for reference all the needed blocks (in no particular order) would be:
  //   Auth_blk
  //   inert_intf
  //   balance_cntrl
  //   steer_en
  //   mtr_drv
  //   A2D_intf
  //   piezo
  //////////////////////////////////////////////////////
  
  A2D_intf a2d_intf_DUT(// Inputs
			.clk(clk),
			.rst_n(rst_n),
			.nxt(vld),
			.MISO(A2D_MISO),
			// Outputs
			.lft_ld(lft_ld),
			.rght_ld(rght_ld),
			.batt(batt),
			.a2d_SS_n(A2D_SS_n),
			.SCLK(A2D_SCLK),
			.MOSI(A2D_MOSI)
			);

  Auth_blk auth_blk_DUT(// Inputs
			.clk(clk),
			.rst_n(rst_n),
			.RX(RX),
			.rider_off(rider_off),
			// Output
			.pwr_up(pwr_up));

  mtr_drv mtr_drv_DUT(	// Inputs
			.clk(clk),
			.rst_n(rst_n),
			.lft_spd(lft_spd),
			.rght_spd(rght_spd),
			.lft_rev(lft_rev),
			.rght_rev(rght_rev),
			// Outputs 
			.PWM_rev_lft(PWM_rev_lft),
			.PWM_rev_rght(PWM_rev_rght),
			.PWM_frwrd_lft(PWM_frwrd_lft),
			.PWM_frwrd_rght(PWM_frwrd_rght)
		      );

  piezo #(fast_sim)
	piezo_DUT(	// Inputs
			.clk(clk),
			.rst_n(rst_n),
			.en_steer(en_steer),
			.ovr_spd(too_fast),
			.batt_low(batt_low),
			.steer_en_clr_tmr(steer_en_clr_tmr),
			// Outputs
			.piezo(piezo),
			.piezo_n(piezo_n),
			.steer_en_tmr_full(steer_en_tmr_full)
		  );

  inert_intf inert_intf_DUT(	// Inputs
				.clk(clk),
				.rst_n(rst_n),
				.INT(INT),
				.MISO(INERT_MISO),
				// Outputs
				.vld(vld),
				.ptch(ptch),
				.SS_n(INERT_SS_n),
				.SCLK(INERT_SCLK),
				.MOSI(INERT_MOSI)
			    );

  balance_cntrl #(fast_sim)
		balance_ctrl_DUT(// Inputs
				.clk(clk),
				.rst_n(rst_n),
				.pwr_up(pwr_up),
				.vld(vld),
				.ptch(ptch),
				.ld_cell_diff(load_cell_diff),	// need to calculate load difference
				.rider_off(rider_off),
				.en_steer(en_steer),
				// Outputs
				.lft_spd(lft_spd),
				.lft_rev(lft_rev),
				.rght_spd(rght_spd),
				.rght_rev(rght_rev),
				.too_fast(too_fast)
				);

  steer_en_SM steer_en_DUT(	// Inputs
				.clk(clk),
				.rst_n(rst_n),
				.lft_load(lft_ld),
				.rght_load(rght_ld),
				.tmr_full(steer_en_tmr_full),
				// Outputs
				.en_steer(en_steer),
				.rider_off(rider_off),
				.load_cell_diff(load_cell_diff),
				.clr_tmr(steer_en_clr_tmr)
			   );

  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////  
  rst_synch iRST(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));
  
endmodule
