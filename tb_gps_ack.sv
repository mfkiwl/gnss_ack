module tb;

integer fd;
integer num;
integer rnum;
logic [7:0] tmp;

logic clk;
logic rst;

logic ack_start;
logic adc_clk;
logic [1:0] i_sample;
logic [1:0] q_sample;
logic [1:0] _i_sample;
logic [1:0] _q_sample;

logic i;
logic q;

logic [4:0] sat0;
logic [11:0] integrator_0;

gps_ack uut
(
    .clk(clk),
    .rst(rst),
    .ack_start(ack_start),
    .adc_clk(adc_clk),
    .i_sample(i),
    .q_sample(q),
    .sat0(sat0),
    .integrator_0(integrator_0)
);

initial
begin
$dumpfile("test.vcd");
$dumpvars(2, tb);
$dumpalle;
$dumpon;

fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");
num = 0;
while($feof(fd) == 0)
begin
    rnum = $fread(tmp, fd);
    {_q_sample, _i_sample, q_sample, i_sample} = tmp[3:0];
    num = num + 1;
end
$display("%d: %b", num, tmp[3:0]);

end

endmodule


