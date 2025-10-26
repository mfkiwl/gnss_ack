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
logic [11:0] integrator_i0;
logic [11:0] integrator_q0;
logic corr_complete;
logic search_complete;
logic [9:0] code_phase;
logic [4:0] code_nco_frac;
logic signed [15:0] doppler_omega;

gps_ack2
#(
    .CODE_NCO_OMEGA(67072), // 131 4Msps
	.DOPPLER_STEP(8),
	.DOPPLER_INIT(17),
	.DOPPLER_NUM(5)
)
uut
(
    .clk(clk),
    .rst(rst),
    .ack_start(ack_start),
    .adc_clk(adc_clk),
    .i_sample(i),
    .q_sample(q),
    .code_phase(code_phase),
	.code_nco_frac(code_nco_frac),
	.doppler_omega(doppler_omega),
    .corr_complete(corr_complete),
    .sat0(sat0),
    .integrator_i0(integrator_i0),
    .integrator_q0(integrator_q0),
	.search_complete(search_complete)
);

always #10 clk = ~clk;

initial
begin

/*
$dumpfile("test.vcd");
$dumpvars(2, tb);
$dumpall;
$dumpon;
*/


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

@(posedge search_complete);
//repeat (20000000) @(posedge clk);

$finish;
end

integer fd;
integer num;
integer rnum;
logic [7:0] tmp1;
logic [7:0] tmp2;

initial
begin
/*
$dumpfile("test.vcd");
$dumpvars(2, tb);
$dumpall;
$dumpon;
clk = 1'b0;
*/
fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");
repeat (8192) @(posedge clk)
begin
    adc_clk = 1'b0;
    @(posedge clk);
    rnum = $fread(tmp1, fd);
    rnum = $fread(tmp2, fd);

    i = tmp1[1];
    q = tmp2[1];
    adc_clk= 1'b1;
end
//$finish;
end

integer fd2;
integer rnum2;
initial
begin
    fd2 = $fopen("./corr2.dat", "w");
    forever @(posedge corr_complete)
    begin
        $display("%d, %d, %d, %d, %d, %d", sat0, code_phase, code_nco_frac, doppler_omega, integrator_i0, integrator_q0);
        $fwrite(fd2, "%d, %d, %d, %d, %d, %d\n", sat0, code_phase, code_nco_frac, doppler_omega, integrator_i0, integrator_q0);
    end
end

endmodule


