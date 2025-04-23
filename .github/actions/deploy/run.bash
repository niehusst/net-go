#!/bin/bash

# setup SSH key auth
install -m 600 -D /dev/null ~/.ssh/id_ed25519
echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
echo "$SSH_KNOWN_HOSTS_B64" | base64 -d  > ~/.ssh/known_hosts

# run docker restart over ssh
ssh $SSH_USER@$SSH_HOST "echo '$AUTH_TOKEN' | docker login ghcr.io -u $DOCKER_USER --password-stdin && docker pull ghcr.io/niehusst/net-go:$TAG_NAME ; docker stop net_go ; docker rm net_go ; docker run -d --name net_go -p 8080:8080 -v netgo.gorm.db:/root ghcr.io/niehusst/net-go:$TAG_NAME && exit"

# cleanup
rm -rf ~/.ssh
