#!/usr/bin/env sh
# this script is used to update the docker image
 
VERSIONs=$(curl https://mikrotik.com/download/archive -s | awk -F ' ' '/Release/{gsub(/<\/b>/, "", $3);print $3}' | tac)
LATEST=$(curl https://mikrotik.com/download/archive -s | awk -F ' ' '/Release/{gsub(/<\/b>/, "", $3);print $3}' | head -n 1)
# loop through the versions
for VERSION in $VERSIONs; do
    cat <<EOF
=============
Building Version: $VERSION
=============
EOF
    docker build -t ghibranalj/docker-routeros:$VERSION . --build-arg "ROUTEROS_VERSION=$VERSION"
    docker push ghibranalj/docker-routeros:$VERSION
done

    cat <<EOF
=============
Latest Version: $LATEST
=============
EOF
docker tag ghibranalj/docker-routeros:$LATEST ghibranalj/docker-routeros:latest
docker push ghibranalj/docker-routeros:latest
