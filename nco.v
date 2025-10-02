module nco
(
	input wire clk,
	input wire rst,
	input wire [31:0] rate,
	output wire lo_q,
	output wire lo_i
);

reg [31:0] lo_phase;
localparam LO_SIN = 4'b1100;
localparam LO_COS = 4'b0110;

always @(posedge clk or negedge rst)
begin
	if (!rst) lo_phase <= 32'b0;
	else
	begin
		lo_phase <= lo_phase + rate;
	end
end

assign lo_i = LO_SIN[lo_phase[31:30]];
assign lo_q = LO_COS[lo_phase[31:30]];

endmodule

