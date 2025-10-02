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

# Extract helium_gateway binary from tar.gz
COPY artifacts/helium-gateway.tar.gz /tmp/
RUN tar -xzf /tmp/helium-gateway.tar.gz -C /usr/bin/ && \
    chmod 0755 /usr/bin/helium_gateway && \
    rm /tmp/helium-gateway.tar.gz

# Copy configuration files
COPY start-gateway.sh /opt/gateway/start-gateway.sh
COPY settings.toml.template /etc/helium_gateway/settings.toml.template

# Make script executable
RUN chmod +x /opt/gateway/start-gateway.sh

# Run the gateway
ENTRYPOINT ["/opt/gateway/start-gateway.sh"]