//Lucas Wysiatko
module A2D_Intf(clk, rst_n, nxt, lft_ld, rght_ld, batt, SS_n, SCLK, MOSI, MISO);

  input clk, rst_n;
  input nxt;
  input MISO;
  output SCLK, MOSI;
  output reg SS_n;
  output reg [11:0] lft_ld, rght_ld, batt;
  logic wrt, update;  //SM outputs
  logic done;
  logic [15:0] cmd;
  logic [15:0] rd_data;
  reg [1:0] RRcounter;  //round robin counter to cycle between channels
  logic en_lft, en_rght, en_batt;  //enables for the 3 flops that can receive rd_data

  typedef enum reg [1:0] {IDLE, TRNS1, WAIT, TRNS2} state_t;

  state_t state, nxt_state;

  //instantiate SPI
  SPI_mstr16 iSPI(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO),
                  .wrt(wrt), .cmd(cmd), .done(done), .rd_data(rd_data));

  //Round Robin Counter
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      RRcounter <= 2'b00;
    else if(RRcounter == 2'b11)
      RRcounter <= 2'b00;
    else if(update)
      RRcounter <= RRcounter + 1;

  //left load flop
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      lft_ld <= 12'h000;
    else if(en_lft)
      lft_ld <= rd_data;

  //right load flop
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      rght_ld <= 12'h000;
    else if(en_rght)
      rght_ld <= rd_data;

  //battery flop
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      batt <= 12'h000;
    else if(en_batt)
      batt <= rd_data;

  //logic block to decide which enable is active
  always@(update) begin
    if(RRcounter == 2'b00 && update) begin
      en_lft = 1;
      en_rght = 0;
      en_batt = 0;
      cmd = {2'b00, 3'b100, 11'h000};
    end
    else if(RRcounter == 2'b01 && update) begin
      en_lft = 0;
      en_rght = 1;
      en_batt = 0;
      cmd = {2'b00, 3'b101, 11'h000};
    end
    else if(RRcounter == 2'b10 && update) begin
      en_lft = 0;
      en_rght = 0;
      en_batt = 1;
      cmd = {2'b00, 3'b000, 11'h000};
    end
    else begin
      en_lft = 0;
      en_rght = 0;
      en_batt = 0;
      cmd = 16'h0000;
    end
  end

  //SM flop
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;

  //SM logic
  always_comb begin
    //default outputs
    wrt = 0;
    update = 0;
    nxt_state = IDLE;

    case(state)

      IDLE: 
        if(nxt) begin
	  wrt = 1;
	  nxt_state = TRNS1;
	end

      TRNS1:
	if(done)
	  nxt_state = WAIT;
	else
	  nxt_state = TRNS1;

      WAIT:
      begin
	wrt = 1;
	nxt_state = TRNS2;
      end

      TRNS2:
	if(done)
	  update = 1;
	else
	  nxt_state = TRNS2;

      /*default:
      begin
	wrt = 0;
	update = 0;
	nxt_state = IDLE;
      end*/

    endcase
  end

endmodule
