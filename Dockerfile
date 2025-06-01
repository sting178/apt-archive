FROM ubuntu:22.04

RUN apt update && \
    apt install -y wget curl gnupg jq dpkg-dev apt-utils tar && \
    wget https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_linux_amd64 -O /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

RUN apt install -y ca-certificates libnss3-tools nginx && \
    curl -sJLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64" && \
    chmod +x mkcert-v*-linux-amd64 && \
    cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert

RUN mkcert -install && \
    mkdir -p /etc/nginx/certs && \
    cd /etc/nginx/certs && \
    mkcert localhost
