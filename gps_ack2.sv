module gps_ack2
#(
    parameter SAMPLE_NUM = 16384,
    parameter CODE_NCO_OMEGA = 67027, // 131 4Msps
    parameter bit [15:0] DOPPLER_STEP = 13, //
    parameter bit [15:0] DOPPLER_INIT = 16'(13), //
    parameter DOPPLER_NUM = 2
)
(
    input wire clk,
    input wire rst,
    input wire ack_start,
    input wire adc_clk,
    input wire i_sample,
    input wire q_sample,
    output logic [9:0] code_phase,
    output logic signed [15:0] doppler_omega,
    output logic [5:0] sat0,
    output logic [5:0] sat1,
    output logic [5:0] sat2,
    output logic [5:0] sat3,
    output logic [5:0] sat4,
    output logic [5:0] sat5,
    output logic [5:0] sat6,
    output logic [5:0] sat7,
    output logic [15:0] integrator_0,
    output logic [15:0] integrator_1,
    output logic [15:0] integrator_2,
    output logic [15:0] integrator_3,
    output logic [15:0] integrator_4,
    output logic [15:0] integrator_5,
    output logic [15:0] integrator_6,
    output logic [15:0] integrator_7,
    output logic corr_complete,
    output logic doppler_block_complete,
    output logic sat_block_complete,
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

function signed [11:0] corr;
    input [7:0] sat_taps;
    input [9:0] g1;
    input [9:0] g2;
    input x;
    logic tmp;

    tmp = (x ^ cacode(g1, g2, sat_taps[7:4], sat_taps[3:0]));
    if (tmp == 1'd0) corr = 12'sd1;
    else corr = -12'sd1;
endfunction

function [11:0] abs;
    input [11:0] x;
    abs = ((x >> 11) == 12'd1)? ((~x)+12'd1) : x;
endfunction

typedef enum logic [3:0]
{
    HOLD,
    CORRECT_SAMPLE,
    CODE_SET_WAIT,
    ACQ_INIT,
    DATA_BLOCK_READ_WAIT,
    CORR,
    INCOH_SET,
    CORR_COMPLETE,
    CODE_PHASE_SET,
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
        if (complete_correct == 1'd0)
        begin
            next_state = CORRECT_SAMPLE;
        end
        else
        begin
            next_state = CODE_SET_WAIT;
        end
    end

    CODE_SET_WAIT: next_state = ACQ_INIT;

    ACQ_INIT: next_state = DATA_BLOCK_READ_WAIT;

    DATA_BLOCK_READ_WAIT: next_state = CORR;

    CORR:
    begin
        if (corr_buf_counter == 6'd35 && corr_sample_counter < 12'd3999) next_state = DATA_BLOCK_READ_WAIT;
        else if (corr_sample_counter == 12'd3999) next_state = INCOH_SET;
        else next_state = CORR;
    end

    INCOH_SET:
    begin
        if (incoh_counter == 4'd8) next_state = CORR_COMPLETE;
        else next_state = DATA_BLOCK_READ_WAIT;
    end

    CORR_COMPLETE: next_state = CODE_PHASE_SET;

    CODE_PHASE_SET:
    begin
        if (code_phase < 10'd1022) next_state = CODE_SET_WAIT;
        else next_state = DOPPLER_SET;
    end

    DOPPLER_SET:
    begin
        if (doppler_counter < DOPPLER_NUM) next_state = CODE_SET_WAIT;
        else next_state = SAT_SET;
    end

    SAT_SET:
    begin
        if (sat_counter == 3'd3) next_state = DONE;
        else next_state = CODE_SET_WAIT;
    end
    DONE: next_state = HOLD;
    default: next_state = HOLD;
    endcase
end

// ADC クロックのシンクロナイザ
logic [1:0] delay_ad_clk;
always_ff @(posedge clk or negedge rst)
begin
    if (!rst) delay_ad_clk <= 2'b0;
    else delay_ad_clk <= {delay_ad_clk[0], adc_clk};
end

logic adc_clk_flag;
assign adc_clk_flag = ~delay_ad_clk[1] & delay_ad_clk[0];


// buf関係のレジスタ
logic [35:0] dataout_i;
logic [35:0] datain_i;
logic [35:0] dataout_q;
logic [35:0] datain_q;
logic [9:0] address;
logic write_enable_0;
logic [9:0] acq_address;
logic [9:0] corr_address;
assign address = (current_state == CORRECT_SAMPLE)? acq_address: corr_address;

logic [5:0] buf_count;
logic [11:0] sample_count;
logic [3:0] block_count;
logic flag_buf_count;
logic [1:0] flag_reg;
logic complete_correct;

bsram_18k_36_2u bbi
(
    .DO(dataout_i),
    .DI(datain_i),
    .AD(address),
    .WRE(write_enable_0),
    .CE(1'd0),
    .CLK(clk),
    .RESET(1'd0)
);

bsram_18k_36_2u bbq
(
    .DO(dataout_q),
    .DI(datain_q),
    .AD(address),
    .WRE(write_enable_0),
    .CE(1'd0),
    .CLK(clk),
    .RESET(1'd0)
);

/* バッファへのデータの取り込み */

always_ff @(posedge clk)
begin
    if (!rst)
    begin
        datain_i <= 36'd0;
        datain_q <= 36'd0;
        buf_count <= 6'd0;
        sample_count <= 12'd0;
        block_count <= 4'd0;
        flag_buf_count <= 1'd0;
    end
    else if (current_state == CORRECT_SAMPLE)
    begin
        if (adc_clk_flag)
        begin
            datain_i[buf_count] <= i_sample;
            datain_q[buf_count] <= q_sample;

            if (buf_count < 6'd35 && sample_count < 12'd3999)
            begin
                buf_count <= buf_count + 6'd1;
                flag_buf_count <= 1'b0;
            end
            else
            begin
                buf_count <= 6'd0;
                flag_buf_count <= 1'b1;
            end

            if (sample_count < 12'd3999)
            begin
                sample_count <= sample_count + 12'd1;
            end
            else
            begin
                sample_count <= 12'd0;
                block_count <= block_count + 4'b1;
            end

        end
    end
    else
    begin
        buf_count <= 6'd0;
        block_count <= 4'd0;
        flag_buf_count <= 1'd0;
    end
end

always_ff @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        write_enable_0 <= 1'd0;
        flag_reg <= 2'd0;
        complete_correct <= 1'd0;
    end
    else
    begin
        flag_reg <= {flag_reg[0], flag_buf_count};
        if (flag_reg[1] == 1'd0 && flag_reg[0] == 1'd1) write_enable_0 <= 1'd1;
        else write_enable_0 <= 1'd0;
        if (flag_reg[1] == 1'd1 && flag_reg[0] == 1'd0) acq_address <= acq_address + 9'd1;
        if (block_count == 4'd8 && write_enable_0 == 1'd1) complete_correct <= 1'd1;
        else complete_correct <= 1'd0;
    end
end

/* バッファへのデータの取り込みここまで */


logic [17:0] code_nco_phase;
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

logic [13:0] integrator_counter;
logic [2:0] sat_counter;

logic [11:0] ca_code_counter;

logic [35:0] corr_data_i;
logic [35:0] corr_data_q;
logic [5:0] corr_buf_counter;
logic [11:0] corr_sample_counter;
logic [3:0] incoh_counter;

logic signed [11:0] integrator_i0;
logic signed [11:0] integrator_q0;
logic signed [11:0] integrator_i1;
logic signed [11:0] integrator_q1;
logic signed [11:0] integrator_i2;
logic signed [11:0] integrator_q2;
logic signed [11:0] integrator_i3;
logic signed [11:0] integrator_q3;
logic signed [11:0] integrator_i4;
logic signed [11:0] integrator_q4;
logic signed [11:0] integrator_i5;
logic signed [11:0] integrator_q5;
logic signed [11:0] integrator_i6;
logic signed [11:0] integrator_q6;
logic signed [11:0] integrator_i7;
logic signed [11:0] integrator_q7;
logic [15:0] power_sum0;
logic [15:0] power_sum1;
logic [15:0] power_sum2;
logic [15:0] power_sum3;
logic [15:0] power_sum4;
logic [15:0] power_sum5;
logic [15:0] power_sum6;
logic [15:0] power_sum7;

logic [15:0] f_doppler_phase;
assign f_doppler_phase = doppler_phase + doppler_omega;


always_ff @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        corr_data_i <= 36'd0;
        corr_data_q <= 36'd0;
        corr_buf_counter <= 6'd0;
        corr_sample_counter <= 12'd0;
        corr_address <= 10'd0;
        incoh_counter <= 4'd0;

        integrator_counter <= 14'b0;
        integrator_i0 <= 12'sd0;
        integrator_q0 <= 12'sd0;
        integrator_i1 <= 12'sd0;
        integrator_q1 <= 12'sd0;
        integrator_i2 <= 12'sd0;
        integrator_q2 <= 12'sd0;
        integrator_i3 <= 12'sd0;
        integrator_q3 <= 12'sd0;
        integrator_i4 <= 12'sd0;
        integrator_q4 <= 12'sd0;
        integrator_i5 <= 12'sd0;
        integrator_q5 <= 12'sd0;
        integrator_i6 <= 12'sd0;
        integrator_q6 <= 12'sd0;
        integrator_i7 <= 12'sd0;
        integrator_q7 <= 12'sd0;

        sat0 <= 6'd1;
        sat1 <= 6'd2;
        sat2 <= 6'd3;
        sat3 <= 6'd4;
        sat4 <= 6'd5;
        sat5 <= 6'd6;
        sat6 <= 6'd7;
        sat7 <= 6'd8;

        g1 <= 10'b11_1111_1111;
        g2 <= 10'b11_1111_1111;
        code_phase <= 10'b0;
        code_nco_phase <= 18'b0;
        car_code_nco <= 1'b0;
        doppler_phase <= 16'sd0;
        doppler_omega <= DOPPLER_INIT;
        lo_i <= 1'b0;
        lo_q <= 1'b0;
        corr_complete <= 1'b0;
        doppler_block_complete <= 1'b0;
        sat_block_complete <= 1'b0;
        search_complete <= 1'b0;
        sat_counter <= 3'd0;
        doppler_counter <= 8'b0;
        ca_code_counter <= 12'b0;
    end
    else
    begin
        if (current_state == HOLD)
        begin
            corr_data_i <= 36'd0;
            corr_data_q <= 36'd0;
            corr_buf_counter <= 6'd0;
            corr_sample_counter <= 12'd0;
            corr_address <= 10'd0;
            incoh_counter <= 4'd0;

            integrator_counter <= 14'b0;
            integrator_i0 <= 12'sd0;
            integrator_q0 <= 12'sd0;
            integrator_i1 <= 12'sd0;
            integrator_q1 <= 12'sd0;
            integrator_i2 <= 12'sd0;
            integrator_q2 <= 12'sd0;
            integrator_i3 <= 12'sd0;
            integrator_q3 <= 12'sd0;
            integrator_i4 <= 12'sd0;
            integrator_q4 <= 12'sd0;
            integrator_i5 <= 12'sd0;
            integrator_q5 <= 12'sd0;
            integrator_i6 <= 12'sd0;
            integrator_q6 <= 12'sd0;
            integrator_i7 <= 12'sd0;
            integrator_q7 <= 12'sd0;

            sat0 <= 6'd1;
            sat1 <= 6'd2;
            sat2 <= 6'd3;
            sat3 <= 6'd4;
            sat4 <= 6'd5;
            sat5 <= 6'd6;
            sat6 <= 6'd7;
            sat7 <= 6'd8;
            g1 <= 10'b11_1111_1111;
            g2 <= 10'b11_1111_1111;
            code_phase <= 10'b0;
            code_nco_phase <= 18'd0;
            car_code_nco <= 1'b0;
            doppler_phase <= 16'sd0;
            doppler_omega <= DOPPLER_INIT;
            sat_counter <= 3'd0;
            corr_complete <= 1'b0;
            doppler_block_complete <= 1'b0;
            sat_block_complete <= 1'b0;
            search_complete <= 1'b0;
            doppler_counter <= 8'b0;
            ca_code_counter <= 12'b0;
        end

        else if (current_state == ACQ_INIT)
        begin
            corr_buf_counter <= 6'd0;
            corr_sample_counter <= 12'd0;
            corr_address <= 10'd0;
            incoh_counter <= 4'd0;
            power_sum0 <= 16'd0;
            power_sum1 <= 16'd0;
            power_sum2 <= 16'd0;
            power_sum3 <= 16'd0;
            power_sum4 <= 16'd0;
            power_sum5 <= 16'd0;
            power_sum6 <= 16'd0;
            power_sum7 <= 16'd0;

            integrator_counter <= 14'b0;
            integrator_i0 <= 12'sd0;
            integrator_q0 <= 12'sd0;
            integrator_i1 <= 12'sd0;
            integrator_q1 <= 12'sd0;
            integrator_i2 <= 12'sd0;
            integrator_q2 <= 12'sd0;
            integrator_i3 <= 12'sd0;
            integrator_q3 <= 12'sd0;
            integrator_i4 <= 12'sd0;
            integrator_q4 <= 12'sd0;
            integrator_i5 <= 12'sd0;
            integrator_q5 <= 12'sd0;
            integrator_i6 <= 12'sd0;
            integrator_q6 <= 12'sd0;
            integrator_i7 <= 12'sd0;
            integrator_q7 <= 12'sd0;

            g1 <= w_g1;
            g2 <= w_g2;
            code_nco_phase <= 18'd0;
            car_code_nco <= 1'b0;
            doppler_phase <= 16'd0;
            doppler_block_complete <= 1'b0;
            sat_block_complete <= 1'b0;
            corr_complete <= 1'b0;
            search_complete <= 1'b0;
            ca_code_counter <= 12'b0;
        end

        else if (current_state == DATA_BLOCK_READ_WAIT)
        begin
            corr_data_i <= dataout_i;
            corr_data_q <= dataout_q;
        end

        else if (current_state == CORR)
        begin
            /* 累算器 */
            integrator_i0 <= integrator_i0 + corr(tap(sat0), g1, g2, corr_data_i[corr_buf_counter]^lo_i);
            integrator_q0 <= integrator_q0 + corr(tap(sat0), g1, g2, corr_data_q[corr_buf_counter]^lo_q);
            integrator_i1 <= integrator_i1 + corr(tap(sat1), g1, g2, corr_data_i[corr_buf_counter]^lo_i);
            integrator_q1 <= integrator_q1 + corr(tap(sat1), g1, g2, corr_data_q[corr_buf_counter]^lo_q);
            integrator_i2 <= integrator_i2 + corr(tap(sat2), g1, g2, corr_data_i[corr_buf_counter]^lo_i);
            integrator_q2 <= integrator_q2 + corr(tap(sat2), g1, g2, corr_data_q[corr_buf_counter]^lo_q);
            integrator_i3 <= integrator_i3 + corr(tap(sat3), g1, g2, corr_data_i[corr_buf_counter]^lo_i);
            integrator_q3 <= integrator_q3 + corr(tap(sat3), g1, g2, corr_data_q[corr_buf_counter]^lo_q);
            integrator_i4 <= integrator_i4 + corr(tap(sat4), g1, g2, corr_data_i[corr_buf_counter]^lo_i);
            integrator_q4 <= integrator_q4 + corr(tap(sat4), g1, g2, corr_data_q[corr_buf_counter]^lo_q);
            integrator_i5 <= integrator_i5 + corr(tap(sat5), g1, g2, corr_data_i[corr_buf_counter]^lo_i);
            integrator_q5 <= integrator_q5 + corr(tap(sat5), g1, g2, corr_data_q[corr_buf_counter]^lo_q);
            integrator_i6 <= integrator_i6 + corr(tap(sat6), g1, g2, corr_data_i[corr_buf_counter]^lo_i);
            integrator_q6 <= integrator_q6 + corr(tap(sat6), g1, g2, corr_data_q[corr_buf_counter]^lo_q);
            integrator_i7 <= integrator_i7 + corr(tap(sat7), g1, g2, corr_data_i[corr_buf_counter]^lo_i);
            integrator_q7 <= integrator_q7 + corr(tap(sat7), g1, g2, corr_data_q[corr_buf_counter]^lo_q);

            /* コードNCO */
            if (corr_sample_counter < 12'd3999)
            begin
                {car_code_nco, code_nco_phase} <= code_nco_phase + CODE_NCO_OMEGA;
                if (code_nco_phase > (18'h3_ff_ff - CODE_NCO_OMEGA))
                begin
                    g1[10:1] <= {g1[9:1], g1[3] ^ g1[10]};
                    g2[10:1] <= {g2[9:1], g2[2] ^ g2[3] ^ g2[6] ^ g2[8] ^ g2[9] ^ g2[10]};
                    ca_code_counter <= ca_code_counter + 1'b1;
                end

                /* ドップラーNCO */
                doppler_phase <= doppler_phase + doppler_omega;
                lo_i <= LO_COS[doppler_phase[15:14]];
                lo_q <= LO_SIN[doppler_phase[15:14]];
            end

            /* バッファ周りのカウンタ */
            if (corr_buf_counter < 6'd35 && corr_sample_counter < 12'd3999)
            begin
                corr_buf_counter <= corr_buf_counter + 6'd1;
            end
            else
            begin
                corr_buf_counter <= 6'd0;
            end

            if (corr_sample_counter < 12'd3999)
            begin
                corr_sample_counter <= corr_sample_counter + 12'd1;
            end
            else
            begin
                corr_sample_counter <= 12'd0;
                incoh_counter <= incoh_counter + 4'b1;
            end

            if (corr_buf_counter == 6'd33 || corr_sample_counter == 12'd3999) corr_address <= corr_address + 9'd1;
        end

        else if (current_state == INCOH_SET)
        begin
            power_sum0 <= power_sum0 + {4'd0, abs(integrator_i0)} + {4'd0, abs(integrator_q0)};
            power_sum1 <= power_sum1 + {4'd0, abs(integrator_i1)} + {4'd0, abs(integrator_q1)};
            power_sum2 <= power_sum2 + {4'd0, abs(integrator_i2)} + {4'd0, abs(integrator_q2)};
            power_sum3 <= power_sum3 + {4'd0, abs(integrator_i3)} + {4'd0, abs(integrator_q3)};
            power_sum4 <= power_sum4 + {4'd0, abs(integrator_i4)} + {4'd0, abs(integrator_q4)};
            power_sum5 <= power_sum5 + {4'd0, abs(integrator_i5)} + {4'd0, abs(integrator_q5)};
            power_sum6 <= power_sum6 + {4'd0, abs(integrator_i6)} + {4'd0, abs(integrator_q6)};
            power_sum7 <= power_sum7 + {4'd0, abs(integrator_i7)} + {4'd0, abs(integrator_q7)};
            integrator_i0 <= 12'sd0;
            integrator_q0 <= 12'sd0;
            integrator_i1 <= 12'sd0;
            integrator_q1 <= 12'sd0;
            integrator_i2 <= 12'sd0;
            integrator_q2 <= 12'sd0;
            integrator_i3 <= 12'sd0;
            integrator_q3 <= 12'sd0;
            integrator_i4 <= 12'sd0;
            integrator_q4 <= 12'sd0;
            integrator_i5 <= 12'sd0;
            integrator_q5 <= 12'sd0;
            integrator_i6 <= 12'sd0;
            integrator_q6 <= 12'sd0;
            integrator_i7 <= 12'sd0;
            integrator_q7 <= 12'sd0;

            corr_sample_counter <= 12'd0;
            corr_buf_counter <= 6'd0;
            code_nco_phase <= 18'd0;
            car_code_nco <= 1'b0;
            g1 <= w_g1;
            g2 <= w_g2;
        end

        else if (current_state == CORR_COMPLETE)
        begin
            corr_complete <= 1'b1;
            incoh_counter <= 4'd0;
            integrator_0 <= power_sum0;
            integrator_1 <= power_sum1;
            integrator_2 <= power_sum2;
            integrator_3 <= power_sum3;
            integrator_4 <= power_sum4;
            integrator_5 <= power_sum5;
            integrator_6 <= power_sum6;
            integrator_7 <= power_sum7;
        end

        else if (current_state == CODE_PHASE_SET)
        begin
            code_phase <= code_phase + 1'b1;
        end

        else if (current_state == DOPPLER_SET)
        begin
            code_phase <= 10'b0;
            doppler_phase <= 16'd0;
            doppler_omega <= doppler_omega + DOPPLER_STEP;
            doppler_counter <= doppler_counter + 1'b1;
            doppler_block_complete <= 1'b1;
        end

        else if (current_state == SAT_SET)
        begin
            sat0 <= sat0 + 6'd8;
            sat1 <= sat1 + 6'd8;
            sat2 <= sat2 + 6'd8;
            sat3 <= sat3 + 6'd8;
            sat4 <= sat4 + 6'd8;
            sat5 <= sat5 + 6'd8;
            sat6 <= sat6 + 6'd8;
            sat7 <= sat7 + 6'd8;
            sat_counter <= sat_counter + 3'd1;
            sat_block_complete <= 1'b1;
        end

        else if (current_state == DONE)
        begin
            corr_complete <= 1'b0;
            doppler_block_complete <= 1'b0;
            sat_block_complete <= 1'b0;
            search_complete <= 1'b1;
        end
    end
end

endmodule
