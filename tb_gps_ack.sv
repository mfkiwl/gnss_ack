module tb;


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

logic [5:0] sat0;
logic [5:0] sat1;
logic [5:0] sat2;
logic [5:0] sat3;
logic [11:0] integrator_0;
logic [11:0] integrator_1;
logic [11:0] integrator_2;
logic [11:0] integrator_3;
logic corr_complete;
logic search_complete;
logic [9:0] code_phase;
logic signed [15:0] doppler_omega;

gps_ack uut
(
    .clk(clk),
    .rst(rst),
    .ack_start(ack_start),
    .adc_clk(adc_clk),
    .i_sample(i),
    .q_sample(q),
    .code_phase(code_phase),
	.doppler_omega(doppler_omega),
    .corr_complete(corr_complete),
    .sat0(sat0),
    .sat1(sat1),
    .sat2(sat2),
    .sat3(sat3),
    .integrator_0(integrator_0),
    .integrator_1(integrator_1),
    .integrator_2(integrator_2),
    .integrator_3(integrator_3),
	.search_complete(search_complete)
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
ack_start = 1'b1;
#20;
ack_start = 1'b0;

//@(posedge search_complete);
repeat (20000000) @(posedge clk);

$finish;
end

integer fd;
integer num;
integer rnum;
logic [7:0] tmp;

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

integer fd2;
integer rnum2;
initial
begin
    fd2 = $fopen("./corr.dat", "w");
    forever @(posedge corr_complete)
    begin
        $display("%d, %d, %d, %d", sat0, code_phase, doppler_omega, integrator_0);
        $display("%d, %d, %d, %d", sat1, code_phase, doppler_omega, integrator_1);
        $display("%d, %d, %d, %d", sat2, code_phase, doppler_omega, integrator_2);
        $display("%d, %d, %d, %d", sat3, code_phase, doppler_omega, integrator_3);
        $fwrite(fd2, "%d, %d, %d, %d\n", sat0, code_phase, doppler_omega, integrator_0);
        $fwrite(fd2, "%d, %d, %d, %d\n", sat1, code_phase, doppler_omega, integrator_1);
        $fwrite(fd2, "%d, %d, %d, %d\n", sat2, code_phase, doppler_omega, integrator_2);
        $fwrite(fd2, "%d, %d, %d, %d\n", sat3, code_phase, doppler_omega, integrator_3);
    end
end

endmodule


