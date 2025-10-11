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

logic [8:0] nco_omega;
logic set_reg;

always #10 clk = ~clk;

code_phase_to_lfsr pp
(
	.clk(clk),
	.rst(rst),
	.phase(phase),
	.g1(g1),
	.g2(g2)
);

cacode_arb_phi_omega cagen
(
	.clk(clk),
	.rst(rst),
	.g1(g1),
	.g2(g2),
	.set_reg(set_reg),
	.T0(4'd2),
	.T1(4'd6),
	.nco_omega(nco_omega),
	.chip(chip)
);


initial
begin
$dumpfile("test.vcd");
$dumpvars(4, tb);
$dumpall;
$dumpon;

clk = 1'b0;
rst = 1'b1;
nco_omega = 9'd131;
set_reg = 1'b0;
phase = 10'd0;
#13;
rst = 1'b0;
#22;
rst = 1'b1;


repeat (20) @(posedge clk);

phase = 10'd1;
@(posedge clk);
@(posedge clk) set_reg = 1'b1;
@(posedge clk) set_reg = 1'b0;

repeat (20) @(posedge clk);
phase = 10'd0;

@(posedge clk);
@(posedge clk) set_reg = 1'b1;
@(posedge clk) set_reg = 1'b0;

repeat (20) @(posedge clk);

$finish;
end

endmodule


