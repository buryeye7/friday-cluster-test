#!/bin/bash

rm txs.txt
touch txs.txt
for i in {0..5}
do
    cat transfer-to-log$i.txt | grep txhash | sed "s/txhash//g" | sed "s/\"//g" | sed "s/,//g" | sed "s/://g" | sed 's/ //g' >> txs.txt
done

rm check-result.txt
touch check-result.txt
HDAC_SEED=$(kubectl get pods | grep hdac-seed | awk -F' ' '{print $1}')
while read line
do
    kubectl exec $HDAC_SEED --container hdac-seed -- clif query tx $line >> check-result.txt    
done < txs.txt
