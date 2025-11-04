module tb;

integer fd;
integer num;
integer rnum;

logic clk;
logic rst;
logic chip;

logic [9:0] g1;
logic [9:0] g2;
logic [9:0] phase;

always #10 clk = ~clk;

code_phase_to_lfsr pp
(
	.clk(clk),
	.rst(rst),
	.phase(phase),
	.g1(g1),
	.g2(g2)
);

initial
begin

clk = 1'b0;
rst = 1'b1;
phase = 10'd0;
#13;
rst = 1'b0;
#22;
rst = 1'b1;

$display("%h", {g1, g2});
phase = 10'd1022;

repeat (1022) @(posedge clk)
begin
	@(posedge clk);
	$display("%h", {g1, g2});
	phase = phase - 10'd1;
end
$finish;
end

endmodule


