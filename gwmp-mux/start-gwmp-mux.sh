#!/bin/bash
set -e
echo "Starting gwmp-mux with packet logging"

echo "listening to packet-forwarder on port 1700"
echo "forwarding to gateway-service on port 1680"

# Start gwmp-mux
exec /usr/local/bin/gwmp-mux 0.0.0.0:1700 127.0.0.1:1680