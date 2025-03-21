#!/usr/bin/env sh

docker build -t netgo:latest .
docker run -dp 8080:8080 netgo:latest
