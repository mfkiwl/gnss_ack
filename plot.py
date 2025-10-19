import csv
import numpy as np
import matplotlib.pyplot as plt

raw = []

with open('./corr.dat', 'r') as f:
	for n in f:
		newline = n.rstrip('\n').split(',')
		sat = int(newline[0].rstrip('  ,').strip('  '))
		phase = int(newline[1].rstrip('  ,').strip('  '))
		corr = int(newline[2].strip('  ').rstrip('  \n'))
		raw.append([sat, phase, corr])

corr_data = np.array(raw)

print(corr_data)

for n in range(1,33):
	sat1 = np.where(corr_data[:,0] == n)[0]
	print(n)
	print(sat1)
	print(corr_data[sat1, 1])
	print(corr_data[sat1, 2])

	plt.plot(corr_data[sat1, 1], corr_data[sat1, 2])
	plt.show()
