#!/bin/bash

#node_pubkey=$(nodef tendermint show-validator)

PW="12345678"
i=1
while read line
do
    
    node_pubkey=$line
    wallet_alias="node$i"
    address=$(clif keys show node$i | jq .address | sed "s/\"//g")

    expect -c "
    set timeout 3
    spawn clif hdac transfer-to $address 100000 1 --from node 
    expect "N]:"
        send \"y\\r\"
    expect "\'node\':"
        send \"$PW\\r\"
    expect eof
    "
    sleep 10 
    expect -c "
    set timeout 3
    spawn clif hdac create-validator 1 --from $wallet_alias --pubkey $node_pubkey --moniker solution$i --chain-id testnet
    expect "N]:"
        send \"y\\r\"
    expect "\'$wallet_alias\':"
        send \"$PW\\r\"
    expect eof
    "
    sleep 10 
    expect -c "
    set timeout 3
    spawn clif hdac bond --from $wallet_alias 1 0.01 --chain-id testnet
    expect "N]:"
        send \"y\\r\"
    expect "\'$wallet_alias\':"
        send \"$PW\\r\"
    expect eof
    "
    sleep 10 
    expect -c "
    set timeout 3
    spawn clif hdac delegate $address --from $wallet_alias 1 0.01 --chain-id testnet
    expect "N]:"
        send \"y\\r\"
    expect "\'$wallet_alias\':"
        send \"$PW\\r\"
    expect eof
    "
    sleep 10 

    i=$((i+1))
done < node-pubkey.txt
