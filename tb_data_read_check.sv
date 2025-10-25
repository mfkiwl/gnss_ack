module tb;


logic clk;
logic rst;

always #10 clk = ~clk;

logic i;
logic q;

integer fd;
integer num;
integer rnum;
logic [7:0] tmp1;
logic [7:0] tmp2;


initial
begin
$dumpfile("test.vcd");
$dumpvars(2, tb);
$dumpall;
$dumpon;
clk = 1'b0;
clk = 1'b0;
fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");
repeat (8192) @(posedge clk)
begin
    @(posedge clk);
    rnum = $fread(tmp1, fd);
    rnum = $fread(tmp2, fd);

	i = tmp1[1];
	q = tmp2[1];
end
$finish;
end

endmodule

