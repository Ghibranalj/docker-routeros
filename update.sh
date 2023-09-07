#!/usr/bin/env sh
# this script is used to update the docker image
 
VERSIONs=$(curl https://mikrotik.com/download/archive -s | awk -F ' ' '/Release/{gsub(/<\/b>/, "", $3);print $3}' | tac)
LATEST=$(curl https://mikrotik.com/download/archive -s | awk -F ' ' '/Release/{gsub(/<\/b>/, "", $3);print $3}' | head -n 1)
# loop through the versions
for V in $VERSIONs; do
    cat <<EOF
=============
Building Version: $V
=============
EOF
    docker build -t ghibranalj/docker-routeros:$V  --build-arg VERSION="$V" .

    cat <<EOF
=============
Pushing Version: $V
=============
EOF
    docker push ghibranalj/docker-routeros:$V

    exit
done

    cat <<EOF
=============
Latest Version: $LATEST
=============
EOF
docker tag ghibranalj/docker-routeros:$LATEST ghibranalj/docker-routeros:latest
docker push ghibranalj/docker-routeros:latest
