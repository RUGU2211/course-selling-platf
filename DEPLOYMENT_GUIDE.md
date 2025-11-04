# Deployment Guide - Course Selling Platform

This guide provides step-by-step instructions to deploy the Course Selling Platform using Docker Compose and Kubernetes (Minikube) locally.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Docker Compose Deployment](#docker-compose-deployment)
3. [Kubernetes Deployment (Minikube)](#kubernetes-deployment-minikube)
4. [Verification](#verification)
5. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### For Docker Compose
- Docker Desktop installed and running
- Docker Compose v2.0+
- At least 8GB RAM available
- 20GB free disk space

### For Kubernetes (Minikube)
- Docker Desktop installed and running
- Minikube installed
- kubectl installed
- At least 8GB RAM available
- 20GB free disk space

### Verify Prerequisites
```powershell
# Check Docker
docker --version
docker-compose --version

# Check Minikube (for Kubernetes)
minikube version
kubectl version --client
```

---

## Docker Compose Deployment

### Quick Start

**Option 1: Using Batch Script (Windows)**
```powershell
.\docker-compose-up.bat
```

**Option 2: Manual Commands**
```powershell
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### Step-by-Step Deployment

#### 1. Build All Services
```powershell
# Build all Docker images
docker-compose build
```

#### 2. Start Infrastructure Services First
```powershell
# Start MySQL, Eureka, and Config Server
docker-compose up -d mysql eureka-server config-server

# Wait for them to be ready (check logs)
docker-compose logs -f mysql
docker-compose logs -f eureka-server
docker-compose logs -f config-server
```

#### 3. Start Application Services
```powershell
# Start all microservices
docker-compose up -d user-service course-service enrollment-service content-service api-gateway frontend

# Start monitoring (optional)
docker-compose up -d prometheus grafana
```

#### 4. Verify All Services
```powershell
# Check all services status
docker-compose ps

# Check service health
.\verify-services.bat
```

### Useful Docker Compose Commands

```powershell
# View logs for specific service
docker-compose logs -f [service-name]

# Restart a service
docker-compose restart [service-name]

# Stop all services
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v

# View resource usage
docker stats

# Execute command in running container
docker-compose exec [service-name] [command]
```

### Access Services (Docker Compose)

- **Frontend**: http://localhost:3000
- **API Gateway**: http://localhost:8765
- **Eureka Dashboard**: http://localhost:8761
- **Config Server**: http://localhost:8888
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3030 (admin/admin)

---

## Kubernetes Deployment (Minikube)

### Quick Start

**Option 1: Using Batch Script (Windows)**
```powershell
# Step 1: Setup Minikube
.\k8s-setup-minikube.bat

# Step 2: Deploy to Kubernetes
.\k8s-deploy.bat
```

**Option 2: Manual Commands**

#### 1. Setup Minikube
```powershell
# Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# Enable addons
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard

# Verify
kubectl cluster-info
kubectl get nodes
```

#### 2. Create Namespace
```powershell
kubectl create namespace course-plat
```

#### 3. Create Docker Registry Secret
```powershell
# Replace with your Docker Hub credentials
kubectl create secret docker-registry dockerhub-secret `
  --docker-server=https://index.docker.io/v1/ `
  --docker-username=YOUR_DOCKERHUB_USERNAME `
  --docker-password=YOUR_DOCKERHUB_PASSWORD `
  --docker-email=YOUR_EMAIL `
  -n course-plat
```

#### 4. Deploy Services

**Set Environment Variables:**
```powershell
$env:DOCKERHUB_USER="your-dockerhub-username"
$env:IMAGE_TAG="latest"
```

**Deploy in Order:**
```powershell
# 1. MySQL
kubectl apply -f k8s/mysql.yaml -n course-plat
kubectl wait --for=condition=ready pod -l app=mysql -n course-plat --timeout=300s

# 2. Eureka Server
kubectl apply -f k8s/eureka-server.yaml -n course-plat
kubectl wait --for=condition=available deployment/eureka-server -n course-plat --timeout=300s

# 3. Config Server
kubectl apply -f k8s/config-server.yaml -n course-plat
kubectl wait --for=condition=available deployment/config-server -n course-plat --timeout=300s

# 4. Actuator
kubectl apply -f k8s/actuator.yaml -n course-plat

# 5. Microservices
kubectl apply -f k8s/user-service.yaml -n course-plat
kubectl apply -f k8s/course-service.yaml -n course-plat
kubectl apply -f k8s/enrollment-service.yaml -n course-plat
kubectl apply -f k8s/content-service.yaml -n course-plat

# 6. API Gateway
kubectl apply -f k8s/api-gateway.yaml -n course-plat

# 7. Frontend
kubectl apply -f k8s/frontend.yaml -n course-plat

# 8. Monitoring (optional)
kubectl apply -f k8s/prometheus.yaml -n course-plat
kubectl apply -f k8s/grafana.yaml -n course-plat
```

### Access Services (Minikube)

#### Using Minikube Service Command
```powershell
# Frontend
minikube service frontend -n course-plat

# API Gateway
minikube service api-gateway -n course-plat

# Eureka Dashboard
minikube service eureka-server -n course-plat

# Config Server
minikube service config-server -n course-plat

# Prometheus
minikube service prometheus -n course-plat

# Grafana
minikube service grafana -n course-plat
```

#### Using Port Forward
```powershell
# Frontend
kubectl port-forward -n course-plat svc/frontend 3000:80

# API Gateway
kubectl port-forward -n course-plat svc/api-gateway 8765:8765

# Eureka
kubectl port-forward -n course-plat svc/eureka-server 8761:8761

# Config Server
kubectl port-forward -n course-plat svc/config-server 8888:8888

# Prometheus
kubectl port-forward -n course-plat svc/prometheus 9090:9090

# Grafana
kubectl port-forward -n course-plat svc/grafana 3030:3000
```

#### Using Minikube IP
```powershell
# Get Minikube IP
minikube ip

# Access services via NodePort (check service ports)
kubectl get svc -n course-plat
```

### Useful Kubernetes Commands

```powershell
# View all resources
kubectl get all -n course-plat

# View pods
kubectl get pods -n course-plat

# View services
kubectl get svc -n course-plat

# View deployments
kubectl get deployments -n course-plat

# View logs
kubectl logs -n course-plat deployment/[service-name]

# Describe pod
kubectl describe pod [pod-name] -n course-plat

# Execute command in pod
kubectl exec -it [pod-name] -n course-plat -- [command]

# Scale deployment
kubectl scale deployment [service-name] --replicas=2 -n course-plat

# Delete deployment
kubectl delete deployment [service-name] -n course-plat

# Delete namespace (removes everything)
kubectl delete namespace course-plat
```

---

## Verification

### Verify Docker Compose Deployment

```powershell
# Check all containers are running
docker-compose ps

# Check service health endpoints
curl http://localhost:8761/actuator/health
curl http://localhost:8888/actuator/health
curl http://localhost:8765/actuator/health
curl http://localhost:8082/user-management-service/actuator/health
curl http://localhost:8083/course-management-service/actuator/health
curl http://localhost:8084/enrollment-service/actuator/health
curl http://localhost:8087/content-delivery-service/actuator/health

# Check Eureka dashboard
# Open browser: http://localhost:8761

# Check frontend
# Open browser: http://localhost:3000
```

### Verify Kubernetes Deployment

```powershell
# Check all pods are running
kubectl get pods -n course-plat

# Check all services
kubectl get svc -n course-plat

# Check deployments
kubectl get deployments -n course-plat

# Check pod logs
kubectl logs -n course-plat -l app=[service-name]

# Check service health (via port-forward)
kubectl port-forward -n course-plat svc/eureka-server 8761:8761
# Then in another terminal:
curl http://localhost:8761/actuator/health
```

### Run Verification Script

```powershell
# Docker Compose
.\verify-services.bat

# Kubernetes
.\k8s-verify.bat
```

---

## Troubleshooting

### Docker Compose Issues

#### Services Not Starting
```powershell
# Check logs
docker-compose logs [service-name]

# Check container status
docker ps -a

# Restart service
docker-compose restart [service-name]

# Rebuild and restart
docker-compose up -d --build [service-name]
```

#### Database Connection Issues
```powershell
# Check MySQL is running
docker-compose ps mysql

# Check MySQL logs
docker-compose logs mysql

# Test MySQL connection
docker-compose exec mysql mysql -uroot -proot -e "SHOW DATABASES;"
```

#### Port Conflicts
```powershell
# Check if ports are in use
netstat -ano | findstr :3307
netstat -ano | findstr :8761

# Change port in docker-compose.yml
```

### Kubernetes Issues

#### Pods Not Starting
```powershell
# Check pod status
kubectl get pods -n course-plat

# Check pod events
kubectl describe pod [pod-name] -n course-plat

# Check pod logs
kubectl logs [pod-name] -n course-plat

# Check events
kubectl get events -n course-plat --sort-by='.lastTimestamp'
```

#### Image Pull Errors
```powershell
# Check Docker registry secret
kubectl get secret dockerhub-secret -n course-plat

# Recreate secret if needed
kubectl create secret docker-registry dockerhub-secret `
  --docker-server=https://index.docker.io/v1/ `
  --docker-username=YOUR_USERNAME `
  --docker-password=YOUR_PASSWORD `
  --docker-email=YOUR_EMAIL `
  -n course-plat
```

#### Services Not Accessible
```powershell
# Check service endpoints
kubectl get endpoints -n course-plat

# Check service details
kubectl describe svc [service-name] -n course-plat

# Test service connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -n course-plat -- wget -O- http://[service-name]:[port]
```

#### Minikube Issues
```powershell
# Check Minikube status
minikube status

# Restart Minikube
minikube stop
minikube start

# Delete and recreate
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096
```

---

## Cleanup

### Docker Compose Cleanup
```powershell
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Remove images
docker-compose down --rmi all
```

### Kubernetes Cleanup
```powershell
# Delete all resources in namespace
kubectl delete all --all -n course-plat

# Delete namespace
kubectl delete namespace course-plat

# Stop Minikube
minikube stop

# Delete Minikube
minikube delete
```

---

## Next Steps

1. **Access the Application**: Open http://localhost:3000 (Docker Compose) or use Minikube service commands
2. **Monitor Services**: Check Eureka dashboard at http://localhost:8761
3. **View Metrics**: Access Prometheus at http://localhost:9090 and Grafana at http://localhost:3030
4. **Test API Endpoints**: Use the API Gateway at http://localhost:8765

For detailed API documentation, see [API_ENDPOINTS.md](md_files/API_ENDPOINTS.md)

