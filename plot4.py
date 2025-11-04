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
		corr = int(newline[2].strip('  ').rstrip('  \n'))
		raw.append([sat, phase, corr])

corr_data = np.array(raw)

print(corr_data)

sat = 31#int(sys.argv[1])
print(sat)

#for n in range(1,33):
sat1 = np.where(corr_data[:,0] == sat)[0]
print("Sat: {0:d}".format(sat))
max_index = np.argmax(corr_data[sat1, 2])
print("Index: {0:d}".format(max_index))
print("phase: {0:d}".format(corr_data[sat1, 1][max_index]))
print("corr: {0:d}".format(corr_data[sat1, 2][max_index]))

plt.plot(corr_data[sat1, 1], corr_data[sat1, 2], '-')
plt.ylim(0,3000)
plt.show()

