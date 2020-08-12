#!/bin/bash

rm transfer-to-log*
i=0

while read line 
do
    param1=$(echo $line | awk -F' ' '{print $1}')
    param2=$(echo $line | awk -F' ' '{print $2}')
    echo $param1 
    echo $param2
    ./transfer-to-interval.py $param1 $param2 > transfer-to-log$i.txt &
    i=$((i + 1))
done < test-info.txt
