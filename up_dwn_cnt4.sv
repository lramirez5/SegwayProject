module up_dwn_clk4(en, dwn, clk, rst_n, cnt);

input en, dwn, clk, rst_n;
output reg [3:0] cnt;

wire [3:0] in;

assign in = en ? ( cnt + {{3{dwn}}, 1'b1} ) : cnt;

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		cnt = 4'h0;
	else
		cnt = in;

endmodule
