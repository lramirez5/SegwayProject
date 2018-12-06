module balance_cntrl(clk, rst_n, vld, pwr_up, ptch, ld_cell_diff, rider_off, en_steer,
		     lft_spd, lft_rev, rght_spd, rght_rev, too_fast);

  parameter fast_sim = 1'b0;
								
  input clk, rst_n;
  input vld;						// tells when a new valid inertial reading ready
  input pwr_up;
  input signed [15:0] ptch;			// actual pitch measured
  input signed [11:0] ld_cell_diff;	// lft_ld - rght_ld from steer_en block
  input rider_off;					// High when weight on load cells indicates no rider
  input en_steer;
  output [10:0] lft_spd;			// 11-bit unsigned speed at which to run left motor
  output lft_rev;					// direction to run left motor (1==>reverse)
  output [10:0] rght_spd;			// 11-bit unsigned speed at which to run right motor
  output rght_rev;					// direction to run right motor (1==>reverse)
  output too_fast;

  ////////////////////////////////////
  // Define needed registers below //
  //////////////////////////////////
  	reg [17:0] full_integrator;
	reg [9:0] prev_ptch_err, intermediate;
  
  ///////////////////////////////////////////
  // Define needed internal signals below //
  /////////////////////////////////////////
	wire signed [9:0] ptch_err_sat, ptch_D_diff;
	wire signed [14:0] ptch_P_term;
	wire signed [17:0] next_integrator;
	wire ov, lft_torque_sel, rght_torque_sel;
	wire signed [11:0] integrator;
	wire signed [6:0] ptch_D_diff_sat;
	wire signed [12:0] ptch_D_term;

	wire signed [15:0] 	PID_cntrl,
				lft_torque, rght_torque,
				lft_torque_abs, rght_torque_abs,
				lft_torque_mult, rght_torque_mult,
				lft_torque_adjusted, rght_torque_adjusted,
				lft_shaped, rght_shaped,
				lft_speed_presat, rght_speed_presat;

  /////////////////////////////////////////////
  // local params for increased flexibility //
  ///////////////////////////////////////////
  localparam P_COEFF = 5'h0E;
  localparam D_COEFF = 6'h14;				// D coefficient in PID control = +20 
    
  localparam LOW_TORQUE_BAND = 8'h46;	// LOW_TORQUE_BAND = 5*P_COEFF
  localparam GAIN_MULTIPLIER = 6'h0F;	// GAIN_MULTIPLIER = 1 + (MIN_DUTY/LOW_TORQUE_BAND)
  localparam MIN_DUTY = 15'h03D4;		// minimum duty cycle (stiffen motor and get it ready)
  
  //// You fill in the rest ////
	
	assign ptch_err_sat = ptch[15] ? &ptch[14:9] ? ptch[9:0] : 10'h200 :
					|ptch[14:9] ? 10'h1FF : ptch[9:0];
	assign ptch_P_term = ptch_err_sat * ($signed(P_COEFF));

	assign next_integrator = {{8{ptch_err_sat[9]}}, ptch_err_sat} + full_integrator;

	assign ov = (ptch_err_sat[9] & full_integrator[17] & ~next_integrator[17]) |
		    (~ptch_err_sat[9] & ~full_integrator[17] & next_integrator[17]) ? 1'b1 : 1'b0;

	assign integrator = (fast_sim != 0) ? full_integrator[17:2] : full_integrator[17:6];

	always @(posedge clk, negedge rst_n)
		if(!rst_n)
			full_integrator <= 18'h0;
		else if(rider_off)
			full_integrator <= 18'h0;
		else if(vld & ~ov)
			full_integrator <= next_integrator;
			
	always @(posedge clk, negedge rst_n)
		if(!rst_n) begin
			prev_ptch_err <= 10'h0;
			intermediate <= 10'h0;
		end
		else if(vld) begin
			prev_ptch_err <= intermediate;
			intermediate <= ptch_err_sat;
		end
 
 	assign ptch_D_diff = ptch_err_sat - prev_ptch_err;

	assign ptch_D_diff_sat = ptch_D_diff[9] ? &ptch_D_diff[8:6] ? ptch_D_diff[6:0] : 7'h40 :
					|ptch_D_diff[8:6] ? 10'h3F : ptch_D_diff[6:0];
	assign ptch_D_term = ptch_D_diff_sat * ($signed(D_COEFF));


	assign PID_cntrl = {ptch_P_term[14], ptch_P_term} + {{4{integrator[11]}}, integrator} + {{3{ptch_D_term[12]}}, ptch_D_term};

	assign lft_torque = en_steer ? PID_cntrl - {{7{ld_cell_diff[11]}}, ld_cell_diff[11:3]} : PID_cntrl;
	assign rght_torque = en_steer ? PID_cntrl + {{7{ld_cell_diff[11]}}, ld_cell_diff[11:3]} : PID_cntrl;
	

	assign lft_torque_mult = lft_torque * ($signed(GAIN_MULTIPLIER));
	assign rght_torque_mult = rght_torque * ($signed(GAIN_MULTIPLIER));

	assign lft_torque_adjusted = lft_torque[15] ? lft_torque - MIN_DUTY : lft_torque + MIN_DUTY;
	assign rght_torque_adjusted = rght_torque[15] ? rght_torque - MIN_DUTY : rght_torque + MIN_DUTY;

	assign lft_torque_abs = lft_torque[15] ? (~lft_torque + 1) : lft_torque;
	assign rght_torque_abs = rght_torque[15] ? (~rght_torque + 1) : rght_torque;

	assign lft_torque_sel = lft_torque_abs >= LOW_TORQUE_BAND;
	assign rght_torque_sel = rght_torque_abs >= LOW_TORQUE_BAND;

	assign lft_shaped = lft_torque_sel ? lft_torque_adjusted : lft_torque_mult;
	assign rght_shaped = rght_torque_sel ? rght_torque_adjusted : rght_torque_mult;

	assign lft_rev = lft_shaped[15];
	assign rght_rev = rght_shaped[15];

	assign lft_speed_presat = lft_rev ? (~lft_shaped + 1) : lft_shaped;
	assign rght_speed_presat = rght_rev ? (~rght_shaped + 1) : rght_shaped;


	assign lft_spd = pwr_up ? 
				|lft_speed_presat[15:11] ? 11'h7FF : lft_speed_presat[10:0]
			 : 11'h0;

	assign rght_spd = pwr_up ? 
				|rght_speed_presat[15:11] ? 11'h7FF : rght_speed_presat[10:0]
			  : 11'h0;

	assign too_fast = (lft_spd > 11'h600) || (rght_spd > 11'h600);


endmodule 
