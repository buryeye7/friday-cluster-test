#!/bin/bash

COUCHDB="http://admin:admin@couchdb-app-svc:5984"
SRC="$GOPATH/src/friday"

if [ $TARGET == "friday" ];then
    cp -rf $GOPATH/src/friday-cluster-test/config/ulb-node-config/nodef-config/* $HOME/.nodef
    cp -rf $GOPATH/src/friday-cluster-test/config/ulb-node-config/clif-config/* $HOME/.clif
else
    cp -rf $GOPATH/src/friday-cluster-test/config/node-config/nodef-config/* $HOME/.nodef
    cp -rf $GOPATH/src/friday-cluster-test/config/node-config/clif-config/* $HOME/.clif
fi

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

NODE_ID=$(nodef tendermint show-node-id)
IP_ADDRESS=$(hostname -I)
IP_ADDRESS=$(echo $IP_ADDRESS)

curl -X PUT $COUCHDB/seed-info/seed-info -d "{\"target\":\"${NODE_ID}@${IP_ADDRESS}:26656\"}"

for i in $(seq 1 $WALLET_CNT)
do
    wallet_address=$(clif keys show node$i -a)
    curl -X PUT $COUCHDB/seed-wallet-info/$wallet_address -d "{\"wallet_alias\":\"node$i\"}"
done

clif rest-server --laddr tcp://0.0.0.0:1317 > clif.txt 2>&1 &
nodef start 2>/dev/null
