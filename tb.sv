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
reg rst;
reg [9:0] init;
wire chip;

always #10 clk = ~clk;

CACODE uut (
    .rst(rst),
    .clk(clk),
    .g2_init(1'b1),
    .init(init),
    .rd(1'b1),
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

init = {2'b0, 4'd2, 4'd6};
clk = 1'b0;
rst = 1'b0;
#10;
rst = 1'b1;
#10;
rst = 1'b0;
#20000;

$finish;
end

endmodule


