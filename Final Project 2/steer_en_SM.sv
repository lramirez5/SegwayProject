//Lucas Wysiatko
module steer_en_SM(clk, rst_n, lft_load, rght_load, tmr_full, en_steer, rider_off, clr_tmr, load_cell_diff);


//  parameter fast_sim = 1'b0;	// don't wait for the entire timer when this is a 1

  input clk;				// 50MHz clock
  input rst_n;				// Active low asynch reset
  input [11:0] lft_load, rght_load;     // come from A2D_intf used to calculate sum_gt_min, sum_lt_min, diff_gt_1_4, and diff_gt_15_16
  input tmr_full;			// asserted when timer reaches 1.3 sec


  /////////////////////////////////////////////////////////////////////////////
  // HEY BUDDY...you are a moron.  sum_gt_min would simply be ~sum_lt_min. Why
  // have both signals coming to this unit??  ANSWER: What if we had a rider
  // (a child) who's weigth was right at the threshold of MIN_RIDER_WEIGHT?
  // We would enable steering and then disable steering then enable it again,
  // ...  We would make that child crash(children are light and flexible and 
  // resilient so we don't care about them, but it might damage our Segway).
  // We can solve this issue by adding hysteresis.  So sum_gt_min is asserted
  // when the sum of the load cells exceeds MIN_RIDER_WEIGHT + HYSTERESIS and
  // sum_lt_min is asserted when the sum of the load cells is less than
  // MIN_RIDER_WEIGHT - HYSTERESIS.  Now we have noise rejection for a rider
  // who's wieght is right at the threshold.  This hysteresis trick is as old
  // as the hills, but very handy...remember it.
  //////////////////////////////////////////////////////////////////////////// 

  output reg en_steer;	// enables steering (goes to balance_cntrl)
  output reg rider_off;	// pulses high for one clock on transition back to initial state

//  wire tmr_full;	// asserted when timer reaches 1.3 sec
  output reg clr_tmr;		// clears the 1.3sec timer

//  Piezo_Timer #(fast_sim) tmr(.clk(clk), .rst_n(rst_n), .reset(clr_tmr), .steer_en_tmr_full(tmr_full), .cnt());
  
  // You fill out the rest...use good SM coding practices ///
  typedef enum reg [1:0] {IDLE, WAIT, STEER} state_t;
  state_t state, nxt_state;

  localparam MIN_RIDER_WEIGHT = 12'h200;
  localparam HYSTERESIS = 12'h020;

  //these are calculated from lft_load and rght_load
  logic sum_gt_min;			// asserted when left and right load cells together exceed min rider weight
  logic sum_lt_min;			// asserted when left_and right load cells are less than min_rider_weight
  logic diff_gt_1_4;			// asserted if load cell difference exceeds 1/4 sum (rider not situated)
  logic diff_gt_15_16;			// asserted if load cell difference is great (rider stepping off)
  logic [12:0] load_cell_sum;		// sum of left and right load cells
  logic signed [11:0] signed_load_cell_diff;
  output signed [11:0] load_cell_diff;   // difference between left and right load cells
  

  assign load_cell_sum = lft_load + rght_load;
  assign sum_gt_min = load_cell_sum > (MIN_RIDER_WEIGHT + HYSTERESIS);
  assign sum_lt_min = load_cell_sum < (MIN_RIDER_WEIGHT - HYSTERESIS);
  assign load_cell_diff = $signed(lft_load - rght_load);
  //assign load_cell_diff = signed_load_cell_diff[11] ? (~signed_load_cell_diff + 1) : signed_load_cell_diff;
  assign diff_gt_1_4 = $unsigned(load_cell_diff) > (load_cell_sum>>2);
  assign diff_gt_15_16 = $unsigned(load_cell_diff) > ((load_cell_sum>>4) * 15);

  //flop for state machine
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;

  //logic for state machine
  always_comb begin
    //default outputs
    clr_tmr = 0;
    en_steer = 0;
    rider_off = 1; 
    nxt_state = IDLE;
    case(state)

    IDLE: if(sum_gt_min) begin
      clr_tmr = 1;
      rider_off = 0;
      nxt_state = WAIT;
    end

    WAIT: if(sum_lt_min) begin
      rider_off = 1;
      nxt_state = IDLE;
    end
    else if(diff_gt_1_4) begin
      clr_tmr = 1;
      nxt_state = WAIT;
      rider_off = 0;
    end
    else if(tmr_full) begin
      en_steer = 1;
      nxt_state = STEER;
      rider_off = 0;
    end
    else begin
      nxt_state = WAIT;
      rider_off = 0;
    end

    STEER: if(sum_lt_min) begin
      rider_off = 1;
      nxt_state = IDLE;
    end
    else if(diff_gt_15_16) begin
      clr_tmr = 1;
      nxt_state = WAIT;
      rider_off = 0;
    end
    else begin
      en_steer = 1;
      nxt_state = STEER;
      rider_off = 0;
    end

    default: nxt_state = IDLE;
    endcase
  end
  
endmodule

/*
module timer(clk, rst_n, clr_tmr, tmr_full);

parameter fast_sim = 1'b0;

input clk, rst_n, clr_tmr;
output tmr_full;

reg [25:0] count;

assign tmr_full = fast_sim ? &count[14:0] : &count;

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		count <= 26'h0000000;
	else if(clr_tmr)
		count <= 26'h0000000;
	else
		count <= count + 1;

endmodule
*/