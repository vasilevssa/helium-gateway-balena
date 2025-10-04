#!/bin/bash

echo "Starting start-gateway-service.sh with libgpiod"

# Ensure we're in a writable directory
cd /tmp

# Clean up any existing configuration files
rm -f settings.toml
rm -f /etc/helium_gateway/settings.toml
rm -f /etc/helium_gateway/gateway_key.bin

echo "Initializing GPIO for WM1302 using libgpiod..."

# Check available GPIO chips
echo "Available GPIO chips:"
gpiodetect

# Initialize GPIO using libgpiod
echo "Initializing GPIO pins with libgpiod..."
gpioset -m time -s 100 0 17=1   # SX1302_RESET = HIGH
gpioset -m time -s 100 0 18=1   # POWER_EN = HIGH  
gpioset -m time -s 100 0 5=1    # SX1261_RESET = HIGH

# OFFICIAL WM1302 RESET SEQUENCE using libgpiod
echo "Performing OFFICIAL WM1302 reset sequence with libgpiod..."

# 1. Power ON
gpioset 0 18=1
echo "Power enabled - waiting 100ms"
sleep 0.1

# 2. SX1302 Reset (активен LOW)
gpioset 0 17=0
sleep 0.1
gpioset 0 17=1
echo "SX1302 reset released - waiting 100ms"
sleep 0.1

# 3. SX1261 Reset (активен LOW)
gpioset 0 5=0
sleep 0.1
gpioset 0 5=1
echo "SX1261 reset released - waiting 2 seconds"
sleep 2

echo "GPIO initialization complete"

echo "Checking for I2C device"

mapfile -t data < <(i2cdetect -y 1)

ECC_CHIP_FOUND=false
for i in $(seq 1 ${#data[@]}); do
    line=(${data[$i]})
    if echo ${line[@]:1} | grep -q 60; then
        echo "✓ ECC chip found at address 0x60"
        ECC_CHIP_FOUND=true
        ECC_CHIP=True
        break
    fi
done

if [ "$ECC_CHIP_FOUND" = false ]; then
    echo "✗ No ECC chip detected on I2C bus"
fi

echo "Generating settings.toml..."

# Generate settings.toml from template
if [[ -v ECC_CHIP ]]; then
  echo "Using ECC for public key."
  if [[ -v GW_KEYPAIR ]]; then
    echo "Writing custom keypair: ${GW_KEYPAIR}"
    echo 'keypair = "'${GW_KEYPAIR}'"' > settings.toml
  else
    echo "Writing ECC keypair: ecc://i2c-1:96?slot=0"
    echo 'keypair = "ecc://i2c-1:96?slot=0"' > settings.toml
    echo 'onboarding = "ecc://i2c-1:96?slot=15"' >> settings.toml
  fi
else
  echo "Using file-based keypair"
  echo 'keypair = "/var/data/gateway_key.bin"' > settings.toml
fi

# Add region configuration
if [[ -v GW_REGION ]]; then
    echo "region = \"$GW_REGION\"" >> settings.toml
else
    echo 'region = "EU868"' >> settings.toml
fi

# Add other essential settings
cat >> settings.toml << EOF

listen = "0.0.0.0:1680"
api = 4467

[log]
level = "info"
timestamp = true

[poc]
entropy_uri = "http://entropy.iot.mainnet.helium.io:7080"
ingest_uri = "http://mainnet-pociot.helium.io:9080"

[config]
pubkey = "137oJzq1qZpSbzHawaysTGGsRCYTXG1MiTMQNxYSsQJp4YMDdN8"
uri = "http://mainnet-config.helium.io:6080/"

[router]
uri = "http://mainnet-router.helium.io:8080/"
queue = 20
EOF

# Copy final settings to destination
cp settings.toml /etc/helium_gateway/settings.toml

echo "Starting helium_gateway server..."
exec helium_gateway server