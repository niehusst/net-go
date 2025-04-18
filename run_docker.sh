#!/usr/bin/env sh

docker build --network=host -t netgo:latest .
docker run --name net_go -dp 8080:8080 netgo:latest 
