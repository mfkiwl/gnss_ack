module tb;


logic clk;
logic rst;

always #10 clk = ~clk;

logic [9:0] i;
logic [9:0] q;

integer fd;
integer num;
integer rnum;
logic signed [7:0] tmp1;
logic signed [7:0] tmp2;


initial
begin
$dumpfile("test.vcd");
$dumpvars(2, tb);
$dumpall;
$dumpon;
num = 0;
clk = 1'b0;
clk = 1'b0;
fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");
repeat (20) @(posedge clk)
begin
    @(posedge clk);
    rnum = $fread(tmp1, fd);
    rnum = $fread(tmp2, fd);

	i[num] = tmp1[2];
	q[num] = tmp2[2];
	num = num + 1;
end
$finish;
end

endmodule

