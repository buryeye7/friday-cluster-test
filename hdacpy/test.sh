#!/bin/bash

INTERVAL=$1
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
    sleep $INTERVAL
done

WALLET_ALIAS=()
COUNT=$(curl $COUCHDB/seed-wallet-info/_all_docs 2>/dev/null | jq '.rows | length')
COUNT=$((COUNT - 1))
for i in $(seq 0 $COUNT)
do
    wallet_address=$(curl $COUCHDB/seed-wallet-info/_all_docs 2>/dev/null | jq .rows[$i].key | sed "s/\"//g")
    WALLET_ALIAS[$i]=$(curl $COUCHDB/seed-wallet-info/$wallet_address 2>/dev/null | jq .wallet_alias | sed "s/\"//g")
    expect -c "
    set timeout 3
    spawn kubectl exec $HDAC_SEED -it --container hdac-seed -- clif hdac transfer-to $wallet_address $AMOUNT $FARE --from node1
    expect "N]:"
        send \"y\\r\"
    expect "\'node1\':"
        send \"$PW\\r\"
    expect eof
    "
    sleep $INTERVAL
done

COUNT=$(curl $COUCHDB/wallet-address/_all_docs 2>/dev/null | jq '.rows | length')
COUNT=$(($COUNT - 1))
for i in $(seq 0 $COUNT)
do
    j=$((i + 1))
    mod=$((j % 3))
    if [ $mod -ne 0 ];then
        continue
    fi
    address=$(curl $COUCHDB/wallet-address/_all_docs 2>/dev/null | jq .rows[$i].key | sed "s/\"//g")
    node_pubkey=$(curl $COUCHDB/wallet-address/$address 2>/dev/null | jq .node_pub_key | sed "s/\"//g")
    wallet_alias=${WALLET_ALIAS[$i]}
    expect -c "
    set timeout 3
    spawn kubectl exec $HDAC_SEED -it --container hdac-seed -- clif hdac create-validator 1 --from $wallet_alias --pubkey $node_pubkey --moniker solution$i --chain-id testnet
    expect "N]:"
        send \"y\\r\"
    expect "\'$wallet_alias\':"
        send \"$PW\\r\"
    expect eof
    "
    sleep $INTERVAL
    expect -c "
    set timeout 3
    spawn kubectl exec $HDAC_SEED -it --container hdac-seed -- clif hdac bond --from $wallet_alias 1 0.01 --chain-id testnet
    expect "N]:"
        send \"y\\r\"
    expect "\'$wallet_alias\':"
        send \"$PW\\r\"
    expect eof
    "
    sleep $INTERVAL
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

rm test-info-after-mempool-full.txt
touch test-info-after-mempool-full.txt
ADDRESS_CNT=$((i - 1))
for i in $(seq 0 $ADDRESS_CNT)
do
    j=$((i+1))
    #mod=$((j%3))
    if [ $j -lt 7 ];then
        echo ${NODE_ADDRESSES[$i]} ${PRIV_KEYS[$i]} >> test-info-after-mempool-full.txt
        continue
    fi
    echo ${NODE_ADDRESSES[$i]} ${PRIV_KEYS[$i]} > transfer-to$j.log 
    ./transfer-to.py ${NODE_ADDRESSES[$i]} ${PRIV_KEYS[$i]} >> transfer-to$j.log &
done
