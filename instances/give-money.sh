#!/bin/bash

AMOUNT=100000000
FARE=1
PW="12345678"

while read line
do
    address=$line
    echo $address
    continue
    expect -c "
    set timeout 3
    spawn clif hdac transfer-to $address $AMOUNT $FARE --from node
    expect "N]:"
        send \"y\\r\"
    expect "\'node\':"
        send \"$PW\\r\"
    expect eof
    "
    sleep 20
done < address-info.txt
