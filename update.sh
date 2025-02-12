#!/usr/bin/env sh
# this script is used to update the docker image
 
VERSIONs=$(curl  -s https://mikrotik.com/download/archive | awk -F'<strong>|</strong>' '/<strong>/ {print $2}' | sort -Vr)
LATEST=$(curl  -s https://mikrotik.com/download/archive | awk -F'<strong>|</strong>' '/<strong>/ {print $2}' | sort -Vr | head -n 1)
# loop through the versions
for V in $VERSIONs; do
    cat <<EOF
=============
Building Version: $V
=============
EOF
    docker build -t ghibranalj/docker-routeros:$V  --build-arg VERSION="$V" . || exit 1

    cat <<EOF
=============
Pushing Version: $V
=============
EOF
    docker push ghibranalj/docker-routeros:$V || exit 1
done

    cat <<EOF
=============
Latest Version: $LATEST
=============
EOF
docker tag ghibranalj/docker-routeros:$LATEST ghibranalj/docker-routeros:latest || exit 1
docker push ghibranalj/docker-routeros:latest || exit 1
