#!/bin/bash

./make-seed.sh

host="localhost"
wallet_address="friday1lqu3uhce7kzys2unclj9dw6d9pduc0zpyt6l25fedw5vd89qgdsqwrexuw"
priv_key="e7bc16250c1228ccdd5a2440239b373ccf3747a52ab875e909cffd1ac1685b07"
PW="12345678"

nodef start > /tmp/nodef.txt &
sleep 10

expect -c "
set timeout 3
spawn clif hdac transfer-to $wallet_address 100000000 1 --from node
expect "N]:"
send \"y\\r\"
expect "\'node\':"
send \"$PW\\r\"
expect eof
"

clif rest-server --laddr tcp://0.0.0.0:1317 > clif.txt 2>&1 &
sleep 10

rm transfer-once-to-log.txt
./transfer-to-interval.py $host $priv_key > transfer-once-to-log.txt & 
