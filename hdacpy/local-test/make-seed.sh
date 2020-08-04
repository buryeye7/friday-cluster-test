#!/bin/bash

#if [ $# == 0 ]; then
#	echo "Please input node name"
#	exit 0 
#fi

#SRC="$HOME/go/src/github.com/hdac-io/friday"
SRC="$HOME/go/src/github.com/jhlee9623/friday"
rm -rf ~/.nodef/config
rm -rf ~/.nodef/data
rm -rf ~/.clif

tmp=$(ps -ef | grep grpc)
echo $tmp | while read line 
do 
	if [[ $line == *"CasperLabs"* ]];then
		target=$(echo $line |  awk -F' ' '{print $2}')
		kill -9 $target
	fi
done

tmp=$(ps -ef | grep nodef)
echo $tmp | while read line 
do 
	if [[ $line == *"nodef"* ]];then
		target=$(echo $line |  awk -F' ' '{print $2}')
		kill -9 $target
	fi
done

# run execution engine grpc server
$SRC/CasperLabs/execution-engine/target/release/casperlabs-engine-grpc-server -z -t 8 $HOME/.casperlabs/.casper-node.sock&

# init node
nodef init node tendermint --chain-id testnet

sed -i "s/prometheus = false/prometheus = true/g" ~/.nodef/config/config.toml
sed -i 's/log_level = "main:info,state:info,\*:error"/log_level = "main:info,state:info,\*:error,consensus:info"/g' ~/.nodef/config/config.toml

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

cp ~/.nodef/config/genesis.json ~/git/friday-test/settings
cp ~/.nodef/config/manifest.toml ~/git/friday-test/settings
cat  ~/.nodef/config/genesis.json | jq .app_state.genutil.gentxs[0].value.memo > ~/git/friday-test/settings/seed-address.txt
