#!/bin/bash

#if [ $# == 0 ]; then
#	echo "Please input node name"
#	exit 0 
#fi


SRC="$HOME/go/src/github.com/hdac-io/friday"
rm -rf ~/.nodef/config
rm -rf ~/.nodef/data
rm -rf ~/.clif

ps -ef | grep grpc > /tmp/dummy
while read line 
do 
	if [[ $line == *"grep"* ]];then
		continue
	fi
	if [[ $line == *"CasperLabs"* ]];then
		target=$(echo $line |  awk -F' ' '{print $2}')
		kill -9 $target
	fi
done < /tmp/dummy

ps -ef | grep nodef > /tmp/dummy
while read line 
do 
	if [[ $line == *"grep"* ]];then
		continue
	fi
	if [[ $line == *"nodef"* ]];then
		target=$(echo $line |  awk -F' ' '{print $2}')
		kill -9 $target
	fi
done < /tmp/dummy

ps -ef | grep clif > /tmp/dummy
while read line 
do 
	if [[ $line == *"grep"* ]];then
		continue
	fi
	if [[ $line == *"clif"* ]];then
		target=$(echo $line |  awk -F' ' '{print $2}')
		kill -9 $target
	fi
done < /tmp/dummy

# run execution engine grpc server
$SRC/CasperLabs/execution-engine/target/release/casperlabs-engine-grpc-server -z -t 8 $HOME/.casperlabs/.casper-node.sock > /tmp/casper.txt &

# init node
nodef init node tendermint --chain-id testnet

# copy execution engine chain configurations
cp $SRC/x/executionlayer/resources/manifest.toml ~/.nodef/config

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

for i in {1..100}
do
        expect -c "
        set timeout 3
        spawn clif keys add node$i
        expect "disk:"
                send \"$PW\\r\"
        expect "passphrase:"
                send \"$PW\\r\"
        expect eof
        "
done


nodef add-genesis-account $(clif keys show node -a) 100000000stake
nodef add-el-genesis-account node "2700000000000000000000000000" "1000000000000000000"

# add genesis node
nodef load-chainspec ~/.nodef/config/manifest.toml

# apply default clif configure
clif config chain-id testnet
clif config output json
clif config indent true
clif config trust-node true

sed -i "s/prometheus = false/prometheus = true/g" $HOME/.nodef/config/config.toml
sed -i 's/log_level = "main:info,state:info,\*:error"/log_level = "main:info,state:info,\*:error,consensus:info"/g' ~/.nodef/config/config.toml
sed -i "s/prof_laddr = \"localhost:6060\"/prof_laddr = \"0.0.0.0:6060\"/g" $HOME/.nodef/config/config.toml

# prepare genesis status
expect -c "
set timeout 3
spawn nodef gentx --name node 
expect "\'node\':"
	send \"$PW\\r\"
expect eof
"

nodef collect-gentxs
nodef validate-genesis

rm -rf /home/centos/git/friday-cluster-test/instances/config/node-config/nodef-config/*
rm -rf /home/centos/git/friday-cluster-test/instances/config/node-config/clif-config/*

cp -rf ~/.nodef/* /home/centos/git/friday-cluster-test/instances/config/node-config/nodef-config/
cp -rf ~/.clif/* /home/centos/git/friday-cluster-test/instances/config/node-config/clif-config/

clif rest-server --laddr tcp://0.0.0.0:1317 2>&1 > /tmp/clif.txt &
nodef start > /tmp/nodef.txt 2>/dev/null &

#cp ~/.nodef/config/genesis.json ~/git/friday-test/settings
#cp ~/.nodef/config/manifest.toml ~/git/friday-test/settings
#cat  ~/.nodef/config/genesis.json | jq .app_state.genutil.gentxs[0].value.memo > ~/git/friday-test/settings/seed-address.txt
