import csv
import numpy as np
import matplotlib.pyplot as plt

raw = []

with open('./corr.dat', 'r') as f:
	for n in f:
		newline = n.rstrip('\n').split(',')
		print(newline)
		sat = newline[0].rstrip(' ,').strip(' ')
		phase = newline[1].rstrip(' ,').strip(' ')
		corr = newline[2].strip(' ').rstrip(' \n')
		raw.append([sat, phase, corr])


print(np.array(raw))

