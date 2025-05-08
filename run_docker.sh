#!/usr/bin/env sh

IMG_NAME=netgo:latest

docker build --network=host \
  -t $IMG_NAME \
  --build-arg ENV_FILE=.env \
  . &&
docker compose up -d

# kill with:
# NETGO_IMAGE=netgo:latest docker compose down
