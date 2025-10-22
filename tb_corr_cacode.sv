module tb;

logic clk;
logic rst;


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
    input [10:1] g1;
    input [10:1] g2;
    input [3:0] t1;
    input [3:0] t2;

    cacode = g1[10] ^ g2[t1] ^ g2[t2];
endfunction

function corr;
    input [7:0] sat_taps;
    input [9:0] g1;
    input [9:0] g2;
    input x;

    corr = x ^ cacode(g1, g2, sat_taps[7:4], sat_taps[3:0]);
endfunction

always #10 clk = ~clk;

logic [9:0] w_g1;
logic [9:0] w_g2;

logic [10:1] g1;
logic [10:1] g2;

logic [9:0] code_phase;

logic [1022:0] ca_code;
logic [11:0] integrator;

logic [7:0] taps;

assign taps = tap(6'd31);

code_phase_to_lfsr lfsr
(
    .clk(clk),
    .rst(rst),
    .phase(code_phase),
    .g1(w_g1),
    .g2(w_g2)
);

task update_cacode;
    g1[10:1] <= {g1[9:1], g1[3] ^ g1[10]};
    g2[10:1] <= {g2[9:1], g2[2] ^ g2[3] ^ g2[6] ^ g2[8] ^ g2[9] ^ g2[10]};
endtask

integer lc;
integer lc2;

initial
begin
    $dumpfile("test.vcd");
    $dumpvars(2, tb);
    $dumpall;
    $dumpon;

    clk = 1'b0; rst = 1'b1;
    code_phase = 10'd123;
    ca_code = 1023'b0;
    #30;
    rst = 1'b0;
    #30;
	rst = 1'b1;
    @(posedge clk);
    @(posedge clk);
    g1 = w_g1;
    g2 = w_g2;
    for (lc = 0; lc < 1023; lc++)
    begin
        ca_code[lc] = cacode(g1, g2, taps[7:4], taps[3:0]);
        update_cacode();
        @(posedge clk);
    end

    @(posedge clk);
    @(posedge clk);
    g1 = w_g1;
    g2 = w_g2;

	for (lc2 = 0; lc2 < 1023; lc2++)
	begin
		integrator = 12'b0;
		code_phase = lc2;
		@(posedge clk);
		@(posedge clk);
		g1 = w_g1;
		g2 = w_g2;
		@(posedge clk);
		for (lc = 0; lc < 1023; lc++)
		begin
			integrator = integrator + corr(taps, g1, g2, ca_code[lc]);
			update_cacode();
			@(posedge clk);
		end
		$display("%d, ", code_phase, integrator);
	end


    $finish;
end

endmodule
