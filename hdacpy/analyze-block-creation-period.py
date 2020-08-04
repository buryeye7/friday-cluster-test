#!/bin/python3

fd = open('/tmp/nodef.txt','r')

gapList = []
begin = 0
for line in fd.readlines():
	lineList = line.split()
	if 'enterCommit' in line or 'Executed' in line:
		phrase = lineList[0].replace('I','').replace('[','').replace(']','').split('|')[1].split(":")
		time = int(phrase[0])*3600*1000
		minute = int(phrase[1])*60*1000
		second = int(phrase[2].split('.')[0])*1000 + int(phrase[2].split('.')[1])
		if 'enterCommit' in line:
			print(line)
			begin = time + minute + second
		else:
			if 'validTxs=1' in line:
				print(line)
				current = time + minute + second
				gapList.append(current - begin)

for gap in gapList:
	print(gap)
print(sum(gapList)/len(gapList))
fd.close()
