import numpy as np
import matplotlib.pyplot as plt

# --- パラメータ設定 ---
fs = 4.0e6             # サンプリング周波数 [Hz]
chip_rate = 1.023e6    # C/Aコードレート [Hz]
code_len = 1023
prn = 31         # 対象PRN
douppler_init = 0
#code_nco_omega = 67043
code_nco_omega = 4290772
init_code_phase = 296
num_coherent = 4000

# --- C/Aコード生成 (ここでは既にPRN31の±1配列があると仮定) ---
# cacode = np.array([...], dtype=np.int8)
# 省略: あなたの既存のPRN31配列を使用
# PocketSDRからパクリ
NONE = np.array([], dtype='int8')
L1CA_G2_delay = ( # PRN 1 - 210
       5,   6,   7,   8,  17,  18, 139, 140, 141, 251, 252, 254, 255, 256, 257,
     258, 469, 470, 471, 472, 473, 474, 509, 512, 513, 514, 515, 516, 859, 860,
     861, 862, 863, 950, 947, 948, 950,  67, 103,  91,  19, 679, 225, 625, 946,
     638, 161,1001, 554, 280, 710, 709, 775, 864, 558, 220, 397,  55, 898, 759,
     367, 299,1018, 729, 695, 780, 801, 788, 732,  34, 320, 327, 389, 407, 525,
     405, 221, 761, 260, 326, 955, 653, 699, 422, 188, 438, 959, 539, 879, 677,
     586, 153, 792, 814, 446, 264,1015, 278, 536, 819, 156, 957, 159, 712, 885,
     461, 248, 713, 126, 807, 279, 122, 197, 693, 632, 771, 467, 647, 203, 145,
     175,  52,  21, 237, 235, 886, 657, 634, 762, 355,1012, 176, 603, 130, 359,
     595,  68, 386, 797, 456, 499, 883, 307, 127, 211, 121, 118, 163, 628, 853,
     484, 289, 811, 202,1021, 463, 568, 904, 670, 230, 911, 684, 309, 644, 932,
      12, 314, 891, 212, 185, 675, 503, 150, 395, 345, 846, 798, 992, 357, 995,
     877, 112, 144, 476, 193, 109, 445, 291,  87, 399, 292, 901, 339, 208, 711,
     189, 263, 537, 663, 942, 173, 900,  30, 500, 935, 556, 373,  85, 652, 310)


L1CA       = {}
L1CA_G1, L1CA_G2 = [], []
CHIP = (1, -1) # {0,1} <-> {+1,-1}

def xor_bits(X):
    return bin(X).count('1') % 2

def gen_code_L1CA(prn):
    if prn < 1 or prn > 210:
        return NONE
    N = 1023
    if prn not in L1CA:
        global L1CA_G1, L1CA_G2
        if len(L1CA_G1) == 0:
            L1CA_G1 = gen_code_L1CA_G1(N)
            L1CA_G2 = gen_code_L1CA_G2(N)
        L1CA[prn] = L1CA_G1 * np.roll(L1CA_G2, L1CA_G2_delay[prn-1])
    return L1CA[prn]

def LFSR(N, R, tap, n):
    code = np.zeros(N, dtype='int8')
    for i in range(N):
        code[i] = CHIP[R & 1]
        R = (xor_bits(R & tap) << (n - 1)) | (R >> 1)
    return code

def gen_code_L1CA_G1(N):
    return LFSR(N, 0b1111111111, 0b0010000001, 10)

def gen_code_L1CA_G2(N):
    return LFSR(N, 0b1111111111, 0b0110010111, 10)

cacode = gen_code_L1CA(prn)

cacode = (cacode & 0x4) >> 2
print(cacode)

# --- データ読み込み ---
raw = np.fromfile('L1_20211202_084700_4MHz_IQ.bin', dtype=np.int8)
i = raw[0::2]
q = raw[1::2]

i = (i & 0x4) >> 2
q = (q & 0x4) >> 2
#print(i)
#print(q)

iq = i + 1j * q
samples = len(iq)
print(f"Loaded {samples/fs*1000:.1f} ms of data")


# --- トラッキング ---
def cos(param):
    ss = [0, 0, 1 ,1]
    t = (param >> 22) & 0x3
    return ss[t]

def sin(param):
    ss = [0, 1, 1 ,0]
    t = (param >> 22) & 0x3
    return ss[t]

carrier_i = 0.0;
carrier_q = 0.0;
i_mixed = 0
q_mixed = 0

doppler_nco = 0
doppler_omega = 3

in0 = 0
qn0 = 0
dp_error = 0
dp_error_prev = 0
DP_NCO_FULL = 0xffffffff
CODE_NCO_FULL = 0xffffff

cacode = np.roll(cacode, init_code_phase + 1)

#code_nco_early = code_nco_omega//2
#code_nco_punctual = 0
#code_nco_late = CODE_FULL - code_nco_omega//2
code_nco = 0

code_error = 0
code_error_prev = 0

half_late = 0

code_phase_early = 0
code_phase_punctual = 0
code_phase_late = 1

coherent_data_counter = 0
integrator_i_punctual = 0
integrator_q_punctual = 0
integrator_i_early = 0
integrator_q_early = 0
integrator_i_late = 0
integrator_q_late = 0

track_punctual_i = np.zeros(samples//num_coherent+1)
track_punctual_q = np.zeros(samples//num_coherent+1)
track_early_i = np.zeros(samples//num_coherent+1)
track_early_q = np.zeros(samples//num_coherent+1)
track_late_i = np.zeros(samples//num_coherent+1)
track_late_q = np.zeros(samples//num_coherent+1)
errors = np.zeros(samples//num_coherent+1)
nco_omegas = np.zeros(samples//num_coherent+1)
demod_i = np.zeros(samples)
demod_q = np.zeros(samples)
sample_counter = 0
index_counter = 0

incoh_counter = 0
incoh_integ = 0

def xor(x, y):
    corr = x ^ y
    return 1 - 2*corr

for di, dq in zip(i, q):
    carrier_i = cos(doppler_nco)
    carrier_q = sin(doppler_nco)

    i_mixed = di ^ carrier_i
    q_mixed = dq ^ carrier_q

    i_corr_punctual = xor(i_mixed , cacode[code_phase_punctual])
    i_corr_early = xor(i_mixed , cacode[code_phase_early])
    i_corr_late = xor(i_mixed , cacode[code_phase_late])

    q_corr_punctual = xor(q_mixed , cacode[code_phase_punctual])
    q_corr_early = xor(q_mixed , cacode[code_phase_early])
    q_corr_late = xor(q_mixed , cacode[code_phase_late])

    integrator_i_late += i_corr_late
    integrator_q_late += q_corr_late
    integrator_i_early += i_corr_early
    integrator_q_early += q_corr_early
    integrator_i_punctual += i_corr_punctual
    integrator_q_punctual += q_corr_punctual


    if doppler_nco > DP_NCO_FULL:
        doppler_nco -= DP_NCO_FULL
        doppler_nco += doppler_omega
    else:
        doppler_nco += doppler_omega

    code_nco += code_nco_omega
    if CODE_NCO_FULL < code_nco:
        code_nco -= CODE_NCO_FULL

        code_phase_late += 1
        if code_phase_late > 1022:
            code_phase_late = 0

        code_phase_early += 1
        if code_phase_early > 1022:
            code_phase_early = 0

    if (CODE_NCO_FULL//2) < code_nco:
        if half_late == 0:
            code_phase_punctual += 1
            if code_phase_punctual > 1022:
                code_phase_punctual = 0
        half_late = 1

    if code_nco < (CODE_NCO_FULL // 2):
        half_late = 0

#    print("Cnt: {}".format(coherent_data_counter))
#    print("EARLY: {}".format(code_phase_early))
#    print("PUNCTUAL: {}".format(code_phase_punctual))
#    print("LATE: {}".format(code_phase_late))
#    print()
#    print()

    coherent_data_counter += 1

    if coherent_data_counter > (num_coherent - 1):
        track_late_i[index_counter] = integrator_i_late
        track_late_q[index_counter] = integrator_q_late
        track_early_i[index_counter] = integrator_i_early
        track_early_q[index_counter] = integrator_q_early
        track_punctual_i[index_counter] = integrator_i_punctual
        track_punctual_q[index_counter] = integrator_q_punctual

        #ee = int(np.floor(np.arctan2(integrator_i_punctual, integrator_q_punctual)))
        dp_error = integrator_i_punctual*qn0 - integrator_q_punctual*in0
        print("DP ERR: {}".format(dp_error))
        in0 = integrator_i_punctual
        qn0 = integrator_q_punctual
        errors[index_counter] = dp_error
        doppler_omega += int(dp_error//2000) + int((dp_error - dp_error_prev)//20000)
        dp_error_prev = dp_error
        print("DF: {}".format(int(dp_error//2000) + int((dp_error - dp_error_prev)//20000)))
        print("DP omega: {}".format(doppler_omega))

        incoh_integ += np.abs(integrator_i_punctual) + np.abs(integrator_q_punctual)
        incoh_counter += 1

        if incoh_counter > 8:

            print("Incoh integ: {}".format(incoh_integ))
            print()
            print()
            incoh_counter = 0
            incoh_integ = 0

            code_error = ((integrator_i_late - integrator_i_early)*integrator_i_punctual + (integrator_q_late - integrator_q_early)*integrator_q_punctual)//2
            print("I early: {}".format(integrator_i_early))
            print("I late: {}".format(integrator_i_late))
            print("Q early: {}".format(integrator_q_early))
            print("Q late: {}".format(integrator_q_late))
            print("I punctual: {}".format(integrator_i_punctual))
            print("Q punctual: {}".format(integrator_q_punctual))
            print("CODE ERR: {}".format(code_error))
            #code_nco_omega += int(code_error//100000) + int((code_error - code_error_prev)//1000000)
            print("DD: {}".format(int(code_error//100000) + int((code_error - code_error_prev)//1000000)))

            code_error_prev = code_error
            print("CODE omega: {}".format(code_nco_omega))

        integrator_i_late = 0
        integrator_q_late = 0
        integrator_i_punctual = 0
        integrator_q_punctual = 0
        integrator_i_early = 0
        integrator_q_early = 0
        coherent_data_counter = 0
        index_counter += 1

fig = plt.figure()
ax = fig.add_subplot(311)
ax.plot(track_punctual_i)
ax.plot(track_punctual_q)
#ax.plot(track_early_i - track_late_i)
#ax.plot(track_early_q - track_late_q)

az = fig.add_subplot(312)
az.plot(errors)

ay = fig.add_subplot(313)
ay.plot(track_punctual_i[500:], track_punctual_q[500:], ".")
ay.axis("equal")
plt.show()




