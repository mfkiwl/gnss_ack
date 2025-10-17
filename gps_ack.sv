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
    HOLD,
    CORRECT_SAMPLE,
    ACQ_INIT,
    CORR,
    ACQ_END,
    DONE
} state_t;

state_t current_state, next_state;

always_ff @(posedge clk or negedge rst)
begin
    if (!rst) current_state <= CORRECT_SAMPLE;
    else current_state <= next_state;
end

always_comb
begin
    case (current_state)
        HOLD:
        CORRECT_SAMPLE:
        begin
            if (acq_count_full == 4095)
            begin
                next_state = ACQ_INIT;
            end
            else
            begin
                next_state = acq_count_full;
            end
        end
        ACQ_INIT:
        CORR:
        ACQ_END:
        DONE:
        default: next_state = CORRECT_SAMPLE;
    endcase
end

logic [1:0] delay_ad_clk;
logic rise_ad_clk;
always_ff @(posedge clk or negedge rst)
begin
    if (!rst) delay_ad_clk <= 2'b0;
    else delay_ad_clk <= {delay_ad_clk[0], adc_clk};
end

assign rise_ad_clk = ~delay_ad_clk[1] & delay_ad_clk[0];

logic [4095:0] i;
logic [4095:0] q;
logic [12:0] acq_counter;
logic acq_count_full;
always_ff @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        i <= 4095'b0;
        q <= 4095'b0;
        acq_counter <= 12'b0;
    end
    else
    begin
        if (current_state == CORRECT_SAMPLE)
        begin
            if (rise_ad_clk)
            begin
                i[acq_counter] <= i_sample;
                q[acq_counter] <= q_sample;
                {acq_count_full, acq_counter} <= acq_counter + 1'b1;
            end
        end
        else if (current_state == DONE)
        begin
            acq_counter <= 12'b0;
        end
    end
end

code_phase_to_lfsr lfsr
(
    .clk(clk),
    .rst(rst),
    .phase(code_phase),
    .g1(w_g1),
    .g2(w_g2)
);

logic [9:0] code_phase;
logic [8:0] code_nco_phase;
logic [9:0] corr_counter;

logic [9:0] w_g1;
logic [9:0] w_g2;

logic [10:1] g1;
logic [10:1] g2;

logic [11:0] integrator_counter;
logic [11:0] integrator_0;
logic [11:0] integrator_1;
logic [11:0] integrator_2;
logic [11:0] integrator_3;
logic [11:0] integrator_4;
logic [11:0] integrator_5;
logic [11:0] integrator_6;
logic [11:0] integrator_7;
logic [11:0] integrator_8;
logic [11:0] integrator_9;

always_ff @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        integrator_counter <= 12'b0;
        integrator_0 <= 12'b0;
        integrator_1 <= 12'b0;
        g1 <= 10'b11_1111_1111;
        g2 <= 10'b11_1111_1111;
        code_phase <= 10'b0;
        code_nco_phase <= 9'b0;
    end
    else
    begin
        if (current_state == CORRECT_SAMPLE && current_state == DONE)
        begin
            integrator_counter <= 12'b0;
            integrator_0 <= 12'b0;
            integrator_1 <= 12'b0;
            g1 <= 10'b11_1111_1111;
            g2 <= 10'b11_1111_1111;
            code_phase <= 10'b0;
            code_nco_phase <= 9'b0;
        end
        else if (current_state == ACQ_INIT)
        begin
            g1 <= w_g1;
            g2 <= w_g2;
            code_phase <= code_phase + 1'b1;
        end
        else if (current_state == CORR)
        begin
            integrator_0 <= integrator_0 + corr(

            




end






endmodule
