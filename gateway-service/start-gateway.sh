#!/bin/bash

echo "Starting start-gateway-service.sh"

# Ensure we're in a writable directory
cd /tmp

# Clean up any existing configuration files
rm -f settings.toml
rm -f /etc/helium_gateway/settings.toml
rm -f /etc/helium_gateway/gateway_key.bin

echo "Initializing GPIO for WM1302 with CORRECT pins..."

# Initialize SX1302 RESET pin (GPIO 17)
echo "17" > /sys/class/gpio/export 2>/dev/null || true
echo "out" > /sys/class/gpio/gpio17/direction
echo "1" > /sys/class/gpio/gpio17/value

# Initialize SX1302 POWER_EN pin (GPIO 18)  
echo "18" > /sys/class/gpio/export 2>/dev/null || true
echo "out" > /sys/class/gpio/gpio18/direction
echo "1" > /sys/class/gpio/gpio18/value

# Initialize SX1261 RESET pin (GPIO 5) - ЗА LBT/SPECTRAL SCAN!
echo "5" > /sys/class/gpio/export 2>/dev/null || true
echo "out" > /sys/class/gpio/gpio5/direction
echo "1" > /sys/class/gpio/gpio5/value

# Initialize AD5338R RESET pin (GPIO 13)
echo "13" > /sys/class/gpio/export 2>/dev/null || true
echo "out" > /sys/class/gpio/gpio13/direction
echo "1" > /sys/class/gpio/gpio13/value

# Reset sequence - правилно ресетване на всички компоненти
echo "Performing reset sequence..."
echo "0" > /sys/class/gpio/gpio17/value  # Reset SX1302
echo "0" > /sys/class/gpio/gpio5/value   # Reset SX1261
sleep 1
echo "1" > /sys/class/gpio/gpio17/value  # Release SX1302 reset
echo "1" > /sys/class/gpio/gpio5/value   # Release SX1261 reset
sleep 2

# Verify GPIO initialization
echo "GPIO Status:"
echo "GPIO 17 (SX1302_RESET): $(cat /sys/class/gpio/gpio17/value)"
echo "GPIO 18 (POWER_EN): $(cat /sys/class/gpio/gpio18/value)"
echo "GPIO 5 (SX1261_RESET): $(cat /sys/class/gpio/gpio5/value)"
echo "GPIO 13 (AD5338R_RESET): $(cat /sys/class/gpio/gpio13/value)"

# Small delay for GPIO stabilization
sleep 3

echo "Checking for I2C device"

mapfile -t data < <(i2cdetect -y 1)

ECC_CHIP_FOUND=false
for i in $(seq 1 ${#data[@]}); do
    # shellcheck disable=SC2206
    line=(${data[$i]})
    # shellcheck disable=SC2068
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