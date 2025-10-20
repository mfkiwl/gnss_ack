module gps_ack
#(
    parameter SAMPLE_BITS = 12, // 4096サンプル
    parameter CODE_NCO_OMEGA = 131, // 4Msps
    parameter DOPPLER_STEP = 13, //
    parameter DOPPLER_INIT = 13, //
    parameter DOPPLER_NUM = 2
)
(
    input wire clk,
    input wire rst,
    input wire ack_start,
    input wire adc_clk,
    input wire i_sample,
    input wire q_sample,
    output logic corr_complete,
    output logic [9:0] code_phase,
    output logic signed [15:0] doppler_omega,
    output logic [5:0] sat0,
    output logic [5:0] sat1,
    output logic [5:0] sat2,
    output logic [5:0] sat3,
    output logic [11:0] integrator_0,
    output logic [11:0] integrator_1,
    output logic [11:0] integrator_2,
    output logic [11:0] integrator_3,
    output logic search_complete
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

    cacode = g1[10] ^ g2[t1] ^ g2[t2];
endfunction

function corr;
    input [7:0] sat_taps;
    input [9:0] g1;
    input [9:0] g2;
    input x;
    input bb;

    corr = x ^ bb ^ cacode(g1, g2, sat_taps[7:4], sat_taps[3:0]);
endfunction


typedef enum logic [3:0]
{
    HOLD,
    CORRECT_SAMPLE,
    ACQ_INIT,
    CORR,
    CORR_COMPLETE,
    ACQ_END,
    DOPPLER_SET,
    SAT_SET,
    DONE
} state_t;

state_t current_state, next_state;

always_ff @(posedge clk or negedge rst)
begin
    if (!rst) current_state <= HOLD;
    else current_state <= next_state;
end

always_comb
begin
    case (current_state)
    HOLD:
    begin
        if (ack_start) next_state = CORRECT_SAMPLE;
        else next_state = HOLD;
    end

    CORRECT_SAMPLE:
    begin
        if (acq_counter <= 4095)
        begin
            next_state = CORRECT_SAMPLE;
        end
        else
        begin
            next_state = ACQ_INIT;
        end
    end

    ACQ_INIT: next_state = CORR;

    CORR:
    begin
        if (integrator_counter < 4095) next_state = CORR;
        else next_state = CORR_COMPLETE;
    end

    CORR_COMPLETE: next_state = ACQ_END;

    ACQ_END:
    begin
        if (code_phase < 10'd1023) next_state = ACQ_INIT;
        else next_state = DOPPLER_SET;
    end

    DOPPLER_SET:
    begin
        if (doppler_counter < DOPPLER_NUM) next_state = ACQ_INIT;
        else next_state = SAT_SET;
    end

    SAT_SET:
    begin
        if (sat_counter < 3'd7) next_state = ACQ_INIT;
        else next_state = DONE;
    end
    DONE: next_state = HOLD;
    default: next_state = HOLD;
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
        acq_counter <= 13'b0;
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

// logic [9:0] code_phase;
logic [8:0] code_nco_phase;
logic car_code_nco;

logic [9:0] w_g1;
logic [9:0] w_g2;

logic [10:1] g1;
logic [10:1] g2;

code_phase_to_lfsr lfsr
(
    .clk(clk),
    .rst(rst),
    .phase(code_phase),
    .g1(w_g1),
    .g2(w_g2)
);

localparam LO_SIN = 4'b1100;
localparam LO_COS = 4'b0110;
logic signed [15:0] doppler_phase;
logic car_doppler_nco;
logic [7:0] doppler_counter;

logic lo_i;
logic lo_q;

logic [11:0] integrator_counter;
logic [2:0] sat_counter;

always_ff @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        integrator_counter <= 12'b0;
        integrator_0 <= 12'b0;
        integrator_1 <= 12'b0;
        integrator_2 <= 12'b0;
        integrator_3 <= 12'b0;
        sat0 <= 6'd1;
        sat1 <= 6'd2;
        sat2 <= 6'd3;
        sat3 <= 6'd4;
        g1 <= 10'b11_1111_1111;
        g2 <= 10'b11_1111_1111;
        code_phase <= 10'b0;
        code_nco_phase <= 9'b0;
        doppler_phase <= 16'b0;
        doppler_omega <= 16'b0;
        lo_i <= 1'b0;
        lo_q <= 1'b0;
        corr_complete <= 1'b0;
        search_complete <= 1'b0;
        sat_counter <= 3'd0;
        doppler_counter <= 8'b0;
    end
    else
    begin
        if (current_state == HOLD)
        begin
            integrator_counter <= 12'b0;
            integrator_0 <= 12'b0;
            integrator_1 <= 12'b0;
            integrator_2 <= 12'b0;
            integrator_3 <= 12'b0;
            sat0 <= 6'd1;
            sat1 <= 6'd2;
            sat2 <= 6'd3;
            sat3 <= 6'd4;
            g1 <= 10'b11_1111_1111;
            g2 <= 10'b11_1111_1111;
            code_phase <= 10'b0;
            code_nco_phase <= 9'b0;
            doppler_phase <= 16'b0;
            doppler_omega <= 16'b0;
            sat_counter <= 3'd0;
            corr_complete <= 1'b0;
            search_complete <= 1'b0;
            doppler_counter <= 8'b0;
        end

        else if (current_state == CORRECT_SAMPLE)
        begin
            integrator_counter <= 12'b0;
            integrator_0 <= 12'b0;
            integrator_1 <= 12'b0;
            integrator_2 <= 12'b0;
            integrator_3 <= 12'b0;
            sat0 <= 6'd1;
            sat1 <= 6'd2;
            sat2 <= 6'd3;
            sat3 <= 6'd4;
            g1 <= 10'b11_1111_1111;
            g2 <= 10'b11_1111_1111;
            code_phase <= 10'b0;
            code_nco_phase <= 9'b0;
            doppler_phase <= 16'b0;
            doppler_omega <= DOPPLER_INIT;
            sat_counter <= 3'd0;
            corr_complete <= 1'b0;
            search_complete <= 1'b0;
            doppler_counter <= 8'b0;
        end

        else if (current_state == ACQ_INIT)
        begin
            integrator_counter <= 12'b0;
            integrator_0 <= 12'b0;
            integrator_1 <= 12'b0;
            integrator_2 <= 12'b0;
            integrator_3 <= 12'b0;
            g1 <= w_g1;
            g2 <= w_g2;
            code_nco_phase <= 9'b0;
            doppler_phase <= 16'b0;
            corr_complete <= 1'b0;
            search_complete <= 1'b0;
        end

        else if (current_state == CORR)
        begin
            integrator_counter <= integrator_counter + 12'b1;
            integrator_0 <= integrator_0 + corr(tap(sat0), g1, g2, i[integrator_counter], lo_i);
            integrator_1 <= integrator_1 + corr(tap(sat1), g1, g2, i[integrator_counter], lo_i);
            integrator_2 <= integrator_2 + corr(tap(sat2), g1, g2, i[integrator_counter], lo_i);
            integrator_3 <= integrator_3 + corr(tap(sat3), g1, g2, i[integrator_counter], lo_i);

            {car_code_nco, code_nco_phase} = code_nco_phase + CODE_NCO_OMEGA;
            if (car_code_nco)
            begin
                g1[10:1] <= {g1[9:1], g1[3] ^ g1[10]};
                g2[10:1] <= {g2[9:1], g2[2] ^ g2[3] ^ g2[6] ^ g2[8] ^ g2[9] ^ g2[10]};
            end

            {car_doppler_nco, doppler_phase} = doppler_phase + doppler_omega;
            if (car_doppler_nco)
            begin
                lo_i <= LO_SIN[doppler_phase[15:14]];
                lo_q <= LO_COS[doppler_phase[15:14]];
            end
        end

        else if (current_state == CORR_COMPLETE)
        begin
            corr_complete <= 1'b1;
        end

        else if (current_state == ACQ_END)
        begin
            code_phase <= code_phase + 1'b1;
        end

        else if (current_state == DOPPLER_SET)
        begin
            code_phase <= 10'b0;
            doppler_phase <= 16'b0;
            doppler_omega <= doppler_omega + DOPPLER_STEP;
            doppler_counter <= doppler_counter + 1'b1;
        end

        else if (current_state == SAT_SET)
        begin
            sat_counter <= sat_counter + 1'b1;
            sat0 <= sat0 + 6'd4;
            sat1 <= sat1 + 6'd4;
            sat2 <= sat2 + 6'd4;
            sat3 <= sat3 + 6'd4;
            doppler_counter <= 8'b0;
            doppler_omega <= DOPPLER_INIT;
        end
        else if (current_state == DONE)
        begin
            corr_complete <= 1'b0;
            search_complete <= 1'b1;
        end
    end
end

endmodule
