#!/usr/bin/env sh
# this script is used to update the docker image
 
LATEST_VERSION=$(curl https://mikrotik.com/download/archive -s | grep Release -m 1 | grep -oP '(?<=<b>Release )\d+\.\d+')

echo "Latest version is $LATEST_VERSION"
sed -r "s/(ROUTEROS_VERSON=\")(.*)(\")/\1$LATEST_VERSION\3/g" -i Dockerfile


docker build -t ghibranalj/docker-routeros:$LATEST_VERSION .

docker push ghibranalj/docker-routeros:$LATEST_VERSION
