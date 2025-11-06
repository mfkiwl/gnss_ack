module bsram_18k_36
(
    output logic [35:0] DO,
    input logic [35:0] DI,
    input logic [13:0] AD,
    input logic WRE,
    input logic CE,
    input logic CLK,
    input logic RESET
);

logic [35:0] ram [0:511];

always_ff @(posedge CLK)
begin
    if (WRE == 1'd1)
    begin
        ram[AD[13:5]] <= DI;
    end
    else
    begin
        DO <= ram[AD[13:5]];
    end
end

endmodule
