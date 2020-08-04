#!/bin/bash

ps -ef | grep transfer > /tmp/dummy.txt
while read line
do
    echo $line
    if [[ $line == *"auto"* ]];then
        process=$(echo $line | awk -F' ' '{print $2}')
        kill -9 $process
    fi
done < /tmp/dummy.txt

