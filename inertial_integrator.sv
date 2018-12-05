// Lorenzo Ramirez & George Akpan

module inertial_integrator(clk, rst_n, vld, ptch_rt, AZ, ptch);

input clk, rst_n, vld;
input signed [15:0] ptch_rt, AZ;

output reg [15:0] ptch;

localparam AZ_OFFSET = 16'hFE80;
localparam PTCH_RT_OFFSET = 16'h03C2;

reg [26:0] ptch_int;

wire signed [25:0] ptch_acc_product;
wire signed [15:0] ptch_acc, ptch_rt_comp, AZ_comp;
wire [26:0] fusion_ptch_offset;

/*
always @(posedge clk, negedge rst_n)
	if(!rst_n)
		ptch <= 0;
	else if(vld)
		ptch <= ptch_int[26:11];
*/
assign ptch = ptch_int[26:11];

always @(posedge clk, negedge rst_n)
	if(!rst_n)
		ptch_int <= 0;
	else if(vld)
		ptch_int <= ptch_int - {{11{ptch_rt_comp[15]}}, ptch_rt_comp} + fusion_ptch_offset;

assign AZ_comp = AZ - AZ_OFFSET;
assign ptch_rt_comp = ptch_rt - PTCH_RT_OFFSET;

assign ptch_acc_product = AZ_comp * $signed(327);
assign ptch_acc = {{3{ptch_acc_product[25]}}, ptch_acc_product[25:13]};

assign fusion_ptch_offset = ($signed(ptch_acc) > $signed(ptch)) ? 27'h0000400 : 27'h7FFFC00;


endmodule
