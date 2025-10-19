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
logic corr_complete;
logic [9:0] code_phase;

gps_ack uut
(
    .clk(clk),
    .rst(rst),
    .ack_start(ack_start),
    .adc_clk(adc_clk),
    .i_sample(i),
    .q_sample(q),
	.code_phase(code_phase),
	.corr_complete(corr_complete),
    .sat0(sat0),
    .integrator_0(integrator_0)
);

always #10 clk = ~clk;

initial
begin
$dumpfile("test.vcd");
$dumpvars(2, tb);
$dumpall;
$dumpon;

#3;
rst = 1'b1;
clk = 1'b0;
ack_start = 1'b0;
#4
rst = 1'b0;
#20
rst = 1'b1;
#35;
sat0 = 5'b1;
ack_start = 1'b1;
#20;
ack_start = 1'b0;

repeat (5000000) @(posedge clk);
$finish;
end

initial
begin
fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");
repeat (8192) @(posedge clk)
begin
	adc_clk = 1'b0;
	@(posedge clk);
	rnum = $fread(tmp, fd);
	{_q_sample, _i_sample, q_sample, i_sample} = tmp[3:0];
	i = i_sample[1];
	q = q_sample[1];
	adc_clk= 1'b1;
end
end

initial
begin
	forever @(posedge corr_complete) $display("%d, %d", code_phase, integrator_0);
end




endmodule


