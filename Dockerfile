FROM alpine:latest

RUN apk add --no-cache \
    python3 \
    py3-pip \
    bash \
    curl \
    ca-certificates \
    ffmpeg \
    imagemagick \
    && rm -rf /var/cache/apk/*

# Install cloudflared
RUN curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared \
    && chmod +x /usr/local/bin/cloudflared

# Use an ARG to accept a version from the --build-arg flag
# It defaults to an empty string, causing pip to install the latest version.
ARG COPYPARTY_VERSION=""

# Install copyparty, appending the specific version only if ARG is set
RUN pip3 install --break-system-packages copyparty${COPYPARTY_VERSION:+"==$COPYPARTY_VERSION"}

# Create app directory
WORKDIR /app

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENTRYPOINT ["/app/start.sh"]
