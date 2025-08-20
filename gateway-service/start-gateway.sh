#!/bin/bash

echo "Starting start-gateway-service.sh"

# Clean up any existing configuration files
rm -f settings.toml
rm -f /etc/helium_gateway/settings.toml
rm -f /etc/helium_gateway/gateway_key.bin

echo "Checking for I2C device"

mapfile -t data < <(i2cdetect -y 1)

for i in $(seq 1 ${#data[@]}); do
    # shellcheck disable=SC2206
    line=(${data[$i]})
    # shellcheck disable=SC2068
    if echo ${line[@]:1} | grep -q 60; then
        echo "ECC is present."
        ECC_CHIP=True
    else
        echo "ECC is not present."
    fi
done

echo "Interacting with ECC_CHIP"
if [[ -v ECC_CHIP ]]
then
  echo "Using ECC for public key."
  if [[ -v GW_KEYPAIR ]]
  then
    echo 'keypair = "'${GW_KEYPAIR}'"' >> settings.toml
  else
    echo 'keypair = "ecc://i2c-1:96?slot=0"' >> settings.toml
  fi
else
  echo "Key file already exists"
  echo 'keypair = "/var/data/gateway_key.bin"' >> settings.toml
fi

echo "Appending template configuration..."
cat /etc/helium_gateway/settings.toml.template >> settings.toml

echo "Final settings.toml content:"
cat settings.toml

echo "Copying to final location..."
cp settings.toml /etc/helium_gateway/settings.toml

echo "Calling helium_gateway server ..."
/usr/bin/helium_gateway -c /etc/helium_gateway/settings.toml server

echo "Starting helium_gateway server..."
exec /usr/bin/helium_gateway -c /etc/helium_gateway/settings.toml server