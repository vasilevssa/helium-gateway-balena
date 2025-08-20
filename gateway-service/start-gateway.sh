#!/bin/bash

echo "Starting start-gateway-service.sh"

# Ensure we're in a writable directory
cd /tmp

# Clean up any existing configuration files
rm -f settings.toml
rm -f /etc/helium_gateway/settings.toml
rm -f /etc/helium_gateway/gateway_key.bin

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

echo "Interacting with ECC_CHIP"
if [[ -v ECC_CHIP ]]
then
  echo "Using ECC for public key."
  if [[ -v GW_KEYPAIR ]]
  then
    echo "Writing custom keypair: ${GW_KEYPAIR}"
    echo 'keypair = "'${GW_KEYPAIR}'"' > settings.toml
  else
    echo "Writing ECC keypair: ecc://i2c-1:96?slot=0"
    echo 'keypair = "ecc://i2c-1:96?slot=0"' > settings.toml
  fi
else
  echo "Using file-based keypair"
  echo 'keypair = "/var/data/gateway_key.bin"' > settings.toml
fi

echo "Verifying keypair was written:"
if [ -f settings.toml ]; then
    echo "✓ settings.toml exists, contents:"
    cat settings.toml
else
    echo "✗ ERROR: settings.toml was not created!"
fi

echo "Appending template configuration..."
cat /etc/helium_gateway/settings.toml.template >> settings.toml

echo "Final settings.toml content:"
echo "=========================="
cat settings.toml
echo "=========================="

echo "Copying to final location..."
cp settings.toml /etc/helium_gateway/settings.toml

echo "Verifying final config file:"
echo "Checking for keypair line:"
if grep -q "^keypair" /etc/helium_gateway/settings.toml; then
    echo "✓ Keypair configuration found:"
    grep "^keypair" /etc/helium_gateway/settings.toml
else
    echo "✗ ERROR: No keypair line found in final config!"
fi

echo "Calling helium_gateway server ..."
/usr/bin/helium_gateway -c /etc/helium_gateway/settings.toml server

echo "Starting helium_gateway server..."
exec /usr/bin/helium_gateway -c /etc/helium_gateway/settings.toml server