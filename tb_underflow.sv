module tb;

logic [3:0] dec;
logic carry;
logic signed [3:0] add;
logic signed [3:0] min;

initial
begin
$dumpfile("test.vcd");
$dumpvars(4, tb);
$dumpall;
$dumpon;

	add = 4'sd1;
	min = -4'sd3;

	dec = 4'b0;
	repeat (20)
	begin
		{carry, dec} = dec + add;
		#10;
	end
	#40;
	dec = 4'd15;
	repeat (20)
	begin
		{carry, dec} = dec + min;
		#10;
	end
end

endmodule
