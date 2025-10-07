module tb;

reg [400000:0] i_d0;
reg [400000:0] q_d0;
reg [400000:0] i_d1;
reg [400000:0] q_d1;
reg [7:0] tmp;

integer fd;
integer num;
integer rnum;

reg clk;
reg grst;
logic rst;
reg [9:0] init;
wire chip;

logic [9:0] g1;
logic [9:0] g2;
logic [9:0] phase;

always #10 clk = ~clk;

code_phase_to_lfsr pp
(
	.clk(clk),
	.rst(grst),
	.phase(phase),
	.g1(g1),
	.g2(g2)
);

CACODE uut (
    .rst(rst),
    .clk(clk),
    .g1_init(g1),
    .g2_init(g2),
    .T0(4'd2),
    .T1(4'd6),
    .chip(chip)
);


initial
begin
$dumpfile("test.vcd");
$dumpvars(2, tb);
$dumpall;
$dumpon;
/*
fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");
num = 0;
	while($feof(fd) == 0)
	begin
		rnum = $fread(tmp, fd);
		{q_d1[num], q_d0[num], i_d1[num], i_d0[num]} = tmp[3:0];
		num = num + 1;
	end
$display("%d: %b", num, tmp[3:0]);
*/

clk = 1'b0;
rst = 1'b1;
grst = 1'b0;
phase = 10'd0;
#13;
rst = 1'b0;
#22;
rst = 1'b1;

grst = 1'b1;

repeat (10) @(posedge clk);

rst = 1'b0;
phase = 10'd1;
#57;
rst = 1'b1;
repeat (10) @(posedge clk);




$finish;
end

integer i;
initial
begin
	i = 0;
	#35;
	repeat(1023) @(posedge clk)
	begin
		$display("%h", {uut.g1, uut.g2});
		i = i + 1;
	end
end

endmodule


