FROM balenalib/raspberrypi4-64-debian:bookworm-run

# Set timezone
ARG SYSTEM_TIMEZONE=UTC
ENV TZ=$SYSTEM_TIMEZONE

# Install dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" \
    apt-get -y install \
    ca-certificates \
    i2c-tools \
    spi-tools \
    curl \
    gpiod \
    --no-install-recommends && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install helium gateway binary
COPY artifacts/helium_gateway /usr/bin/helium_gateway
RUN chmod 0755 /usr/bin/helium_gateway

# Copy configuration files
COPY start-gateway.sh /opt/gateway/start-gateway.sh
COPY settings.toml.template /etc/helium_gateway/settings.toml.template

# Make script executable
RUN chmod +x /opt/gateway/start-gateway.sh

# Run the gateway
ENTRYPOINT ["/opt/gateway/start-gateway.sh"]