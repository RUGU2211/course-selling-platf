#!/bin/bash
set -e

echo "=========================================="
echo "Fixing API Gateway Routes"
echo "=========================================="

# 1. Pull latest changes
echo "Pulling latest changes..."
git pull origin master || git pull

# 2. Rebuild API Gateway with fixed configuration
echo "Rebuilding API Gateway..."
docker-compose build --no-cache api-gateway

# 3. Ensure Config Server is running and healthy
echo "Checking Config Server status..."
docker-compose ps config-server
if ! docker-compose ps config-server | grep -q "Up.*healthy"; then
    echo "Starting Config Server..."
    docker-compose up -d config-server
    echo "Waiting for Config Server to be healthy..."
    sleep 60
    docker-compose ps config-server
fi

# 4. Verify Config Server is serving routes
echo "Verifying Config Server routes..."
docker exec course-platform-config curl -s http://localhost:8888/api-gateway/docker | grep -i "gateway.routes" | head -5

# 5. Stop API Gateway
echo "Stopping API Gateway..."
docker-compose stop api-gateway

# 6. Remove old API Gateway container
echo "Removing old API Gateway container..."
docker-compose rm -f api-gateway

# 7. Start API Gateway (will fetch config from Config Server)
echo "Starting API Gateway..."
docker-compose up -d api-gateway

# 8. Wait for API Gateway to start
echo "Waiting for API Gateway to start and fetch config..."
sleep 60

# 9. Check if routes are loaded
echo "Checking if routes are loaded..."
docker logs course-platform-api-gateway --tail 50 | grep -i "routes count" | tail -5

# 10. Check API Gateway routes endpoint
echo "Checking API Gateway routes endpoint..."
docker exec course-platform-api-gateway curl -s http://localhost:8765/actuator/gateway/routes || echo "Routes endpoint not available yet"

# 11. Test routes
echo "Testing routes..."
echo "Testing user-management-service..."
curl -s http://localhost:8765/user-management-service/actuator/health || echo "Route not working"
echo ""
echo "Testing course-management-service..."
curl -s http://localhost:8765/course-management-service/actuator/health || echo "Route not working"

echo "=========================================="
echo "Fix complete!"
echo "=========================================="

