# Quick Service Status Check Guide

## Check if API Gateway Started Successfully

Your API Gateway logs show it's starting up. Check if it's fully running:

```bash
# Check container status
docker ps | grep api-gateway

# Check if it's healthy
docker compose ps api-gateway

# Check recent logs (last 50 lines)
docker logs course-platform-api-gateway --tail 50

# Test if it's responding
curl http://localhost:8765/actuator/health
```

## Expected Status

The API Gateway should show:
- **Status:** Up (running)
- **Health:** Healthy
- **Registered with Eureka:** Yes

## Check All Services Status

```bash
# See all containers
docker compose ps

# See which services are running
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check all service logs
docker compose logs --tail=20
```

## Test Services After Startup

### 1. Test API Gateway
```bash
curl http://localhost:8765/actuator/health
# Should return: {"status":"UP"}
```

### 2. Test Eureka Dashboard
```bash
curl http://localhost:8761
# Should return HTML page
```

### 3. Test Frontend
```bash
curl http://localhost:3000
# Should return HTML page
```

### 4. Check Eureka for Registered Services
```bash
curl http://localhost:8761/eureka/apps
# Should show all registered services
```

## Common Issues

### API Gateway Not Fully Started Yet
- **Symptom:** Logs show "Starting..." but no "Started" message
- **Solution:** Wait 2-3 more minutes. Initial startup takes 5-10 minutes.

### Services Not Registered in Eureka
- **Symptom:** Eureka dashboard shows no services
- **Solution:** Wait for services to register (can take 2-5 minutes after container starts)

### Port Already in Use
- **Symptom:** Container exits immediately
- **Solution:** 
  ```bash
  # Check what's using the port
  sudo netstat -tlnp | grep 8765
  
  # Stop conflicting container
  docker compose down
  docker compose up -d
  ```

## What the Logs Mean

### ✅ Good Signs:
- "Starting ApiGatewayApplication" - Service is starting
- "Fetching config from server" - Config server connection working
- "Loaded RoutePredicateFactory" - Routes are being configured
- "Exposing endpoints beneath base path '/actuator'" - Actuator endpoints ready

### ⚠️ Warnings (Usually OK):
- "spring-cloud-gateway-server is deprecated" - Non-critical warning
- "Cannot determine local hostname" - Common in Docker, usually fine

### 🔴 Errors to Watch For:
- "Connection refused" - Service dependencies not ready
- "Failed to register" - Eureka connection issue
- "Port already in use" - Port conflict

## Complete Service Check Script

```bash
#!/bin/bash
echo "=== Docker Containers Status ==="
docker compose ps

echo -e "\n=== Checking Service Health ==="
echo "API Gateway:"
curl -s http://localhost:8765/actuator/health || echo "Not responding"

echo -e "\nEureka:"
curl -s http://localhost:8761 | head -1 || echo "Not responding"

echo -e "\nFrontend:"
curl -s http://localhost:3000 | head -1 || echo "Not responding"

echo -e "\n=== Eureka Registered Services ==="
curl -s http://localhost:8761/eureka/apps | grep -o '<application><name>[^<]*</name>' | sed 's/<application><name>\(.*\)<\/name>/\1/' || echo "No services registered yet"
```

Save this as `check-services.sh`, make it executable (`chmod +x check-services.sh`), and run it.

