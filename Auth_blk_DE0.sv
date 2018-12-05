module Auth_blk_DE0(clk,RST_n,PB,auth,rider_off,LED);

  input clk;		// 50MHz clock
  input RST_n;		// raw push button input that forms reset
  input PB;			// from push button...initiates UART transmission
  input auth;		// from outer DIP switch, means we will send a 'g' on push of PB
  input rider_off;	// from inner DIP switch
  
  output [7:0] LED;	// LSB represents pwr_up, bits 7 and 6 to assist with debug

  wire pwr_up;		// output of DUT
  wire [7:0] tx_data;
  wire rst_n;		// global reset signal produced by rst_synch block
  
  //////////////////////////////////////////////////////////
  // Infer mux to select data to be sent to DUT via UART //
  ////////////////////////////////////////////////////////
  assign tx_data = (auth) ? 8'h67 : 8'h73;
  
  ////////////////////////////////////
  // Assign LED to assist in debug //
  //////////////////////////////////
  assign LED = {auth,rider_off,5'b00000,pwr_up};
  
  //////////////////////
  // Instantiate DUT //
  ////////////////////
  Auth_blk iDUT(.clk(clk),.rst_n(rst_n),.RX(RX),.rider_off(rider_off),.pwr_up(pwr_up));
		
  ///////////////////////////////////////////////
  // Instantiate Push Button release detector //
  /////////////////////////////////////////////
  PB_release iPB(.clk(clk),.rst_n(rst_n),.PB(PB),.released(trmt));
  
  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////
  rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));
	  
  //////////////////////////////
  // Instantiate Transmitter //
  ////////////////////////////
  UART_tx iTX(.clk(clk), .rst_n(rst_n), .TX(RX), .trmt(trmt), .tx_data(tx_data),
              .tx_done(tx_done));

endmodule
