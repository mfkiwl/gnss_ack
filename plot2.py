import csv
import numpy as np
import matplotlib.pyplot as plt

raw = []

with open('./corr_check.dat', 'r') as f:
	for n in f:
		newline = n.rstrip('\n').split(',')
		phase = int(newline[0].rstrip('  ,').strip('  '))
		corr = int(newline[1].strip('  ').rstrip('  \n'))
		raw.append([phase, corr])

corr_data = np.array(raw)

print(corr_data)

#for n in range(1,33):
plt.plot(corr_data[:,0], corr_data[:, 1])
plt.show()
