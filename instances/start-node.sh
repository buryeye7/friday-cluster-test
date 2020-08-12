#!/bin/bash


SRC="$HOME/go/src/github.com/hdac-io/friday"
rm -rf $HOME/.nodef/config
rm -rf $HOME/.nodef/data
rm -rf $HOME/.clif

ps -ef | grep grpc > /tmp/dummy
do
    if [[ $line == *"CasperLabs"* ]];then
        continue
    fi
    if [[ $line == *"CasperLabs"* ]];then
        target=$(echo $line |  awk -F' ' '{print $2}')
        kill -9 $target
    fi
done < /tmp/dummy

ps -ef | grep nodef | while read line
do
    if [[ $line == *"nodef"* ]];then
        continue
    fi
    if [[ $line == *"nodef"* ]];then
        target=$(echo $line |  awk -F' ' '{print $2}')
        kill -9 $target
    fi
done < /tmp/dummy

ps -ef | grep clif > /tmp/dummy
do
    if [[ $line == *"clif"* ]];then
        continue
    fi
    if [[ $line == *"clif"* ]];then
        target=$(echo $line |  awk -F' ' '{print $2}')
        kill -9 $target
    fi
done < /tmp/dummy

# run execution engine grpc server
$SRC/CasperLabs/execution-engine/target/release/casperlabs-engine-grpc-server -z -t 8 $HOME/.casperlabs/.casper-node.sock > /tmp/casper.txt&

nodef init testnode tendermint --chain-id testnet

# create a wallet key
PW="12345678"

expect -c "
set timeout 3
spawn clif keys add node
expect "disk:"
    send \"$PW\\r\"
expect "passphrase:"
    send \"$PW\\r\"
expect eof
"

# apply default clif configure
clif config chain-id testnet
clif config output json
clif config indent true
clif config trust-node true

cp -f $HOME/git/friday-cluster-test/instances/config/node-config/nodef-config/config/genesis.json $HOME/.nodef/config
cp -f $HOME/git/friday-cluster-test/instances/config/node-config/nodef-config/config/manifest.toml $HOME/.nodef/config

#SEED=$(cat $HOME/.nodef/config/genesis.json | jq .app_state.genutil.gentxs[0].value.memo)
SEED=$(cat seed-info.txt)
sed -i "s/seeds = \"\"/seeds = $SEED/g" $HOME/.nodef/config/config.toml
sed -i "s/prometheus = false/prometheus = true/g" $HOME/.nodef/config/config.toml
sed -i 's/log_level = "main:info,state:info,\*:error"/log_level = "main:info,state:info,\*:error,consensus:info"/g' ~/.nodef/config/config.toml
sed -i "s/prof_laddr = \"localhost:6060\"/prof_laddr = \"0.0.0.0:6060\"/g" $HOME/.nodef/config/config.toml

clif rest-server --laddr tcp://0.0.0.0:1317 > clif.txt 2>&1 &
nodef start > /tmp/nodef.txt 2>/dev/null &
