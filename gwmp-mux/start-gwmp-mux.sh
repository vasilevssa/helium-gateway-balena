#!/bin/bash
set -e
echo "Starting gwmp-mux with packet logging"

echo "listening to packet-forwarder on port 1700"
echo "forwarding to gateway-service on port 1680"

# Start gwmp-mux with verbose logging and redirect output to log file
# The packet-logger service reads from this log file
exec /usr/local/bin/gwmp-mux \
    --host 1700 \
    --client 127.0.0.1:1680 