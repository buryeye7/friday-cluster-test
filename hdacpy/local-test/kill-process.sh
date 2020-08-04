#!/bin/bash

ps -ef | grep nodef > /tmp/dummy.txt
while read line 
do 
	if [[ $line != *"grep"* ]];then
		ps=$(echo $line | awk -F' ' '{print $2}')
		kill -9 $ps
	fi
done < /tmp/dummy.txt

ps -ef | grep casper > /tmp/dummy.txt
while read line
do
        if [[ $line != *"grep"* ]];then
                ps=$(echo $line | awk -F' ' '{print $2}')
                kill -9 $ps
        fi
done < /tmp/dummy.txt


