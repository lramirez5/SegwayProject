module Auth_blk(clk, rst_n, RX, rider_off, pwr_up);

input clk, rst_n, RX, rider_off;

output reg pwr_up;

wire [7:0] rx_data;
wire rx_rdy, g, s;

reg clr_rx_rdy;

UART_rcv RCV(.clk(clk), .rst_n(rst_n), .RX(RX), .clr_rdy(clr_rx_rdy), .rx_data(rx_data), .rdy(rx_rdy));

enum bit [1:0] {OFF, PWR1, PWR2} state, nxt_state;

assign g = rx_rdy & (rx_data == 8'h67);
assign s = rx_rdy & (rx_data == 8'h73);

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= OFF;
	else
		state <= nxt_state;

always_comb begin
	nxt_state = OFF;
	pwr_up = 0;
	clr_rx_rdy = 0;

	case(state)
	  OFF : begin
		if(g) begin
			nxt_state = PWR1;
			pwr_up = 1;
			clr_rx_rdy = 1;
		end
	  end
	  PWR1 : begin
		if(!s) begin
			nxt_state = PWR1;
			pwr_up = 1;
			clr_rx_rdy = 0;
		end
		else if(s) begin
			nxt_state = PWR2;
			pwr_up = 1;
			clr_rx_rdy = 1;
		end
	  end
	  PWR2 : begin
		if(g) begin
			nxt_state = PWR1;
			pwr_up = 1;
			clr_rx_rdy = 1;
		end
		else if(!rider_off) begin
			nxt_state = PWR2;
			pwr_up = 1;
			clr_rx_rdy = 0;
		end 
		else if(rider_off) begin
			nxt_state = OFF;
			pwr_up = 0;
			clr_rx_rdy = 0;
		end

	  end
	endcase
end

endmodule
