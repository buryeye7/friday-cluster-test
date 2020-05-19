#!/bin/bash

cd hdac-seed
docker build --no-cache --tag buryeye7/hdac-seed:latest .
docker push buryeye7/hdac-seed:latest

cd ..
cd hdac-node
docker build --no-cache --tag buryeye7/hdac-node:latest .
docker push buryeye7/hdac-node:latest

