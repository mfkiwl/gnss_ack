module tb;


reg clk;
reg rst;
reg [31:0] rate;
wire lo_i;
wire lo_q;

always #10 clk = ~clk;

nco uut
(
	.clk(clk),
	.rst(rst),
	.rate(rate),
	.lo_q(lo_q),
	.lo_i(lo_i)
);

initial
begin
	$dumpfile("test.vcd");
	$dumpvars(2, tb);
	$dumpall;
	$dumpon;

	clk = 1'b0;
	rate = 32'd20000000;
	rst = 1'b1;
	#10;
	rst = 1'b0;
	#100;
	rst = 1'b1;
	repeat (100000) #20;
	$finish;
end

endmodule
