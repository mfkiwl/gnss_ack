import csv
import numpy as np
import matplotlib.pyplot as plt
import sys

raw = []

with open('./corr2.dat', 'r') as f:
	for n in f:
		newline = n.rstrip('\n').split(',')
		sat = int(newline[0].rstrip('  ,').strip('  '))
		phase = int(newline[1].rstrip('  ,').strip('  '))
		phase2 = int(newline[2].strip('  ').rstrip('  '))
		doppler = int(newline[3].strip('  ').rstrip('  '))
		corr_i = int(newline[4].strip('  ').rstrip('  '))
		corr_q = int(newline[5].strip('  ').rstrip('  \n'))
		raw.append([sat, phase, phase2, doppler, corr_i, corr_q])

corr_data = np.array(raw)

print(corr_data)

sat = int(sys.argv[1])
print(sat)

num_sample = int(sys.argv[2])

#for n in range(1,33):
sat1 = np.where(corr_data[:,0] == sat)[0]
print("Sat: {0:d}".format(sat))
#	print(sat1)
	#print(corr_data[sat1, 1])
	#print(corr_data[sat1, 2])
min_index = np.argmin(corr_data[sat1, 4])
corr = np.sqrt((corr_data[sat1, 4] - num_sample//2 - 1)**2 + (corr_data[sat1, 5] - num_sample//2 - 1)**2)
min_index = np.argmax(corr)
print("Index: {0:d}".format(min_index))
print("phase: {0:d}".format(corr_data[sat1, 1][min_index]))
print("frac: {0:d}".format(corr_data[sat1, 2][min_index]))
print("Doppler: {0:d}".format(corr_data[sat1, 3][min_index]))
print("Corr_i: {0:d}".format(corr_data[sat1, 4][min_index]))
print("Corr_q: {0:d}".format(corr_data[sat1, 5][min_index]))
print("Corr: {0:f}".format(corr[min_index]))

plt.plot(corr_data[sat1, 1], corr, '.')
plt.ylim((0, 400))
plt.show()

