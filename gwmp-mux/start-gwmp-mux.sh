#!/bin/bash

set -e

echo "Starting gwmp-mux multiplexer..."

# Default configuration
GWMP_MUX_BIND=${GWMP_MUX_BIND:-"0.0.0.0:1700"}
GWMP_MUX_CONFIG=${GWMP_MUX_CONFIG:-"/etc/gwmp-mux/config.toml"}

# Create default config if it doesn't exist
if [ ! -f "$GWMP_MUX_CONFIG" ]; then
    echo "Creating gwmp-mux configuration from template at $GWMP_MUX_CONFIG"
    
    # Use template if available, otherwise create basic config
    if [ -f "/opt/config.toml.template" ]; then
        cp /opt/config.toml.template "$GWMP_MUX_CONFIG"
        # Replace bind address in template
        sed -i "s|bind = \"0.0.0.0:1700\"|bind = \"$GWMP_MUX_BIND\"|g" "$GWMP_MUX_CONFIG"
    else
        cat > "$GWMP_MUX_CONFIG" << EOF
# gwmp-mux configuration
[server]
bind = "$GWMP_MUX_BIND"

[[upstreams]]
name = "helium-gateway"
host = "gateway-service"
port = 1680
enabled = true

[log]
level = "info"
EOF
    fi
fi

echo "=== gwmp-mux Configuration ==="
echo "Bind Address: $GWMP_MUX_BIND"
echo "Config File: $GWMP_MUX_CONFIG"
echo "=============================="

echo "Configuration file contents:"
cat "$GWMP_MUX_CONFIG"

echo "Starting gwmp-mux..."

# Test network connectivity to gateway-service
echo "Testing connectivity to gateway-service..."
if nc -z gateway-service 1680; then
    echo "✓ Can reach gateway-service:1680"
else
    echo "✗ Cannot reach gateway-service:1680"
fi

# gwmp-mux typically looks for config.toml in current directory
# Copy config to working directory as config.toml
cp "$GWMP_MUX_CONFIG" /opt/config.toml
cd /opt

echo "Final config.toml contents:"
cat config.toml

echo "Starting gwmp-mux binary..."
exec /usr/local/bin/gwmp-mux
