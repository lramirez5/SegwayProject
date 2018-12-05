//Lucas Wysiatko
module inert_intf(clk, rst_n, vld, ptch, SS_n, SCLK, MOSI, MISO, INT);

  input clk, rst_n;
  input INT;  //interrupt from inertial sensor new measurement is ready
  output vld;
  output [15:0] ptch;

  //registers for double flopping INT for meta-stability
  reg INT1, INT_stable;

  //holding registers
  reg [7:0] ptchL, ptchH, AZL, AZH;

  //SPI interface
  input MISO;
  output SS_n, SCLK, MOSI;

  reg [15:0] timer16;  //16 bit timer for initialization

  reg [15:0] ptch_rt, AZ;  //obtained by concatinating the reads in the holding registers

  typedef enum reg [3:0] {INIT1, INIT2, INIT3, INIT4, WAIT, RD1, RD2, RD3, RD4} state_t;  //define states as enumerated type
  state_t state, nxt_state;
  logic [15:0] cmd;
  logic [7:0] rd_data;
  logic wrt, done, vldSM, ptchL_en, ptchH_en, AZL_en, AZH_en;

  //instantiate SPI_mstr16
  SPI_mstr16 iSPI(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), 
                  .MISO(MISO), .wrt(wrt), .cmd(cmd), .done(done), .rd_data(rd_data));

  //instantiate inertial_integrator
  inertial_integrator iINT(.clk(clk), .rst_n(rst_n), .vld(vld), .ptch_rt(ptch_rt), .AZ(AZ), .ptch(ptch));

  //16-bit timer used in SM
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      timer16 <= 16'h0000;
    else
      timer16 <= timer16 + 1;  

  //meta-stabalize INT
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      INT1 <= 1'b0;
    else
      INT1 <= INT;
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      INT_stable <= 1'b0;
    else
      INT_stable <= INT1;

  //ptch_rt and AZ are formed when vld is asserted
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n) begin
      ptch_rt <= 16'h0000;
      AZ <= 16'h0000;
    end
    else if(vld) begin
      ptch_rt <= {ptchH, ptchL};
      AZ <= {AZH, AZL};
    end    

  //SM flop
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      state <= INIT1;
    else
      state <= nxt_state;

  //SM logic 
  always_comb begin
    //default outputs
    wrt = 0;
    vldSM = 0;
    cmd = 16'h0D02;
    ptchL_en = 0;
    ptchH_en = 0;
    AZL_en = 0;
    AZH_en = 0;
    nxt_state = INIT1;

    case(state)

      INIT1: begin
	cmd = 16'h0D02;
	if(&timer16) begin
	  wrt = 1;
	  nxt_state = INIT2;
	end
      end

      INIT2: begin
	cmd = 16'h1053;
	if(done) begin
	  wrt = 1;
	  nxt_state = INIT3;
	end
	else
	  nxt_state = INIT2;
      end

      INIT3: begin
	cmd = 16'h1150;
	if(done) begin
	  wrt = 1;
	  nxt_state = INIT4;
	end
	else
	  nxt_state = INIT3;
      end

      INIT4: begin
	cmd = 16'h1460;
	if(done) begin
	  wrt = 1;
	  nxt_state = WAIT;
	end
	else
	  nxt_state = INIT4;
      end

      WAIT: begin
	cmd = 16'hA2xx;
	if(done && INT_stable) begin
	  wrt = 1;
	  ptchL_en = 1;
	  nxt_state = RD1;
	end
	else
	  nxt_state = WAIT;
      end

      RD1: begin
	cmd = 16'hA3xx;
	if(done) begin
	  wrt = 1;
	  ptchH_en = 1;
	  nxt_state = RD2;
	end
	else
	  nxt_state = RD1;
      end

      RD2: begin
	cmd = 16'hACxx;
	if(done) begin
	  wrt = 1;
	  AZL_en = 1;
	  nxt_state = RD3;
	end
	else
	  nxt_state = RD2;
      end

      RD3: begin
	cmd = 16'hADxx;
	if(done) begin
	  wrt = 1;
	  AZH_en = 1;
	  nxt_state = RD4;
	end
	else
	  nxt_state = RD3;
      end

      RD4: begin
	if(done) begin
	  vldSM = 1;
	  nxt_state = WAIT;
	end
	else
	  nxt_state = RD4;
      end
    endcase
  end

  assign vld = vldSM;

  //holding registers
  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      ptchL <= 8'h00;
    else if(ptchL_en)
      ptchL <= rd_data;

  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      ptchH <= 8'h00;
    else if(ptchH_en)
      ptchH <= rd_data;

  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      AZL <= 8'h00;
    else if(AZL_en)
      AZL <= rd_data;

  always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
      AZH <= 8'h00;
    else if(AZH_en)
      AZH <= rd_data;

endmodule
