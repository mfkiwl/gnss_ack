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
    output logic corr_complete,
    output logic [9:0] code_phase,
    output logic signed [15:0] doppler_omega,
    output logic [5:0] sat0,
    output logic [13:0] integrator_0,
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
    ACQ_INIT,
    CODE_SET_WAIT,
    DATA_BLOCK_READ_WAIT,
    CORR,
    CORR_COMPLETE,
    INCOH_SET,
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

    ACQ_INIT: next_state = CORR;

    DATA_BLOCK_READ_WAIT: next_state = CORR;

    CORR:
    begin
        if (integrator_counter < SAMPLE_NUM - 1) next_state = CORR;
        else next_state = CORR_COMPLETE;
    end

    CORR_COMPLETE: next_state = CODE_PHASE_SET; // next_state = CODE_NCO_SET;

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
        //if (sat_counter < 3'd3) next_state = ACQ_INIT;
        next_state = DONE;//else next_state = DONE;
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

logic [5:0] buf_count;
logic [11:0] sample_count;
logic [3:0] incoh_count;
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
        incoh_count <= 4'd0;
        write_enable_0 <= 1'd0;
        address <= 10'd0;
        flag_reg <= 2'd0;
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
            end
            else
            begin
                buf_count <= 6'd0;
            end

            if (sample_count < 12'd3999)
            begin
                sample_count <= sample_count + 12'd1;
            end
            else
            begin
                sample_count <= 12'd0;
                incoh_count <= incoh_count + 4'b1;
            end


            if (buf_count == 6'd35 || sample_count == 12'd3999) write_enable_0 <= 1'd1;
            else write_enable_0 <= 1'd0;

            if (buf_count == 6'd35 || sample_count == 12'd3999) address <= address + 9'd1;

            if (incoh_count == 4'd8 && write_enable_0 == 1'd1) complete_correct <= 1'd1;
            else complete_correct <= 1'd0;
        end
    end
    else
    begin
        buf_count <= 6'd0;
        write_enable_0 <= 1'd0;
        address <= 10'd0;
        complete_correct <= 1'd0;
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

logic [35:0] data_part;
logic signed [11:0] integrator_i_part;
logic signed [11:0] integrator_q_part;
logic [8:0] data_block_counter;

always_ff @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        integrator_counter <= 14'b0;
        integrator_i_part <= 12'sd0;
        integrator_q_part <= 12'sd0;
        data_block_counter <= 9'd0;

        sat0 <= 6'd32;
        g1 <= 10'b11_1111_1111;
        g2 <= 10'b11_1111_1111;
        code_phase <= 10'b0;
        code_nco_phase <= 18'b0;
        doppler_phase <= 16'b0;
        doppler_omega <= 16'b0;
        lo_i <= 1'b0;
        lo_q <= 1'b0;
        corr_complete <= 1'b0;
        search_complete <= 1'b0;
        sat_counter <= 3'd0;
        doppler_counter <= 8'b0;
        ca_code_counter <= 12'b0;
    end
    else
    begin
        if (current_state == HOLD)
        begin
            integrator_counter <= 14'b0;
            integrator_i_part <= 12'sd0;
            integrator_q_part <= 12'sd0;
            data_block_counter <= 9'd0;

            sat0 <= 6'd31;
            g1 <= 10'b11_1111_1111;
            g2 <= 10'b11_1111_1111;
            code_phase <= 10'b0;
            code_nco_phase <= 18'b0;
            doppler_phase <= 16'b0;
            doppler_omega <= 16'b0;
            sat_counter <= 3'd0;
            corr_complete <= 1'b0;
            search_complete <= 1'b0;
            doppler_counter <= 8'b0;
            ca_code_counter <= 12'b0;
        end

                else if (current_state == ACQ_INIT)
        begin
            integrator_counter <= 14'b0;
            integrator_i_part <= 12'sd0;
            integrator_q_part <= 12'sd0;
            data_block_counter <= 9'd0;

            g1 <= w_g1;
            g2 <= w_g2;
            doppler_phase <= 16'b0;
            corr_complete <= 1'b0;
            search_complete <= 1'b0;
            ca_code_counter <= 12'b0;
        end

        else if (current_state == CORR)
        begin
            //integrator_counter <= integrator_counter + 14'b1;
            //integrator_i_p = integrator_i + corr(tap(sat0), g1, g2, i[data_count]^lo_i);
            //integrator_q = integrator_q + corr(tap(sat0), g1, g2, q[data_count]^lo_q);

            {car_code_nco, code_nco_phase} <= code_nco_phase + CODE_NCO_OMEGA;
            if (car_code_nco)
            begin
                g1[10:1] <= {g1[9:1], g1[3] ^ g1[10]};
                g2[10:1] <= {g2[9:1], g2[2] ^ g2[3] ^ g2[6] ^ g2[8] ^ g2[9] ^ g2[10]};
                ca_code_counter <= ca_code_counter + 1'b1;
            end

            {car_doppler_nco, doppler_phase} <= doppler_phase + doppler_omega;
            lo_i <= LO_SIN[doppler_phase[15:14]];
            lo_q<= LO_COS[doppler_phase[15:14]];
        end

        else if (current_state == CORR_COMPLETE)
        begin
            corr_complete <= 1'b1;
        end

        else if (current_state == INCOH_SET)
        begin

        end

        else if (current_state == CODE_PHASE_SET)
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

        else if (current_state == DONE)
        begin
            corr_complete <= 1'b0;
            search_complete <= 1'b1;
        end
    end
end

endmodule
