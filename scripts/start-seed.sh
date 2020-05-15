#!/bin/bash

COUCHDB="http://admin:admin@13.125.228.37:5984"
SRC="$GOPATH/src/friday"

ps -ef | grep grpc | while read line
do
    if [[ $line == *"CasperLabs"* ]];then
        target=$(echo $line |  awk -F' ' '{print $2}')
        kill -9 $target
    fi
done

ps -ef | grep nodef | while read line
do
    if [[ $line == *"nodef"* ]];then
        target=$(echo $line |  awk -F' ' '{print $2}')
        kill -9 $target
    fi
done

# run execution engine grpc server
$SRC/CasperLabs/execution-engine/target/release/casperlabs-engine-grpc-server -z -t 8 $HOME/.casperlabs/.casper-node.sock&

WALLET_ADDRESS=$(clif keys show node1 -a)
NODE_PUB_KEY=$(nodef tendermint show-validator)
NODE_ID=$(nodef tendermint show-node-id)
IP_ADDRESS=$(hostname -I)
IP_ADDRESS=$(echo $IP_ADDRESS)
curl -X PUT $COUCHDB/wallet-address/$WALLET_ADDRESS -d "{\"type\":\"seed-node\",\"node-pub-key\":\"$NODE_PUB_KEY\",\"node-id\":\"$NODE_ID\",\"ip-address\":\"${IP_ADDRESS}\"}"
curl -X PUT $COUCHDB/seed-info/seed-info -d "{\"target\":\"${NODE_ID}@${IP_ADDRESS}:26656\"}"

nodef start 2>/dev/null
