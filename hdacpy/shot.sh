#!/bin/bash

while read line
do
    param1=$(echo $line | awk -F' ' '{print $1}')
    param2=$(echo $line | awk -F' ' '{print $2}')
    ./transfer-to.py $param1 $param2 >> transfer-to-log$j.txt &    
done < test-info-after-mempool-full.txt
