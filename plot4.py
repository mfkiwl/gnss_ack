import csv
import numpy as np
import matplotlib.pyplot as plt
import sys

raw = []

with open('./corr3.dat', 'r') as f:
	for n in f:
		newline = n.rstrip('\n').split(',')
		sat = int(newline[0].rstrip('  ,').strip('  '))
		code = int(newline[1].rstrip('  ,').strip('  '))
		doppler = int(newline[2].rstrip('  ,').strip('  '))
		corr = int(newline[3].strip('  ').rstrip('  \n'))
		raw.append([sat, code, doppler, corr])

corr_data = np.array(raw)

print(corr_data)

sat = int(sys.argv[1])
print(sat)

#for n in range(1,33):
sat1 = np.where(corr_data[:,0] == sat)[0]
doppler_list = np.unique(corr_data[sat1, 2])
code_list = np.unique(corr_data[sat1, 1])
print(doppler_list)
print(code_list)
#for n in doppler_list:



print("Sat: {0:d}".format(sat))
max_index = np.argmax(corr_data[sat1, 3])
print("Index: {0:d}".format(max_index))
print("code phase: {0:d}".format(corr_data[sat1, 1][max_index]))
print("doppler freq.: {0:d}".format(corr_data[sat1, 1][max_index]))
print("corr: {0:d}".format(corr_data[sat1, 3][max_index]))

plt.plot(corr_data[sat1, 1], corr_data[sat1, 3], '-')
plt.ylim(0,5000)
plt.show()

