#!/bin/python3

fd = open('/tmp/result.txt','r')

checkGap = 0
deliverGap = 0
commitGap = 0
for line in fd.readlines():
	listList = line.split()
	listList = line.split()
	value = int(listList[4])
	if 'Gap' in line and 'CheckTx' in line:
		checkGap += value	
	elif 'Gap' in line and 'Execute' in line:
		deliverGap += value	
	elif 'Gap' in line and 'Commit' in line:
		commitGap += value	

print(checkGap/100)
print(deliverGap/100)
print(commitGap/100)
fd.close()
