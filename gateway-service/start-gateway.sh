#!/bin/sh
set -e

echo "Resetting WM1302 with correct GPIO pins..."

# Power enable - CORRECT PIN from WM1302 docs
gpioset gpiochip0 11=1
sleep 0.2

# Reset SX1302 - CORRECT PIN from WM1302 docs  
gpioset gpiochip0 22=0
sleep 0.1
gpioset gpiochip0 22=1
sleep 0.2

# Reset SX1261 (ако е наличен)
gpioset gpiochip0 5=0
sleep 0.1
gpioset gpiochip0 5=1

echo "WM1302 reset complete"

# Start the actual gateway
exec /usr/bin/helium_gateway server