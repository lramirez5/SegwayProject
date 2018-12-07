module piezo(clk, rst_n, en_steer, ovr_spd, batt_low, piezo, piezo_n);

input clk, rst_n, en_steer, ovr_spd, batt_low;

output piezo, piezo_n;

wire wave;
wire [3:0] tmr;
wire [19:0] duty;
wire [20:0] max_cnt, en_steer_max_cnt, ovr_spd_max_cnt, batt_low_max_cnt;

PWM_piezo piezo_pwm(.clk(clk), .rst_n(rst_n), .max_cnt(max_cnt), .duty(duty), .PWM_sig(wave));

timer piezo_timer(.clk(clk), .rst_n(rst_n), .reset(~(en_steer | ovr_spd | batt_low)), .tmr(tmr));

assign en_steer_max_cnt = 21'h01E838;//21'h1156EC;
assign ovr_spd_max_cnt = 21'h00E400;
assign batt_low_max_cnt = 21'h03F800;//21'h030D40;

assign en_steer_en_duty = ~|tmr[3:1] && en_steer && !ovr_spd;
assign ovr_spd_en_duty = ~tmr[0] && ovr_spd;
assign batt_low_en_duty = tmr[3] && ~tmr[2]  && batt_low;//(tmr > 4'hA) && (tmr < 4'hE) && batt_low;

assign max_cnt = (ovr_spd_en_duty) ? ovr_spd_max_cnt :
		 (en_steer_en_duty) ? en_steer_max_cnt :
		 batt_low_max_cnt;

assign duty = (en_steer_en_duty | ovr_spd_en_duty | batt_low_en_duty) ? (max_cnt >> 1) : 20'h0;

assign piezo = |duty & wave;
assign piezo_n = |duty & ~piezo;

endmodule


module timer(clk, rst_n, reset, tmr);

input clk, rst_n, reset;

output reg [3:0] tmr;

reg [25:0] cnt;

wire en;

assign en = (cnt == 26'h0773594);//(cnt == 26'h3B9ACA0);

always @(posedge clk, negedge rst_n)
	if(!rst_n) begin
		cnt <= 26'b0;
		tmr <= 4'b0;
	end
	else if(reset) begin
		cnt <= 26'b0;
		tmr <= 4'b0;
	end
	else if(en) begin
		cnt <= 26'b0;
		tmr <= tmr + 1;
	end
	else
		cnt <= cnt + 1;
/*
always @(posedge clk, negedge rst_n)
	if(!rst_n)
		tmr <= 4'b0;
	else if(reset)
		tmr <= 
	else if(en)
		tmr <= tmr + 1;
*/
endmodule

