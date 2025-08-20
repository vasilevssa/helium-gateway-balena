#!/bin/bash

echo "Testing gwmp-mux integration..."

# Test 1: Build all services
echo "=== Building services ==="
docker-compose build

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build successful"

# Test 2: Start services
echo "=== Starting services ==="
docker-compose up -d

if [ $? -ne 0 ]; then
    echo "❌ Services failed to start"
    exit 1
fi

echo "✅ Services started"

# Test 3: Check service health
echo "=== Checking service health ==="
sleep 10

# Check if all services are running
SERVICES=("gateway-service" "gwmp-mux" "packet-forwarder")
for service in "${SERVICES[@]}"; do
    if docker-compose ps | grep -q "$service.*Up"; then
        echo "✅ $service is running"
    else
        echo "❌ $service is not running"
        docker-compose logs "$service"
        exit 1
    fi
done

# Test 4: Check port connectivity
echo "=== Checking port connectivity ==="

# Check if gwmp-mux is listening on port 1700
if netstat -tuln | grep -q ":1700.*LISTEN\|:1700"; then
    echo "✅ gwmp-mux listening on port 1700"
else
    echo "❌ gwmp-mux not listening on port 1700"
fi

# Check if gateway-service is listening on port 1680
if netstat -tuln | grep -q ":1680.*LISTEN\|:1680"; then
    echo "✅ gateway-service listening on port 1680"
else
    echo "❌ gateway-service not listening on port 1680"
fi

echo "=== Integration test complete ==="
echo "To view logs:"
echo "  docker-compose logs gateway-service"
echo "  docker-compose logs gwmp-mux"  
echo "  docker-compose logs packet-forwarder"

echo ""
echo "To stop services:"
echo "  docker-compose down"
