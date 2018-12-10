module Piezo_Timer(clk, rst_n, reset, steer_en_tmr_full, cnt);

parameter fast_sim = 1'b0;


input clk, rst_n, reset;

output steer_en_tmr_full;
output reg [26:0] cnt;

assign steer_en_tmr_full = fast_sim ? &cnt[14:0] : &cnt[25:0];

always @(posedge clk, negedge rst_n)
	if(!rst_n) begin
		cnt <= 27'h0000000;
	end
	else if(reset) begin
		cnt <= 27'h0000000;
	end
	else
		cnt <= cnt + 1;

endmodule

