module ADC128S(clk,rst_n,SS_n,SCLK,MISO,MOSI, lft_ld, rght_ld, batt);
  //////////////////////////////////////////////////|
  // Model of a National Semi Conductor ADC128S    ||
  // 12-bit A2D converter.  NOTE: this model       ||
  // is used in the "Segway" project and gives a   ||
  // warning for any channels other than 0,4,5.    ||
  // The first two readings will return 0xC00, the ||
  // next two will return 0xBF0, next two after    ||
  //  that return 0xBE...                          ||
  ///////////////////////////////////////////////////

  input clk,rst_n;		// clock and active low asynch reset
  input SS_n;			// active low slave select
  input SCLK;			// Serial clock
  input MOSI;			// serial data in from master
  
  output MISO;			// serial data out to master
  
  wire [15:0] A2D_data,cmd;
  wire rdy_rise;

  input unsigned [11:0] lft_ld, rght_ld, batt;
//  reg lft_cnt_dir, rght_cnt_dir;

  wire lft_rd_en, rght_rd_en, batt_rd_en;

	
  typedef enum reg {FIRST,SECOND} state_t;
  
  state_t state,nxt_state;
  
  ///////////////////////////////////////////////
  // Registers needed in design declared next //
  /////////////////////////////////////////////
  reg rdy_ff;				// used for edge detection on rdy
  reg [2:0] channel;		// pointer to last channel specified for A2D conversion to be performed on.
//  reg [11:0] value, lft_value, rght_value, batt_value;
  
  /////////////////////////////////////////////
  // SM outputs declared as type logic next //
  ///////////////////////////////////////////
  logic update_ch,change_value;

  ////////////////////////////////
  // Instantiate SPI interface //
  //////////////////////////////
  SPI_ADC128S iSPI(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                 .MOSI(MOSI),.A2D_data(A2D_data),.cmd(cmd),.rdy(rdy));

	  
  //// channel pointer ////	  
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  channel <= 3'b000;
	else if (update_ch) begin
	  channel <= cmd[13:11];
	  if ((channel!=3'b000) && (channel!=3'b100) && (channel!=3'b101))
	    $display("WARNING: Only channels 0,4,5 of A2D valid for this version of ADC128S\n");
	end
/*
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  value <= 12'hC00;
	else if (change_value)
	//  if(lft_rd_en)
	//    value <= lft_value;//value - 12'h010;
	//  else if(rght_rd_en)
	//    value <= rght_value;
	//  else if(batt_rd_en)
	//    value <= batt_value;
	  value <= value - 12'h010;
*/
/*
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  lft_value <= 12'h000;
	else if (change_value)// & ~lft_rd_en)
	  lft_value <= lft_value + 12'h002;

  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  rght_value <= 12'h000;
	else if (change_value)// & ~rght_rd_en)
	  rght_value <= lft_value + 12'h005;

  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  batt_value <= 12'hFFF;
	else if (change_value)// & ~batt_rd_en)
	  batt_value <= batt_value - 12'h002;
	  */
  //// Infer state register next ////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  state <= FIRST;
	else
	  state <= nxt_state;
	  
  //// positive edge detection on rdy ////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	  rdy_ff <= 1'b0;
	else
	  rdy_ff <= rdy;
  assign rdy_rise = rdy & ~rdy_ff;
  

  //////////////////////////////////////
  // Implement state tranisiton logic //
  /////////////////////////////////////
  always_comb
    begin
      //////////////////////
      // Default outputs //
      ////////////////////
      update_ch = 0;
	  change_value = 0;
      nxt_state = FIRST;	  

      case (state)
        FIRST : begin
          if (rdy_rise) begin
		    update_ch = 1;
            nxt_state = SECOND;
          end
        end
		SECOND : begin		
		  if (rdy_rise) begin
		    change_value = 1;
			nxt_state = FIRST;
		  end else
		    nxt_state = SECOND;
		end
      endcase
    end

 
  assign lft_rd_en = (channel == 3'h0);
  assign rght_rd_en = (channel == 3'h4);
  assign batt_rd_en = (channel == 3'h5);
	
  assign A2D_data = 	(lft_rd_en) ? {4'b0000, lft_ld} :
			(rght_rd_en) ? {4'b0000, rght_ld} :
			(batt_rd_en) ? {4'b0000, batt} :
			16'h0001;
			//{4'b0000,value} | {13'h0000,channel};

/*
  always @(posedge clk, negedge rst_n)
	if(!rst_n)
		lft_cnt_dir <= 1;
	else if((lft_cnt_dir & (lft_ld > 12'h200)) | (~lft_cnt_dir & (lft_ld < 12'h00a)))
		lft_cnt_dir <= ~lft_cnt_dir;
	
  always @(posedge clk, negedge rst_n)
	if(!rst_n)
		lft_ld <= 12'h001;
	else if(lft_rd_en & rdy_rise & (state == SECOND))
	  if(lft_cnt_dir)
		lft_ld <= lft_ld + 2; // Can change the rate
	  else
		lft_ld <= lft_ld - 2; //

  
  always @(posedge clk, negedge rst_n)
	if(!rst_n)
		rght_cnt_dir <= 1;
	else if((rght_cnt_dir & (rght_ld > 12'h100)) | (~rght_cnt_dir & (rght_ld < 12'h00a)))
		rght_cnt_dir <= ~rght_cnt_dir;
	
  always @(posedge clk, negedge rst_n)
	if(!rst_n)
		rght_ld <= 12'h030;
	else if(rght_rd_en & rdy_rise & (state == SECOND))
	  if(rght_cnt_dir)
		rght_ld <= rght_ld + 5; //
	  else
		rght_ld <= rght_ld - 5; //


  always @(posedge clk, negedge rst_n)
	if(!rst_n)
		batt <= 12'hFFF;
	else if(batt_rd_en & rdy_rise & (state == SECOND))
           if(batt > 16'h7FF)
		batt <= batt - 2;
	   else
		batt <= {10'h000, ~batt[0]};

*/
endmodule  
  