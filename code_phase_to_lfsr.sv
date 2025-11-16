module code_phase_to_lfsr
(
	input wire clk,
	input wire rst,
	input wire [9:0] phase,
	output reg [9:0] g1,
	output reg [9:0] g2
);

logic [19:0] rom [0:1022];

initial
begin
	$readmemh("phase_table_rev.hex", rom);
end


always_ff @(posedge clk or negedge rst)
begin
	if (!rst)
	begin
		g1 <= 10'b11_1111_1111;
		g2 <= 10'b11_1111_1111;
	end
	else {g1, g2} <= rom[phase];
end


endmodule


