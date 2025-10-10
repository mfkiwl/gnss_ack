module cacode_arb_phi_omega
(
	input wire clk,
	input wire rst,
	input wire [9:0] g1,
	input wire [9:0] g2,
	input wire set_reg,
	input wire [4:1] T0,
	input wire [4:1] T1,
	input wire [7:0] nco_omega,
	output wire chip
);

logic [7:0] phase;
logic rd;

always_ff @(posedge clk or negedge rst)
begin
	if (!rst) phase <= 20'b0;
	else {rd, phase} <= phase + nco_omega;
end

CACODE uut (
    .rst(rst),
    .clk(clk),
	.rd(rd),
	.set_reg(set_reg),
    .g1_init(g1),
    .g2_init(g2),
    .T0(4'd2),
    .T1(4'd6),
    .chip(chip)
);

endmodule
