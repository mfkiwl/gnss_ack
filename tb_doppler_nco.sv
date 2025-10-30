module tb;

logic clk;
logic rst;

always #10 clk = ~clk;


logic car_doppler_nco;
logic signed [9:0] doppler_phase;
logic signed [9:0] doppler_omega;
localparam LO_SIN = 4'b1100;
localparam LO_COS = 4'b0110;

logic lo_i;
logic lo_q;

always_ff @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        doppler_phase <= 10'b0;
        car_doppler_nco <= 1'b0;
    end
    else
    begin
        {car_doppler_nco, doppler_phase} <= doppler_phase + doppler_omega;
		lo_q <= LO_SIN[doppler_phase[9:8]];
		lo_i <= LO_COS[doppler_phase[9:8]];
    end
end

initial
begin
    $dumpfile("test.vcd");
    $dumpvars(2, tb);
    $dumpall;
    $dumpon;

    doppler_omega = 10-'sd255;
    clk = 1'b0;
	rst = 1'b0;
	#3;
	rst = 1'b1;

    repeat (200) @(posedge clk);
    $finish;
end

endmodule
