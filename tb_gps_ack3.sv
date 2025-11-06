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

logic signed [11:0] integrator_i;
logic signed [11:0] integrator_q;
logic [11:0] ca_code_counter;

logic [31999:0] i;
logic [31999:0] q;
logic [13:0] acq_counter;

logic [17:0] code_nco_phase;
logic car_code_nco;

logic [10:1] g1;
logic [10:1] g2;

integer fd;
integer num;
integer rnum;
integer fd2;
integer rnum2;
integer k;
integer l;
integer m;
integer n;

logic [7:0] tmp1;
logic [7:0] tmp2;

parameter CODE_NCO_OMEGA = 67043; // 131 4Msps
//parameter CODE_NCO_OMEGA = 33522; // 131 4Msps

logic [5:0] sat0;
logic [7:0] sat0_tap;

logic [19:0] rom [0:1022];
logic [9:0] code_phase;

logic lo_i;
logic lo_q;
localparam LO_SIN = 4'b1100;
localparam LO_COS = 4'b0110;
logic signed [15:0] doppler_phase;
logic car_doppler_nco;
logic signed [15:0] doppler_omega;

logic [14:0] data_count;

logic [31:0] power_sum;

initial
begin

    /* CODE phase */
    $readmemh("phase_table_rev.hex", rom);

    sat0 = 6'd32;
    code_phase = 10'd0;
    sat0_tap = tap(sat0);
    //doppler_omega = 16'sd52;

    /* IQ data read */
    fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");

    for (k = 0; k < 32000; k++)
    begin
        rnum = $fread(tmp1, fd);
        rnum = $fread(tmp2, fd);

        i[k] = tmp1[2];
        q[k] = tmp2[2];

    end

    fd2 = $fopen("./corr2.dat", "w");
    lo_i = 1'b0;
    lo_q = 1'b0;

    for (n = -80; n < 80; n += 4)
    begin
        code_phase = 10'd0;
        for (l = 0; l < 1023; l++)
        begin
            data_count = 15'd0;
            power_sum = 0;
            doppler_phase = 16'sd0;
            doppler_omega = n[15:0];

            for (m = 0; m < 8; m++)
            begin
                integrator_i = 12'sd0;
                integrator_q = 12'sd0;
                code_nco_phase = 18'd0;
                {g1, g2} = rom[code_phase];

                for (k = 0; k < 4000; k++)
                begin
                    integrator_i = integrator_i + corr(tap(sat0), g1, g2, i[data_count]^lo_i);
                    integrator_q = integrator_q + corr(tap(sat0), g1, g2, q[data_count]^lo_q);
                    {car_code_nco, code_nco_phase} = code_nco_phase + CODE_NCO_OMEGA;
                    if (car_code_nco)
                    begin
                        g1[10:1] = {g1[9:1], g1[3] ^ g1[10]};
                        g2[10:1] = {g2[9:1], g2[2] ^ g2[3] ^ g2[6] ^ g2[8] ^ g2[9] ^ g2[10]};
                        ca_code_counter = ca_code_counter + 1'b1;
                    end

                    {car_doppler_nco, doppler_phase} = doppler_phase + doppler_omega;
                    lo_i = LO_COS[doppler_phase[15:14]];
                    lo_q = LO_SIN[doppler_phase[15:14]];

                    data_count = data_count + 15'd1;
                end
                power_sum = power_sum + {20'd0, abs(integrator_i)} + {20'd0, abs(integrator_q)};
            end
            $display("%d, %d, %d, %d", sat0, code_phase, doppler_omega, power_sum);
            $fwrite(fd2, "%d, %d, %d, %d\n", sat0, code_phase, doppler_omega, power_sum);
            code_phase = code_phase + 1;
        end
    end
    $finish;
end

endmodule

