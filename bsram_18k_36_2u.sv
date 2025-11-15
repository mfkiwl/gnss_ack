module bsram_18k_36_2u
(
    output logic [35:0] DO,
    input logic [35:0] DI,
    input logic [9:0] AD,
    input logic WRE,
    input logic CE,
    input logic CLK,
    input logic RESET
);

logic [35:0] ram [0:1023];
//logic [35:0] ram;


always_ff @(posedge CLK)
begin
    if (WRE == 1'd1)
    begin
        ram[AD] <= DI;
    end
    else
    begin
        DO <= ram[AD];
    end
end

endmodule
