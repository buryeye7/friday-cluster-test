#!/bin/bash

PW="12345678"
AMOUNT=1000000000000000
FARE=1
COUCHDB="http://admin:admin@$(./get-public-ip.sh couchdb):30598"
HDAC_SEED=$(kubectl get pods | grep hdac-seed | awk -F' ' '{print $1}')


COUNT=$(curl $COUCHDB/input-address/_all_docs 2>/dev/null | jq '.rows | length')
COUNT=$((COUNT - 1))

PRIV_KEYS=()
for i in $(seq 0 $COUNT)
do
    key=$(curl $COUCHDB/input-address/_all_docs 2>/dev/null | jq .rows[$i].key | sed "s/\"//g")
    PRIV_KEYS[$i]=$(curl $COUCHDB/input-address/$key 2>/dev/null | jq .private_key| sed "s/\"//g")
    address=$(curl $COUCHDB/input-address/$key 2>/dev/null | jq .address | sed "s/\"//g")
    expect -c "
    set timeout 3
    spawn kubectl exec $HDAC_SEED -it --container hdac-seed -- clif hdac transfer-to $address $AMOUNT $FARE --from node1
    expect "N]:"
        send \"y\\r\"
    expect "\'node1\':"
        send \"$PW\\r\"
    expect eof
    "
    echo ${PRIV_KEYS[$i]}
    sleep 10
done

COUNT=$(curl $COUCHDB/wallet-address/_all_docs 2>/dev/null | jq '.rows | length')
COUNT=$((COUNT - 1))

for i in $(seq 0 $COUNT)
do
    address=$(curl $COUCHDB/wallet-address/_all_docs 2>/dev/null | jq .rows[$i].key | sed "s/\"//g")
    expect -c "
    set timeout 3
    spawn kubectl exec $HDAC_SEED -it --container hdac-seed -- clif hdac transfer-to $address $AMOUNT $FARE --from node1
    expect "N]:"
        send \"y\\r\"
    expect "\'node1\':"
        send \"$PW\\r\"
    expect eof
    "
    sleep 10
done

NODE_ADDRESSES=()
kubectl get svc > /tmp/svcs.txt
i=0
while read line 
do
    if [[ $line == *"hdac-node"* ]];then
        NODE_ADDRESSES[$i]=$(echo $line | awk -F' ' '{print $4}' | sed "s/\"//g")
        #echo ${NODE_ADDRESSES[$i]}
        i=$((i + 1))
    fi
done < /tmp/svcs.txt
ADDRESS_CNT=$((i - 1))

for j in $(seq 0 $ADDRESS_CNT)
do
    ./transfer-to.py ${NODE_ADDRESSES[$j]} ${PRIV_KEYS[$j]} &
done

#Make validators
kubectl get pods > /tmp/pods.txt
while read line
do
    name=$(echo $line | awk -F' ' '{print $1}')        
    if [[ $name == *"hdac-node"* ]];then
        echo $name
    fi
done < /tmp/pods.txt    

./make-validator.sh
