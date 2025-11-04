import numpy as np
import matplotlib.pyplot as plt

# --- パラメータ設定 ---
fs = 4.0e6             # サンプリング周波数 [Hz]
chip_rate = 1.023e6    # C/Aコードレート [Hz]
code_len = 1023
prn =  31             # 対象PRN
coh_ms = 1             # コヒーレント積分時間 [ms]
noncoh_num = 8     # 非コヒーレント回数
fd_candidates = np.arange(-5000, 5001, 500)  # ドップラー探索範囲 [Hz]

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

def xor_bits(X):
    return bin(X).count('1') % 2
L1CA       = {}
L1CA_G1, L1CA_G2 = [], []
CHIP = (1, -1) # {0,1} <-> {+1,-1}
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
print(i)
print(q)

iq = i + 1j * q
samples = len(iq)
print(f"Loaded {samples/fs*1000:.1f} ms of data")

# --- コードNCO（サンプルごとのチップインデックス） ---
fcw = chip_rate / fs
chip_idx = (np.floor(np.arange(int(fs*coh_ms/1000)) * fcw) % code_len).astype(int)

# --- 相関結果格納 ---
#corr_map = np.zeros((len(fd_candidates), code_len))
corr_map = np.zeros((len(fd_candidates), code_len))

def xor_corr(data_bits, code_bits):
    xor = np.bitwise_xor(data_bits, code_bits)
    return np.sum(1 - 2*xor)

# --- メインループ ---
# Doppler search loop
for fi, fd in enumerate(fd_candidates):
    print(f"Doppler {fd:+6.0f} Hz ...")
    n = np.arange(samples)
    carrier_i = (np.sign(np.cos(2*np.pi*fd/fs*n)) > 0).astype(np.uint8)
    carrier_q = (np.sign(np.sin(2*np.pi*fd/fs*n)) > 0).astype(np.uint8)

    i_mixed = np.bitwise_xor(i, carrier_i)
    q_mixed = np.bitwise_xor(q, carrier_q)

    for code_delay in range(code_len):
        local_code = np.roll(cacode, code_delay)[chip_idx]

        # --- コヒーレント相関をnoncoh_num回繰り返して非コヒーレント積分 ---
        power_sum = 0.0
        for blk in range(noncoh_num):
            start = blk * int(fs * coh_ms / 1000)
            stop  = start + int(fs * coh_ms / 1000)
            i_corr = xor_corr(i_mixed[start:stop], local_code)
            q_corr = xor_corr(q_mixed[start:stop], local_code)

            power_sum += np.abs(i_corr) + np.abs(q_corr)

        corr_map[fi, code_delay] = power_sum

# --- 結果表示 ---
max_fd_i, max_code_i = np.unravel_index(np.argmax(corr_map), corr_map.shape)
print(f"Detected peak: Doppler={fd_candidates[max_fd_i]} Hz, Code phase={max_code_i}, Corr={corr_map[max_fd_i, max_code_i]}")

fig = plt.figure()
ax = fig.add_subplot(211)
im1 =ax.imshow(corr_map.T, aspect='auto',
           extent=[fd_candidates[0], fd_candidates[-1], 0, 1023],
           origin='lower', cmap='inferno')
ax.set_xlabel("Doppler [Hz]")
ax.set_ylabel("Code phase [chips]")
ax.set_title("GPS PRN{} correlation ({} ms non-coherent)".format(prn,noncoh_num))
fig.colorbar(im1, label="Correlation")
ay = fig.add_subplot(212)
ay.plot(np.arange(1023), corr_map[max_fd_i, :])

#idx = np.argmax(corr_map)
#print("Detected peak: corr = {}, code phase = {}".format(corr_map[idx], idx))

#fig = plt.figure()
#ax = fig.add_subplot(111)
#ax.plot(range(1023), corr_map)
#ax.set_ylim(0,3000)

plt.show()
