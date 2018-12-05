module SPI_mstr16(clk, rst_n, wrt, cmd, MISO, SS_n, SCLK, MOSI, done, rd_data);

input clk, rst_n, wrt, MISO;
input [15:0] cmd;

output reg SS_n, SCLK, MOSI, done;
output reg [15:0] rd_data;

enum {IDLE, FRONT, BACK, GO} state, nxt_state;

wire MISO_smpl, shft_nxt, smpl;
wire [3:0] bit_cnt;
reg SS_n_d, shft, en_SCLK, set_done, clr_done;

spi_counter_5bit sclk_count(.clk(clk), .rst_n(rst_n), .rst_cnt(SS_n), .en(en_SCLK), .SCLK(SCLK), .rise_next(smpl), .fall_next(shft_nxt));

spi_counter_4bit bit_count(.clk(clk), .rst_n(rst_n), .rst_bit_cnt(SS_n), .inc(shft & (state==GO)), .cnt(bit_cnt));

spi_shft_reg16 shiftreg(.clk(clk), .rst_n(rst_n), .wrt(wrt), .shft(shft), .cmd(cmd), .MISO_smpl(MISO_smpl), .MOSI(MOSI));

sample_MISO sample(.clk(clk), .rst_n(rst_n), .smpl(smpl), .MISO(MISO), .MISO_smpl(MISO_smpl));

sr_ff done_flop(.q(done), .s(set_done), .r(clr_done), .rst_n(rst_n), .clk(clk));

always @(posedge clk, negedge rst_n)
	if(!rst_n) begin
		state <= IDLE;
		SS_n <= 1;	// SS_n needs to be preset
	end else begin
		state <= nxt_state;
		SS_n <= SS_n_d;	// SS_n could glitch so it needs to be flopped
	end

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		rd_data <= 16'h0;
	else if(shft)
		rd_data <= {rd_data[14:0], MISO_smpl};

always_comb begin
	nxt_state = IDLE;
	SS_n_d = 1;
	shft = 0;
	en_SCLK = 0;
	set_done = 0;
	clr_done = 0;

	case(state)
	  IDLE :	// will wait for a command to be written
	    begin
		if(wrt) begin
			nxt_state = FRONT;
			SS_n_d = 0;
			en_SCLK = 1;
			clr_done = 1;
		end
	    end
	  FRONT :	// Front porch - wait for SCLK to fall but don't shift
	    begin
		if(shft_nxt) begin
			nxt_state = GO;
			SS_n_d = 0;
			en_SCLK = 1;
		end else begin
			nxt_state = FRONT;
			SS_n_d = 0;
			en_SCLK = 1;
		end
	    end
	  GO :		// Normal MOSI tranmission, MISO reception until 16 bits are sent/received
	    begin
		if(bit_cnt == 4'hF) begin
			nxt_state = BACK;
			SS_n_d = 0;
		end else begin
			nxt_state = GO;
			SS_n_d = 0;
			en_SCLK = 1;
			if(shft_nxt)
				shft = 1;
			else
				shft = 0;
		end
	    end
	  BACK :	// Back porch - Done sampling but need one last shift
	    begin
		if(shft_nxt) begin
			nxt_state = IDLE;
			shft = 1;
			SS_n_d = 1;
			set_done = 1;
		end else begin
			nxt_state = BACK;
			SS_n_d = 0;
			en_SCLK = 1;
		end
	    end
	  default : begin nxt_state = IDLE; end
	endcase
end

endmodule

module spi_counter_5bit(clk, rst_n, rst_cnt, en, SCLK, rise_next, fall_next);

input clk, rst_n, rst_cnt, en;
output SCLK, rise_next, fall_next;

reg [4:0] sclk_div;

assign SCLK = sclk_div[4];
assign rise_next = (sclk_div == 5'b01111);	// SCLK will rise on the next positive edge of clk
assign fall_next = (sclk_div == 5'b11111);	// SCLK will fall on the next positive edge of clk

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		sclk_div <= 5'h0;
	else if(rst_cnt)
		sclk_div <= 5'b10111;	// Set SCLK between the rising edge and the falling edge
	else if(en)
		sclk_div <= sclk_div + 1;

endmodule

module spi_counter_4bit(clk, rst_n, rst_bit_cnt, inc, cnt);

input clk, rst_n, inc, rst_bit_cnt;
output reg [3:0] cnt;	// Need to count 16 bits

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		cnt <= 0;
	else if(rst_bit_cnt)
		cnt <= 0;
	else if(inc)
		cnt <= cnt + 1;

endmodule

module spi_shft_reg16(clk, rst_n, wrt, shft, cmd, MISO_smpl, MOSI);

input clk, rst_n, wrt, shft, MISO_smpl;
input [15:0] cmd;

output MOSI;

reg [15:0] shft_reg;

assign MOSI = shft_reg[15];

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		shft_reg <= 16'h0;
	else if(wrt)
		shft_reg <= cmd;
	else if(shft)
		shft_reg <= {shft_reg[14:0], MISO_smpl};

endmodule

module sample_MISO(clk, rst_n, smpl, MISO, MISO_smpl);

input clk, rst_n, smpl, MISO;
output reg MISO_smpl;

always @(posedge clk, negedge rst_n)	// Flop input from slave so it can be shifted in synchronously
	if(!rst_n)
		MISO_smpl <= 0;
	else if(smpl)
		MISO_smpl <= MISO;

endmodule

module sr_ff(q, s, r, rst_n, clk);

input clk, s, r, rst_n;
output reg q;

always_ff @(posedge clk, negedge rst_n)
  if(!rst_n)
    q <= 0;
  else if(r)
    q <= 0;
  else if(s)
    q <= 1;

endmodule
