module gps_ack
#(
	parameter SAMPLE_BITS = 12 // 4096サンプル
)
(
    input wire clk,
    input wire rst,
	input wire adc_clk,
    input wire i_sample,
	input wire q_sample
    // input wire [5:0] satelite,
    // input wire [9:0] chip_delay,
    // input wire [31:0] doppler,
    // output wire [15:0] integrator
);

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

	cacode = g1[10] ^ g2[t1] ^ g2[t1];
endfunction

function corr;
	input [7:0] tap;
	input [9:0] g1;
	input [9:0] g2;
	input x;
	input bb;

	corr = x ^ bb ^ cacode(g1, g2, tap[7:4], tap[3:0]);
endfunction



typedef enum logic [3:0]
{
	CORRECT_SAMPLE,
	ACQUISITION,
	DONE
} state_t;

state_t current_state, next_state;

always_ff @(posedge clk or negedge rst)
begin
	if (!rst) current_state <= CORRECT_SAMPLE;
	else current_state <= next_state;
end

logic [1:0] delay_ad_clk;
logic rise_ad_clk;
always_ff @(posedge clk or negedge rst)
begin
	if (!rst) delay_ad_clk <= 2'b0;
	else delay_ad_clk <= {delay_ad_clk[0], adc_clk};
end

assign rise_ad_clk = ~delay_ad_clk[1] & delay_ad_clk[0];

logic [1022:0] i;
logic [1022:0] q;
logic [9:0] acq_counter;
always_ff @(posedge clk or negedge rst)
begin
	if (!rst)
	begin
		i <= 1023'b0;
		q <= 1023'b0;
		acq_counter <= 10'b0;
	end
	else
	begin
		if (current_state == ACQUISITION)
		begin
			if (rise_ad_clk)
			begin
				i <= {i[1021:1], i_sample};
				q <= {i[1021:1], q_sample};
				acq_counter <= acq_counter + 1'b1;
			end
		end
		else if (current_state == DONE)
		begin
			i <= 1023'b0;
			q <= 1023'b0;
			acq_counter <= 10'b0;
		end
	end
end





endmodule
