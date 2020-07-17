#!/usr/bin/python

from os import listdir
from os.path import isfile, join

path="./diffs/"
onlyfiles = [f for f in listdir(path) if isfile(join(path, f))]

for fileName in onlyfiles:
    sum=float(0)
    fd=open(path + fileName, 'r')
    i=0
    for num in fd.readlines():
        #print(num)
        sum += float(num)
        i += 1
    print i
    sum /= float(i)
    print(fileName + ": " + str(sum))
