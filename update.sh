#!/usr/bin/env sh
# this script is used to update the docker image
 
VERSIONs=$(curl https://mikrotik.com/download/archive -s | awk -F ' ' '/Release/{gsub(/<\/b>/, "", $3);print $3}')

# loop through the versions
for VERSION in VERSIONs; do
    docker build -t ghibranalj/docker-routeros:$VERSION . --build-arg "ROUTEROS_VERSION=$VERSION"
    docker push ghibranalj/docker-routeros:$VERSION
done


# Get latest Version
LATEST=$(echo $VERSIONs | head -n 1)
# rename tag to latest
echo Renaming Version $LATEST to :latest
docker tag ghibranalj/docker-routeros:$LATEST ghibranalj/docker-routeros:latest

