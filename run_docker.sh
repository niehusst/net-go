#!/usr/bin/env sh

docker build --network=host \
  -t netgo:latest \
  --build-arg ENV_FILE=.env \
  .
docker run -d \
  --name net_go \
  -p 8080:8080 \
  -v netgo.gorm.db:/root \
  netgo:latest

# kill with:
# docker stop net_go
# docker rm net_go
