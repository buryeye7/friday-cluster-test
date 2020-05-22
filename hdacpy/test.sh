#!/bin/bash

check_sync() {
    hdac_seed=$(kubectl get pods | grep hdac-seed | awk -F' ' '{print $1}')
    hdac_node3=$(kubectl get pods | grep hdac-node3 | awk -F' ' '{print $1}')
    while true
    do
        seed_height=$(kubectl exec $hdac_seed --container hdac-seed -- clif query block | jq .block_meta.header.height | sed "s/\"//g")
        node3_height=$(kubectl exec $hdac_node3 --container hdac-node3   -- clif query block | jq .block_meta.header.height | sed "s/\"//g")
        echo "check_sync: $seed_height $node3_height"
        if [ $seed_height == $node3_height ];then
            break
        fi  
    done
}

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

COUNT=$(curl $COUCHDB/seed-wallet-info/_all_docs 2>/dev/null | jq '.rows | length')
COUNT=$((COUNT - 1))
for i in $(seq 0 $COUNT)
do
    wallet_address=$(curl $COUCHDB/seed-wallet-info/_all_docs 2>/dev/null | jq .rows[$i].key | sed "s/\"//g")
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
    address=$(curl $COUCHDB/wallet-address/_all_docs 2>/dev/null | jq .rows[$i].key | sed "s/\"//g")
    node_pubkey=$(curl $COUCHDB/wallet-address/$address 2>/dev/null | jq .node_pub_key | sed "s/\"//g")
    wallet_alias=$(curl $COUCHDB/wallet-address/$address 2>/dev/null | jq .wallet_alias | sed "s/\"//g")
    node_number=$(echo $wallet_alias | sed "/s/node//g")
    mod=$(($node_number % 3))
    if [ $mod -ne 0 ];then
        continue
    fi
    share=$(($node_number / 3))
    if [ $share -gt 1 ];then
        check_sync
    fi
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
