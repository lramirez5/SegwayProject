module saturate_tb();

reg [15:0] unsigned_err, signed_err;
reg [9:0] signed_D_diff;

wire [9:0] unsigned_err_sat, signed_err_sat;
wire [6:0] signed_D_diff_sat;

saturate iDUT(.unsigned_err(unsigned_err), .unsigned_err_sat(unsigned_err_sat),
		.signed_err(signed_err), .signed_err_sat(signed_err_sat),
		.signed_D_diff(signed_D_diff), .signed_D_diff_sat(signed_D_diff_sat));

initial begin
	unsigned_err = 16'h004C;	//No saturation
	signed_err = 16'hFF4C;		//No sat
	signed_D_diff = 10'h3F1;	//No sat
	#5;
	unsigned_err = 16'hFF4C;	//Saturation
	signed_err = 16'hDF4C;		//Sat
	signed_D_diff = 10'h241;	//Sat
	#5;
	signed_err = 16'h004C;		//No sat
	signed_D_diff = 10'h021;	//No sat
	#5;
	signed_err = 16'h3F4C;		//Sat
	signed_D_diff = 10'h1F1;	//Sat
	#5;
	$stop();
end

endmodule