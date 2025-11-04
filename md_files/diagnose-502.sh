#!/bin/bash
# Diagnose 502 Bad Gateway Error
# This script checks why frontend can't reach API Gateway

echo "=========================================="
echo "Diagnosing 502 Bad Gateway Error"
echo "=========================================="
echo ""

# Check if containers are running
echo "1. Checking container status..."
docker ps --filter "name=course-platform" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Check API Gateway specifically
echo "2. Checking API Gateway container..."
if docker ps --filter "name=api-gateway" --format "{{.Names}}" | grep -q api-gateway; then
    echo "✅ API Gateway container is running"
    API_STATUS=$(docker inspect course-platform-api-gateway --format='{{.State.Status}}')
    API_HEALTH=$(docker inspect course-platform-api-gateway --format='{{.State.Health.Status}}' 2>/dev/null || echo "no-healthcheck")
    echo "   Status: ${API_STATUS}"
    echo "   Health: ${API_HEALTH}"
else
    echo "❌ API Gateway container is NOT running!"
    echo "   Starting API Gateway..."
    docker compose up -d api-gateway || echo "   Failed to start API Gateway"
fi
echo ""

# Check frontend container
echo "3. Checking Frontend container..."
if docker ps --filter "name=frontend" --format "{{.Names}}" | grep -q frontend; then
    echo "✅ Frontend container is running"
else
    echo "❌ Frontend container is NOT running!"
fi
echo ""

# Test network connectivity from frontend to API Gateway
echo "4. Testing network connectivity..."
echo "   Testing from frontend to API Gateway..."
docker exec course-platform-frontend ping -c 2 course-platform-api-gateway 2>/dev/null && \
    echo "✅ Network connectivity OK" || \
    echo "❌ Cannot reach API Gateway from frontend container"
echo ""

# Check API Gateway health
echo "5. Checking API Gateway health endpoint..."
API_GATEWAY_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' course-platform-api-gateway 2>/dev/null)
if [ -n "$API_GATEWAY_IP" ]; then
    echo "   API Gateway IP: ${API_GATEWAY_IP}"
    echo "   Testing health endpoint from frontend..."
    docker exec course-platform-frontend curl -s http://course-platform-api-gateway:8765/actuator/health && \
        echo -e "\n✅ API Gateway health endpoint is accessible" || \
        echo "❌ Cannot access API Gateway health endpoint"
else
    echo "❌ Cannot get API Gateway IP"
fi
echo ""

# Check API Gateway logs
echo "6. Recent API Gateway logs (last 20 lines):"
echo "----------------------------------------"
docker logs course-platform-api-gateway --tail 20 2>/dev/null || echo "Cannot access API Gateway logs"
echo ""

# Check frontend nginx logs
echo "7. Recent Frontend nginx error logs:"
echo "----------------------------------------"
docker exec course-platform-frontend tail -20 /var/log/nginx/error.log 2>/dev/null || echo "Cannot access nginx error logs"
echo ""

# Check if services are on same network
echo "8. Checking Docker networks..."
echo "   API Gateway network:"
docker inspect course-platform-api-gateway --format='{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{end}}' 2>/dev/null
echo "   Frontend network:"
docker inspect course-platform-frontend --format='{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{end}}' 2>/dev/null
echo ""

# Test API Gateway directly (from host)
echo "9. Testing API Gateway directly from host..."
curl -s http://localhost:8765/actuator/health && \
    echo -e "\n✅ API Gateway is accessible from host" || \
    echo "❌ API Gateway is NOT accessible from host"
echo ""

# Summary and recommendations
echo "=========================================="
echo "Summary & Recommendations:"
echo "=========================================="

if ! docker ps --filter "name=api-gateway" --format "{{.Names}}" | grep -q api-gateway; then
    echo "❌ API Gateway is not running"
    echo "   Fix: docker compose up -d api-gateway"
elif ! curl -s http://localhost:8765/actuator/health > /dev/null 2>&1; then
    echo "❌ API Gateway is running but not healthy"
    echo "   Check logs: docker logs course-platform-api-gateway"
    echo "   Wait for it to be healthy: docker compose ps api-gateway"
else
    echo "✅ API Gateway appears to be healthy"
    echo "   If 502 errors persist, check:"
    echo "   - Network connectivity between containers"
    echo "   - nginx configuration"
    echo "   - DNS resolution in Docker network"
fi

echo ""
echo "To fix:"
echo "1. Restart API Gateway: docker compose restart api-gateway"
echo "2. Check all dependencies: docker compose ps"
echo "3. Restart frontend: docker compose restart frontend"
echo "4. Check logs: docker compose logs api-gateway"
echo "=========================================="

