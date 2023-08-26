#!/usr/bin/env sh
# this script is used to update the docker image
 
LATEST_VERSION=$(curl https://mikrotik.com/download/archive -s | grep Release -m 1 | grep -oP '(?<=<b>Release )\d+\.\d+')

echo "Latest version is $LATEST_VERSION"

docker build -t ghibranalj/docker-routeros:$LATEST_VERSION . --build-arg "ROUTEROS_VERSION=$LATEST_VERSION"

docker push ghibranalj/docker-routeros:$LATEST_VERSION

docker tag ghibranalj/docker-routeros:$LATEST_VERSION ghibranalj/docker-routeros:latest

docker push ghibranalj/docker-routeros:latest
