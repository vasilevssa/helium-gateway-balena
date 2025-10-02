#!/bin/sh
set -e

echo "Resetting WM1302..."

# Power enable SX1302
gpioset gpiochip0 18=1
sleep 0.1

# Reset SX1302
gpioset gpiochip0 17=0
sleep 0.1
gpioset gpiochip0 17=1

# Reset SX1261 (ако е наличен)
gpioset gpiochip0 5=0
sleep 0.1
gpioset gpiochip0 5=1

echo "WM1302 reset complete"
