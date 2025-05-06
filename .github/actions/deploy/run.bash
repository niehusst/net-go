#!/bin/bash

# setup SSH key auth
install -m 600 -D /dev/null ~/.ssh/id_ed25519
echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
echo "$SSH_KNOWN_HOSTS_B64" | base64 -d  > ~/.ssh/known_hosts

# run docker restart over ssh
IMAGE_NAME="ghcr.io/niehusst/net-go"
CONTAINER_NAME="net_go"
ssh $SSH_USER@$SSH_HOST "echo '$AUTH_TOKEN' | docker login ghcr.io -u $DOCKER_USER --password-stdin && 
docker stop $CONTAINER_NAME && 
docker rm $CONTAINER_NAME && 
docker image prune -af && 
docker pull $IMAGE_NAME:$TAG_NAME && 
docker run -d --name $CONTAINER_NAME -p 8080:8080 -v netgo_db:/root $IMAGE_NAME:$TAG_NAME && 
exit"

# cleanup
rm -rf ~/.ssh
