#!/bin/bash
# FIX 404 ERRORS - Complete Fix Script
# Run this on EC2 to fix all 404 errors

set -e

echo "=========================================="
echo "FIXING 404 ERRORS - Complete Fix"
echo "=========================================="
echo ""

# Step 1: Stop all services
echo "1. Stopping all services..."
docker compose down

# Step 2: Rebuild config-server with native configuration
echo "2. Rebuilding config-server with native configuration..."
docker compose build config-server

# Step 3: Rebuild API Gateway without hardcoded routes
echo "3. Rebuilding API Gateway..."
docker compose build api-gateway

# Step 4: Start services in correct order
echo "4. Starting services..."
docker compose up -d mysql eureka-server

# Step 5: Wait for Eureka to be healthy
echo "5. Waiting for Eureka to be healthy..."
timeout 180 bash -c 'until docker compose ps eureka-server | grep -q healthy; do sleep 2; done' || echo "Eureka took longer than expected"

# Step 6: Start config-server
echo "6. Starting config-server..."
docker compose up -d config-server

# Step 7: Wait for config-server to be healthy
echo "7. Waiting for config-server to be healthy (this may take 2-3 minutes)..."
timeout 300 bash -c 'until docker compose ps config-server | grep -q healthy; do sleep 5; done' || echo "Config server took longer than expected"

# Step 8: Verify config-server is serving config
echo "8. Verifying config-server is serving config..."
sleep 10
if curl -s http://localhost:8888/api-gateway/default | grep -q "gateway"; then
    echo "✅ Config server is serving config"
else
    echo "⚠️  Config server might not be serving config correctly"
    echo "   Check logs: docker logs course-platform-config"
fi

# Step 9: Start all microservices
echo "9. Starting all microservices..."
docker compose up -d user-service course-service enrollment-service content-service actuator

# Step 10: Wait for services to register in Eureka
echo "10. Waiting for services to register in Eureka..."
sleep 30

# Step 11: Start API Gateway
echo "11. Starting API Gateway..."
docker compose up -d api-gateway

# Step 12: Wait for API Gateway to be healthy
echo "12. Waiting for API Gateway to be healthy (this may take 2-3 minutes)..."
timeout 300 bash -c 'until docker compose ps api-gateway | grep -q healthy; do sleep 5; done' || echo "API Gateway took longer than expected"

# Step 13: Check if routes are loaded
echo "13. Checking if routes are loaded..."
sleep 10
if curl -s http://localhost:8765/actuator/gateway/routes | grep -q "course-management-service"; then
    echo "✅ Routes are loaded!"
else
    echo "❌ Routes are NOT loaded"
    echo "   Check API Gateway logs: docker logs course-platform-api-gateway | grep -i route"
    echo "   Check config server: curl http://localhost:8888/api-gateway/default"
fi

# Step 14: Start frontend
echo "14. Starting frontend..."
docker compose up -d frontend

# Step 15: Wait for frontend to be healthy
echo "15. Waiting for frontend to be healthy..."
sleep 30

# Step 16: Test routes
echo "16. Testing routes..."
echo ""
echo "Testing course-management-service..."
curl -s http://localhost:8765/course-management-service/api/courses | head -c 200 || echo "❌ Failed"
echo ""

echo "Testing user-management-service..."
curl -s http://localhost:8765/user-management-service/api/users/stats | head -c 200 || echo "❌ Failed"
echo ""

# Step 17: Show status
echo "17. Final status:"
echo "=========================================="
docker compose ps
echo "=========================================="

echo ""
echo "✅ Fix complete!"
echo ""
echo "If routes still don't work, check:"
echo "1. Config server logs: docker logs course-platform-config"
echo "2. API Gateway logs: docker logs course-platform-api-gateway"
echo "3. Test config server: curl http://localhost:8888/api-gateway/default"
echo "4. Test API Gateway routes: curl http://localhost:8765/actuator/gateway/routes"
echo ""

