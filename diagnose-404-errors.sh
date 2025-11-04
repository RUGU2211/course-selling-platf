#!/bin/bash
set -e

echo "=========================================="
echo "Diagnosing 404 Errors"
echo "=========================================="

# 1. Check if services are running
echo "1. Checking Docker containers..."
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "NAME|course-platform"

# 2. Check API Gateway health
echo ""
echo "2. Checking API Gateway health..."
curl -s http://localhost:8765/actuator/health || echo "⚠ API Gateway not accessible on port 8765"

# 3. Check if services are registered in Eureka
echo ""
echo "3. Checking Eureka service registry..."
curl -s http://localhost:8761/eureka/apps | grep -E "name|status" | head -20 || echo "⚠ Eureka not accessible"

# 4. Test API Gateway routes
echo ""
echo "4. Testing API Gateway routes..."
echo "Testing user-management-service route..."
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8765/user-management-service/actuator/health || echo "⚠ Route not working"

echo "Testing course-management-service route..."
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8765/course-management-service/actuator/health || echo "⚠ Route not working"

# 5. Check service health directly
echo ""
echo "5. Checking service health directly..."
echo "User Service:"
curl -s http://localhost:8082/user-management-service/actuator/health || echo "⚠ User service not accessible"

echo "Course Service:"
curl -s http://localhost:8083/course-management-service/actuator/health || echo "⚠ Course service not accessible"

# 6. Check frontend nginx proxy
echo ""
echo "6. Testing frontend proxy..."
echo "Via frontend proxy (port 3000):"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:3000/user-management-service/actuator/health || echo "⚠ Frontend proxy not working"

# 7. Check API Gateway routes configuration
echo ""
echo "7. Checking API Gateway routes..."
curl -s http://localhost:8765/actuator/gateway/routes | grep -E "uri|predicate" | head -20 || echo "⚠ Routes not accessible"

# 8. Network connectivity check
echo ""
echo "8. Testing network connectivity from frontend to API Gateway..."
docker exec course-platform-frontend curl -s http://course-platform-api-gateway:8765/actuator/health || echo "⚠ Cannot reach API Gateway from frontend container"

echo ""
echo "=========================================="
echo "Diagnosis Complete"
echo "=========================================="

