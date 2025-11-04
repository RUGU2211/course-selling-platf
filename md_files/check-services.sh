#!/bin/bash
echo "======================================"
echo "Service Status Check Script"
echo "======================================"
echo ""

echo "=== Docker Containers Status ==="
docker compose ps
echo ""

echo "=== Checking Service Health Endpoints ==="
echo ""

echo "1. API Gateway (Port 8765):"
curl -s http://localhost:8765/actuator/health 2>/dev/null && echo -e "\n✅ API Gateway is UP" || echo "❌ API Gateway not responding"
echo ""

echo "2. Eureka Server (Port 8761):"
curl -s http://localhost:8761 | head -1 2>/dev/null && echo "✅ Eureka is UP" || echo "❌ Eureka not responding"
echo ""

echo "3. Frontend (Port 3000):"
curl -s http://localhost:3000 | head -1 2>/dev/null && echo "✅ Frontend is UP" || echo "❌ Frontend not responding"
echo ""

echo "4. Config Server (Port 8888):"
curl -s http://localhost:8888/actuator/health 2>/dev/null && echo "✅ Config Server is UP" || echo "❌ Config Server not responding"
echo ""

echo "=== Eureka Registered Services ==="
REGISTERED=$(curl -s http://localhost:8761/eureka/apps 2>/dev/null | grep -o '<application><name>[^<]*</name>' | sed 's/<application><name>\(.*\)<\/name>/\1/' | sort -u)
if [ -z "$REGISTERED" ]; then
    echo "⚠️  No services registered in Eureka yet (may still be starting)"
else
    echo "$REGISTERED" | while read service; do
        echo "  ✅ $service"
    done
fi
echo ""

echo "=== Container Resource Usage ==="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -15
echo ""

echo "=== Recent API Gateway Logs (Last 5 lines) ==="
docker logs course-platform-api-gateway --tail 5 2>/dev/null | grep -E "(Started|ERROR|WARN|INFO.*main)" | tail -5
echo ""

echo "======================================"
echo "Check Complete!"
echo "======================================"

