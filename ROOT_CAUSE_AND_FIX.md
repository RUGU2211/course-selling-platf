# ROOT CAUSE AND COMPLETE FIX

## ROOT CAUSE IDENTIFIED

The 404 errors are happening because:

1. **API Gateway routes are NOT loading from config-server**
   - `/actuator/gateway/routes` returns 404 (routes not loaded)
   - Config server was using Git mode, now switched to native mode
   - Services on EC2 haven't been rebuilt with new configuration

2. **Services have context paths** (`/course-management-service`, `/user-management-service`, etc.)
   - API Gateway routes match `/course-management-service/**`
   - Routes forward to `lb://course-management-service` 
   - Since services have context paths, paths are forwarded correctly (no rewrite needed)

3. **Configuration files are correct** but services need to be rebuilt on EC2

## IMMEDIATE FIX - Run These Commands on EC2

```bash
# 1. Pull latest code (if using git)
cd ~/course-selling-platf
git pull

# 2. Stop all services
docker compose down

# 3. Rebuild config-server (native mode) and API Gateway
docker compose build config-server api-gateway

# 4. Start services in order
docker compose up -d mysql eureka-server

# 5. Wait for Eureka (about 30 seconds)
sleep 30

# 6. Start config-server
docker compose up -d config-server

# 7. Wait for config-server to be healthy (2-3 minutes)
# Check status:
docker compose ps config-server
# Keep checking until it shows "healthy"

# 8. Test config-server is serving config
curl http://localhost:8888/api-gateway/default
# Should return JSON with gateway configuration

# 9. Start all microservices
docker compose up -d user-service course-service enrollment-service content-service actuator

# 10. Wait for services to register in Eureka (30 seconds)
sleep 30

# 11. Start API Gateway
docker compose up -d api-gateway

# 12. Wait for API Gateway to be healthy (2-3 minutes)
# Check status:
docker compose ps api-gateway
# Keep checking until it shows "healthy"

# 13. Check if routes are loaded
curl http://localhost:8765/actuator/gateway/routes
# Should return list of routes, NOT 404

# 14. Test routes directly
curl http://localhost:8765/course-management-service/api/courses
curl http://localhost:8765/user-management-service/api/users/stats
# Should return data, NOT 404

# 15. Restart frontend
docker compose restart frontend

# 16. Check all services are healthy
docker compose ps
```

## OR USE THE AUTOMATED SCRIPT

```bash
# Make script executable
chmod +x FIX_404_ERRORS_NOW.sh

# Run the fix script
./FIX_404_ERRORS_NOW.sh
```

## Configuration Summary

### ✅ Config Server (Native Mode)
- Location: `config-server/src/main/resources/config/api-gateway.yml`
- Mode: Native (local files, no Git)
- Files: All config files in `config-server/src/main/resources/config/`

### ✅ API Gateway Routes
- Routes configured in: `config-server/src/main/resources/config/api-gateway.yml`
- Uses service discovery: `lb://` for Eureka services
- No hardcoded routes in `application.properties`
- Routes forward full paths (services have context paths)

### ✅ Services
- All services have context paths: `/course-management-service`, `/user-management-service`, etc.
- Controllers use: `/api/courses`, `/api/users`, etc.
- Full paths: `/course-management-service/api/courses`

## Verification After Fix

```bash
# 1. Check config server is serving config
curl http://localhost:8888/api-gateway/default | jq '.propertySources[0].source["spring.cloud.gateway.routes"]'

# 2. Check API Gateway routes
curl http://localhost:8765/actuator/gateway/routes | jq

# 3. Test routes
curl http://localhost:8765/course-management-service/api/courses
curl http://localhost:8765/user-management-service/api/users/stats

# 4. Check services in Eureka
curl http://localhost:8761/eureka/apps | grep -i "course-management-service"
```

## If Routes Still Don't Load

Check API Gateway logs:
```bash
docker logs course-platform-api-gateway | grep -i "config\|route\|gateway" | tail -50
```

Look for:
- "Loaded config from server" - Config loaded successfully
- "No qualifying bean" - Routes not loading
- Connection errors to config-server

## Expected Behavior After Fix

1. ✅ Config server starts with native mode
2. ✅ Config server serves config at `/api-gateway/default`
3. ✅ API Gateway starts after config-server is healthy
4. ✅ API Gateway loads routes from config-server
5. ✅ Routes are visible at `/actuator/gateway/routes`
6. ✅ Routes forward to services via Eureka (`lb://`)
7. ✅ Services respond correctly (no 404 errors)

