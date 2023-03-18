#!/usr/bin/env sh

# should probs update to not name docker img as test
docker build -t test:latest .
docker run -dp 8080:8080 test:latest
