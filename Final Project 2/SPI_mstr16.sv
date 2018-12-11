//Lucas Wysiatko
module SPI_mstr16(clk, rst_n, SS_n, SCLK, MOSI, MISO, wrt, cmd, done, rd_data);

  input clk, rst_n;
  input MISO;
  input wrt;
  input [15:0] cmd;
  output SCLK, MOSI;
  output reg done, SS_n;
  output [15:0] rd_data;

  reg [4:0] sclk_div;  //5-bit counter to determine SCLK
  reg [4:0] shft_cnt;  //5-bit counter to determine when done (aka shift 16 times)
  logic rst_cnt, shft, smpl, clr_done, set_done;  //SM outputs
  reg MISO_smpl;  //sampled at SCLK rise and becomes the LSB in shift reg
  reg [15:0] shift_reg;  //for shifting out commands MSB first while simultaneously receiving data

  typedef enum reg [1:0] {IDLE, FRNT_PRCH, TRANS, BCK_PRCH} state_t;  //define states as enumerated type
  state_t state, nxt_state;

  //create the 5-bit counter whose MSB is SCLK
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      sclk_div <= 5'b00000;
    else if(rst_cnt)
      sclk_div <= 5'b10111;
    else
      sclk_div <= sclk_div +1;

  assign SCLK = sclk_div[4];  //MSB is 1/32 of our system clk

  //counter to determine when we are done
  always_ff@(posedge clk)
    if(rst_cnt)
      shft_cnt <= 5'h00;
    else if(shft)
      shft_cnt <= shft_cnt + 1; 

  //flop for sampling MISO at rising edge of sclk
  always_ff@(posedge clk)
    if(smpl)
      MISO_smpl <= MISO;

  //shift register sending out cmd
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      shift_reg <= 16'h0000;
    else if(wrt)
      shift_reg <= cmd;
    else if(shft)
      shift_reg <= {shift_reg[14:0], MISO_smpl};

  assign MOSI = shift_reg[15];  //MSB sent to slave
  assign rd_data = shift_reg;  //rd_data will be the data in the shift reg when the transmission is done

  //have done come from a flop
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      done <= 1'b0;
    else if(clr_done)
      done <= 1'b0;
    else if(set_done)
      done <= 1'b1;

  //have SS_n come from a flop
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n) 
      SS_n <= 1'b1;
    else if(clr_done)
      SS_n <= 1'b0;
    else if(set_done)
      SS_n <= 1'b1;

  //flop for SM
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;

  //logic for SM
  always_comb begin
    //default outputs
    rst_cnt = 0;
    shft = 0;
    smpl = 0;
    clr_done = 0;
    set_done = 0;
    nxt_state = IDLE;

    case(state)
    
      IDLE: begin
        if(wrt) begin
	  clr_done = 1;
	  rst_cnt = 1;
	  nxt_state = FRNT_PRCH;
	end
      end

      FRNT_PRCH: begin
	if(sclk_div == 5'b00000) begin
	  nxt_state = TRANS;
	end
	else
	  nxt_state = FRNT_PRCH;
      end

      TRANS: begin
	if(shft_cnt == 5'b01111 && sclk_div == 5'b10000)  //done when we have shifted 15 times and sampled 16 times
	  nxt_state = BCK_PRCH;
	else if(sclk_div == 5'b01111) begin
	  smpl = 1;
	  nxt_state = TRANS;
	end
	else if(sclk_div == 5'b11111) begin
	  shft = 1;
	  nxt_state = TRANS;
	end
	else
	  nxt_state = TRANS;
      end

      BCK_PRCH: begin
	if(sclk_div == 5'b11111) begin  
	  shft = 1;  //perform the last shift
	  set_done = 1;
	  nxt_state = IDLE;
	end
	else
	  nxt_state = BCK_PRCH;
      end
    endcase
  end
    
endmodule
