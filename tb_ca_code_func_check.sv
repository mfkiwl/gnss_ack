/*
module update_ca
(
    input wire [10:1] g1_ca,
    input wire [10:1] g2_ca,
    input wire [3:0] t1,
    input wire [3:0] t2,
    output logic ca
);


assign ca = g1_ca[10] ^ g2_ca[t1] ^ g2_ca[t2];

endmodule
*/

module tb;

function [7:0] tap;
    input [5:0] satelite;
    begin
        case(satelite)
            6'd1: tap = {4'd2, 4'd6};
            6'd2: tap = {4'd3, 4'd7};
            6'd3: tap = {4'd4, 4'd8};
            6'd4:  tap = {4'd5, 4'd9};
            6'd5:  tap = {4'd1, 4'd9};
            6'd6:  tap = {4'd2, 4'd10};
            6'd7:  tap = {4'd1, 4'd8};
            6'd8:  tap = {4'd2, 4'd9};
            6'd9:  tap = {4'd3, 4'd10};
            6'd10: tap = {4'd2, 4'd3};
            6'd11: tap = {4'd3, 4'd4};
            6'd12: tap = {4'd5, 4'd6};
            6'd13: tap = {4'd6, 4'd7};
            6'd14: tap = {4'd7, 4'd8};
            6'd15: tap = {4'd8, 4'd9};
            6'd16: tap = {4'd9, 4'd10};
            6'd17: tap = {4'd1, 4'd4};
            6'd18: tap = {4'd2, 4'd5};
            6'd19: tap = {4'd3, 4'd6};
            6'd20: tap = {4'd4, 4'd7};
            6'd21: tap = {4'd5, 4'd8};
            6'd22: tap = {4'd6, 4'd9};
            6'd23: tap = {4'd1, 4'd3};
            6'd24: tap = {4'd4, 4'd6};
            6'd25: tap = {4'd5, 4'd7};
            6'd26: tap = {4'd6, 4'd8};
            6'd27: tap = {4'd7, 4'd9};
            6'd28: tap = {4'd8, 4'd10};
            6'd29: tap = {4'd1, 4'd6};
            6'd30: tap = {4'd2, 4'd7};
            6'd31: tap = {4'd3, 4'd8};
            6'd32: tap = {4'd4, 4'd9};
            default: tap = {4'd0, 4'd0};
        endcase
    end
endfunction

function cacode;
    input [10:1] g1_ca;
    input [10:1] g2_ca;
    input [3:0] t1;
    input [3:0] t2;
    begin
        cacode = g1_ca[10] ^ g2_ca[t1] ^ g2_ca[t2];
    end
endfunction

logic [10:1] g1;
logic [10:1] g2;
logic [5:0] sat1;
logic [5:0] sat2;
logic chip1;
logic chip2;

logic clk;
always #10 clk = ~clk;

always @(posedge clk)
begin
    g1[10:1] <= {g1[9:1], g1[3] ^ g1[10]};
    g2[10:1] <= {g2[9:1], g2[2] ^ g2[3] ^ g2[6] ^ g2[8] ^ g2[9] ^ g2[10]};
end

logic [7:0] sat1_t;
logic [7:0] sat2_t;


always @(*)
begin
    sat1_t = tap(sat1);
    sat2_t = tap(sat2);
    chip1 = cacode(g1, g2, sat1_t[3:0], sat1_t[7:4]);
    chip2 = cacode(g1, g2, sat2_t[3:0], sat2_t[7:4]);
end

initial
begin
$dumpfile("test.vcd");
$dumpvars(4, tb);
$dumpall;
$dumpon;
g1 = 10'b11_1111_1111;
g2 = 10'b11_1111_1111;
sat1 = 6'd31;
sat2 = 6'd2;
clk = 1'b0;

repeat(20) @(posedge clk);
$finish();
end


endmodule
