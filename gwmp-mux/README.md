# gwmp-mux Integration

This directory contains the gwmp-mux service integration for multiplexing LoRa packets from the RAK2287 packet forwarder to multiple upstream servers.

## Architecture

The gwmp-mux service sits between the packet forwarder and gateway services:

```
LoRa Devices → RAK2287 → packet-forwarder → gwmp-mux → gateway-service + other LNS
```

## Configuration

The gwmp-mux service can be configured through:

1. **Environment Variables** (in docker-compose.yml):
   - `GWMP_MUX_BIND`: Address to bind the GWMP server (default: "0.0.0.0:1700")

2. **Configuration File** (`/etc/gwmp-mux/config.toml`):
   - Automatically generated from template if not present
   - Can be customized by mounting a volume with your own config

## Adding Additional Upstream Servers

To forward packets to multiple LoRaWAN Network Servers, edit the configuration file:

```toml
# Add more upstream servers
[[upstreams]]
name = "ttn"
host = "eu1.cloud.thethings.network"
port = 1700
enabled = true

[[upstreams]]
name = "chirpstack"
host = "your-chirpstack.example.com"
port = 1700
enabled = true
```

## Ports

- **1700/udp**: Receives packets from packet forwarder
- **1680**: Forwards packets to gateway-service (internal)

## Logs

Monitor gwmp-mux logs through Balena Cloud or docker-compose:
```bash
docker-compose logs gwmp-mux
```
