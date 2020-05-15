#!/bin/bash

if [ $# == 0 ];then
    echo "Please hdac node number"
    exit 0
fi

COUCHDB="http://admin:admin@13.125.228.37:5984"
FILE_NO=$(ls -l hdac-node-descs | grep ^- | wc -l)
NODE_NO=$1

for i in $(seq 1 $FILE_NO)
do
    kubectl delete -f ./hdac-node-descs/hdac-node$i.yaml
done

#delete couchDB
curl -X DELETE $COUCHDB/seed-info
curl -X DELETE $COUCHDB/wallet-address

#create couchDB
curl -X PUT $COUCHDB/seed-info
curl -X PUT $COUCHDB/wallet-address

kubectl delete -f prometheus/prometheus.yaml
kubectl delete -f grafana/grafana.yaml
kubectl delete -f ./hdac-seed-desc/hdac-seed.yaml

kubectl apply -f ./hdac-seed-desc/hdac-seed.yaml
while true
do
    res=$(kubectl get pods) 
    if [[ "${res}" == *"hdac-seed"*"Running"* ]];then
        break
    fi
done

for i in $(seq 1 $NODE_NO)
do
    kubectl apply -f ./hdac-node-descs/hdac-node$i.yaml
done

while true
do
    res=$(kubectl get pods | wc -l) 
    res=$((res - 2))
    echo $res
    if [ $res -eq $NODE_NO ];then
        break
    fi
    sleep 1
done

cd prometheus
./make-prometheus-config.sh
cd ..

kubectl delete configmap prometheus-kubernetes
kubectl create configmap prometheus-kubernetes --from-file=./prometheus/prometheus-kubernetes-config.yaml

kubectl apply -f prometheus/prometheus.yaml
kubectl apply -f grafana/grafana.yaml

