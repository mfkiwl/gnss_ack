module tb;

logic clk;
logic rst;

always #10 clk = ~clk;
always #100 adc_clk = ~adc_clk;

logic [9:0] i;
logic [9:0] q;

logic [35:0] dataout_i;
logic [35:0] datain_i;
logic [13:0] address;
logic write_enable;

bsram_18k_36 bbi
(
    .DO(dataout_i),
    .DI(datain_i),
    .AD(address),
    .WRE(write_enable),
    .CE(1'd0),
    .CLK(1'd0),
    .RESET(1'd0)
);

integer rnum;
integer fd;
integer num;
logic [7:0] tmp1;
logic [7:0] tmp2;

logic adc_clk;

initial
begin
$dumpfile("test.vcd");
$dumpvars(2, tb);
$dumpall;
$dumpon;
num = 0;
clk = 1'b0;
clk = 1'b0;
adc_clk = 1'b0;
fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");
repeat (20) @(negedge adc_clk)
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

