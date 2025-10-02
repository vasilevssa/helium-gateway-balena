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
    gpiod libgpiod-dev \
    --no-install-recommends && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install helium gateway binary
COPY artifacts/helium_gateway /usr/bin/helium_gateway

# Copy configuration files
COPY start-gateway.sh /opt/gateway/start-gateway.sh
COPY settings.toml.template /etc/helium_gateway/settings.toml.template

# Add reset script
COPY gateway-service/reset_wm1302.sh /usr/local/bin/reset_wm1302.sh

# Make binaries and scripts executable & verify template is clean
RUN chmod +x /usr/bin/helium_gateway /usr/local/bin/reset_wm1302.sh /opt/gateway/start-gateway.sh && \
    if grep -q "^keypair = " /etc/helium_gateway/settings.toml.template; then \
        echo "ERROR: Template still contains keypair entries!" && \
        grep "^keypair = " /etc/helium_gateway/settings.toml.template && \
        exit 1; \
    fi && \
    echo "Template verified clean at $(date)" > /tmp/build_timestamp

# Run the gateway (reset WM1302 before start)
ENTRYPOINT ["/bin/sh", "-c", "/usr/local/bin/reset_wm1302.sh && /opt/gateway/start-gateway.sh"]
