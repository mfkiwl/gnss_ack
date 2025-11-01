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

function doppler_i;
    input sig_i;
    input sig_q;
    input dp_i;
    input dp_q;
    logic mix_i;
    logic mix_q;

    mix_i = ~(sig_i ^ dp_i);
    mix_q = ~(sig_q ^ dp_q);
    doppler_i = ~(mix_i ^ mix_q);
endfunction

function doppler_q;
    input sig_i;
    input sig_q;
    input dp_i;
    input dp_q;
    logic mix_i;
    logic mix_q;

    mix_i = ~(sig_q ^ dp_i);
    mix_q = ~(sig_i ^ dp_q);
    doppler_q = mix_q ^ mix_i;
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

    corr =  ~(x ^ cacode(g1, g2, sat_taps[7:4], sat_taps[3:0]));
endfunction

logic [11:0] integrator_i;
logic [11:0] integrator_q;
logic [11:0] ca_code_counter;

logic [3999:0] i;
logic [3999:0] q;
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

logic [7:0] tmp1;
logic [7:0] tmp2;

parameter CODE_NCO_OMEGA = 67027; // 131 4Msps

logic [5:0] sat0;

logic [19:0] rom [0:1022];
logic [9:0] code_phase;


initial
begin

    /* CODE phase */
    $readmemh("phase_state.hex", rom);

    sat0 = 6'd26;
    code_phase = 10'd0;

    /* IQ data read */
    fd = $fopen("./L1_20211202_084700_4MHz_IQ.bin", "rb");

    for (k = 0; k < 4000; k++)
    begin
        rnum = $fread(tmp1, fd);
        rnum = $fread(tmp2, fd);

        i[k] = tmp1[2];
        q[k] = ~tmp2[2];
    end

    fd2 = $fopen("./corr2.dat", "w");

    for (l = 0; l < 1023; l++)
    begin
        integrator_i = 12'd0;
        integrator_q = 12'd0;
        {g1, g2} = rom[code_phase];

        for (k = 0; k < 4000; k++)
        begin
            integrator_i = integrator_i + {11'd0, corr(tap(sat0), g1, g2, i[k])};
            integrator_q = integrator_q + {11'd0, corr(tap(sat0), g1, g2, q[k])};
            {car_code_nco, code_nco_phase} = code_nco_phase + CODE_NCO_OMEGA;
            if (car_code_nco)
            begin
                g1[10:1] = {g1[9:1], g1[3] ^ g1[10]};
                g2[10:1] = {g2[9:1], g2[2] ^ g2[3] ^ g2[6] ^ g2[8] ^ g2[9] ^ g2[10]};
                ca_code_counter = ca_code_counter + 1'b1;
            end
        end
		$display("%d, %d, %d, %d, %d, %d", sat0, code_phase, 0, 0, integrator_i, integrator_q);
		$fwrite(fd2, "%d, %d, %d, %d, %d, %d\n", sat0, code_phase, 0, 0, integrator_i, integrator_q);
		code_phase = code_phase + 1;
    end
    $finish;
end

endmodule

