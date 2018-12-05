module A2D_intf(clk, rst_n, nxt, MISO, lft_ld, rght_ld, batt, a2d_SS_n, SCLK, MOSI);

input clk, rst_n, nxt;
// input from A2D
input MISO;

output [11:0] lft_ld, rght_ld, batt;
// outputs to A2D
output a2d_SS_n, SCLK, MOSI;

wire done, lft_en, rght_en, batt_en;
wire [15:0] rd_data;
wire [2:0] chnl;
wire [1:0] rnd_cnt;

reg wrt, update;
reg [15:0] cmd;

SPI_mstr16 SPI(.clk(clk), .rst_n(rst_n), .wrt(wrt), .cmd(cmd), .MISO(MISO), .SS_n(a2d_SS_n), .SCLK(SCLK), .MOSI(MOSI), .done(done), .rd_data(rd_data));

//ADC128S A2D(.clk(clk), .rst_n(rst_n), .SS_n(a2d_SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI));

round_counter rnd_counter(.clk(clk), .rst_n(rst_n), .update(update), .rnd_cnt(rnd_cnt));

assign lft_en = update && (rnd_cnt == 2'b00);
assign rght_en = update && (rnd_cnt == 2'b01);
assign batt_en = update && (rnd_cnt == 2'b10);

lft_ld_reg LFT(.clk(clk), .rst_n(rst_n), .en(lft_en), .lft_data_in(rd_data[11:0]), .lft_data_out(lft_ld));
rght_ld_reg RGHT(.clk(clk), .rst_n(rst_n), .en(rght_en), .rght_data_in(rd_data[11:0]), .rght_data_out(rght_ld));
batt_reg BATT(.clk(clk), .rst_n(rst_n), .en(batt_en), .batt_data_in(rd_data[11:0]), .batt_data_out(batt));

enum {IDLE, SEND_1ST, WAIT_1, SEND_2ND} state, nxt_state;

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;

// lft_ld read from channel 0
// rght_ld read from channel 4
// batt read from channel 5
assign chnl = (rnd_cnt == 2'b01) ? 3'h4 : (rnd_cnt == 2'b10) ? 3'h5 : 3'h0;
assign cmd = {2'b00, chnl, 11'h000};

always_comb begin
	nxt_state = IDLE;
	wrt = 0;
	update = 0;

	case(state)
	  IDLE : begin
		if(nxt) begin
			nxt_state = SEND_1ST;
			wrt = 1;
		end
	  end
	  SEND_1ST : begin
		if(done)
			nxt_state = WAIT_1;
		else
			nxt_state = SEND_1ST;
	  end
	  WAIT_1 : begin
		nxt_state = SEND_2ND;
		wrt = 1;
	  end
	  SEND_2ND : begin
		if(done) begin
			nxt_state = IDLE;
			update = 1;
		end
		else
			nxt_state = SEND_2ND;
	  end
	endcase

end

endmodule

module round_counter(clk, rst_n, update, rnd_cnt);

input clk, rst_n, update;
output reg [1:0] rnd_cnt;

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		rnd_cnt <= 2'b00;
	else if(update)
		if(rnd_cnt == 2'b10)
			rnd_cnt <= 2'b00;
		else
			rnd_cnt <= rnd_cnt + 1;

endmodule

module lft_ld_reg(clk, rst_n, en, lft_data_in, lft_data_out);

input clk, rst_n, en;
input [11:0] lft_data_in;
output reg [11:0] lft_data_out;

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		lft_data_out <= 0;
	else if(en)
		lft_data_out <= lft_data_in;

endmodule

module rght_ld_reg(clk, rst_n, en, rght_data_in, rght_data_out);

input clk, rst_n, en;
input [11:0] rght_data_in;
output reg [11:0] rght_data_out;

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		rght_data_out <= 0;
	else if(en)
		rght_data_out <= rght_data_in;

endmodule

module batt_reg(clk, rst_n, en, batt_data_in, batt_data_out);

input clk, rst_n, en;
input [11:0] batt_data_in;
output reg [11:0] batt_data_out;

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		batt_data_out <= 0;
	else if(en)
		batt_data_out <= batt_data_in;

endmodule
