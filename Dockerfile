FROM alpine:3.11

# For access via VNC
EXPOSE 5900

# Expose Ports of RouterOiS
EXPOSE 1194 1701 1723 1812/udp 1813/udp 21 22 23 443 4500/udp 50 500/udp 51 2021 2022 2023 2027 5900 80 8080 8291 8728 8729 8900

# Change work dir (it will also create this folder if is not exist)
WORKDIR /routeros

# Install dependencies
RUN set -xe \
 && apk add --no-cache --update \
    netcat-openbsd qemu-x86_64 qemu-system-x86_64 \
    busybox-extras iproute2 iputils \
    bridge-utils iptables jq bash python3 unzip\
    dnsmasq ipcalc

#get version from argument or use default
ARG VERSION
ENV ROUTEROS_VERSION=$VERSION
# Environments which may be change
ENV ROUTEROS_IMAGE="chr-$ROUTEROS_VERSION.img"
ENV ROUTEROS_PATH="https://download.mikrotik.com/routeros/$ROUTEROS_VERSION/$ROUTEROS_IMAGE.zip"

# Download VDI image from remote site
RUN wget "$ROUTEROS_PATH" -O "/routeros/$ROUTEROS_IMAGE.zip"

# Unzip image
RUN unzip "/routeros/$ROUTEROS_IMAGE.zip" -d "/routeros"

# Copy script to routeros folder
ADD ["./scripts", "/routeros"]

ENTRYPOINT ["/routeros/entrypoint.sh"]
