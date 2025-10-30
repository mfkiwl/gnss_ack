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
logic [5:0] sat4;
logic [5:0] sat5;
logic [5:0] sat6;
logic [5:0] sat7;
logic [13:0] integrator_i0;
logic [13:0] integrator_q0;
logic [13:0] integrator_i1;
logic [13:0] integrator_q1;
logic [13:0] integrator_i2;
logic [13:0] integrator_q2;
logic [13:0] integrator_i3;
logic [13:0] integrator_q3;
logic [13:0] integrator_i4;
logic [13:0] integrator_q4;
logic [13:0] integrator_i5;
logic [13:0] integrator_q5;
logic [13:0] integrator_i6;
logic [13:0] integrator_q6;
logic [13:0] integrator_i7;
logic [13:0] integrator_q7;
logic corr_complete;
logic search_complete;
logic [9:0] code_phase;
logic [4:0] code_nco_frac;
logic signed [15:0] doppler_omega;

gps_ack2
#(
    .SAMPLE_NUM(4095),
    .CODE_NCO_OMEGA(67072), // 131 4Msps
    .DOPPLER_STEP(4),
    .DOPPLER_INIT(-16'sd80),
    .DOPPLER_NUM(40)
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
    .sat1(sat1),
    .sat2(sat2),
    .sat3(sat3),
    .sat4(sat4),
    .sat5(sat5),
    .sat6(sat6),
    .sat7(sat7),
    .integrator_i0(integrator_i0),
    .integrator_q0(integrator_q0),
    .integrator_i1(integrator_i1),
    .integrator_q1(integrator_q1),
    .integrator_i2(integrator_i2),
    .integrator_q2(integrator_q2),
    .integrator_i3(integrator_i3),
    .integrator_q3(integrator_q3),
    .integrator_i4(integrator_i4),
    .integrator_q4(integrator_q4),
    .integrator_i5(integrator_i5),
    .integrator_q5(integrator_q5),
    .integrator_i6(integrator_i6),
    .integrator_q6(integrator_q6),
    .integrator_i7(integrator_i7),
    .integrator_q7(integrator_q7),
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
integer k;
logic [7:0] tmp1;
logic [7:0] tmp2;

initial
begin

clk = 1'b0;

fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");

repeat (65536) @(posedge clk)
begin
    adc_clk = 1'b0;
    @(posedge clk);
    rnum = $fread(tmp1, fd);
    rnum = $fread(tmp2, fd);

    i = tmp1[2];
    q = tmp2[2];
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
        $display("%d, %d, %d, %d, %d, %d", sat1, code_phase, code_nco_frac, doppler_omega, integrator_i1, integrator_q1);
        $display("%d, %d, %d, %d, %d, %d", sat2, code_phase, code_nco_frac, doppler_omega, integrator_i2, integrator_q2);
        $display("%d, %d, %d, %d, %d, %d", sat3, code_phase, code_nco_frac, doppler_omega, integrator_i3, integrator_q3);
        $display("%d, %d, %d, %d, %d, %d", sat4, code_phase, code_nco_frac, doppler_omega, integrator_i4, integrator_q4);
        $display("%d, %d, %d, %d, %d, %d", sat5, code_phase, code_nco_frac, doppler_omega, integrator_i5, integrator_q5);
        $display("%d, %d, %d, %d, %d, %d", sat6, code_phase, code_nco_frac, doppler_omega, integrator_i6, integrator_q6);
        $display("%d, %d, %d, %d, %d, %d", sat7, code_phase, code_nco_frac, doppler_omega, integrator_i7, integrator_q7);
        $fwrite(fd2, "%d, %d, %d, %d, %d, %d\n", sat0, code_phase, code_nco_frac, doppler_omega, integrator_i0, integrator_q0);
        $fwrite(fd2, "%d, %d, %d, %d, %d, %d\n", sat1, code_phase, code_nco_frac, doppler_omega, integrator_i1, integrator_q1);
        $fwrite(fd2, "%d, %d, %d, %d, %d, %d\n", sat2, code_phase, code_nco_frac, doppler_omega, integrator_i2, integrator_q2);
        $fwrite(fd2, "%d, %d, %d, %d, %d, %d\n", sat3, code_phase, code_nco_frac, doppler_omega, integrator_i3, integrator_q3);
        $fwrite(fd2, "%d, %d, %d, %d, %d, %d\n", sat4, code_phase, code_nco_frac, doppler_omega, integrator_i4, integrator_q4);
        $fwrite(fd2, "%d, %d, %d, %d, %d, %d\n", sat5, code_phase, code_nco_frac, doppler_omega, integrator_i5, integrator_q5);
        $fwrite(fd2, "%d, %d, %d, %d, %d, %d\n", sat6, code_phase, code_nco_frac, doppler_omega, integrator_i6, integrator_q6);
        $fwrite(fd2, "%d, %d, %d, %d, %d, %d\n", sat7, code_phase, code_nco_frac, doppler_omega, integrator_i7, integrator_q7);
    end
end

endmodule


