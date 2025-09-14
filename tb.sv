module tb;

reg [400000:0] i_d0;
reg [400000:0] q_d0;
reg [400000:0] i_d1;
reg [400000:0] q_d1;
reg [7:0] tmp;

integer fd;
integer num;
integer rnum;

initial
begin
fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");
num = 0;
	while($feof(fd) == 0)
	begin
		rnum = $fread(tmp, fd);
		{q_d1[num], q_d0[num], i_d1[num], i_d0[num]} = tmp[3:0];
		num = num + 1;
	end
$display("%d: %b", num, tmp[3:0]);
$finish;
end

endmodule


