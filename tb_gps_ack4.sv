module tb_gps_ack4;


logic clk;
logic rst;

logic ack_start;
logic adc_clk;

logic i;
logic q;

logic [5:0] sat0;
logic [15:0] integrator_0;
logic corr_complete;
logic search_complete;
logic [9:0] code_phase;
logic signed [15:0] doppler_omega;

gps_ack2
#(
    .SAMPLE_NUM(4095),
    .CODE_NCO_OMEGA(67043), // 131 4Msps
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
    .doppler_omega(doppler_omega),
    .corr_complete(corr_complete),
    .sat0(sat0),
    .integrator_0(integrator_0),
    .search_complete(search_complete)
);

always #10 clk = ~clk;
always #100 adc_clk = ~adc_clk;

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
    adc_clk = 1'b0;
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
	//@(posedge corr_complete);
	//@(posedge corr_complete);
    //repeat (40000) @(posedge adc_clk);

    $finish;
end

integer fd;
//integer num;
integer rnum;
//integer k;
logic [7:0] tmp1;
logic [7:0] tmp2;

initial
begin
    fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");

    repeat (65536) @(posedge adc_clk)
    begin
        rnum = $fread(tmp1, fd);
        rnum = $fread(tmp2, fd);

        i = tmp1[2];
        q = tmp2[2];
    end
end

integer fd2;
integer rnum2;
initial
begin
    fd2 = $fopen("./corr3.dat", "w");
    forever @(posedge corr_complete)
    begin
        $display("%d, %d, %d, %d", sat0, code_phase, doppler_omega, integrator_0);
        $fwrite(fd2, "%d, %d, %d, %d\n", sat0, code_phase, doppler_omega, integrator_0);
    end
end

endmodule


