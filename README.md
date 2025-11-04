<<<<<<< HEAD
# Course Selling Platform

A comprehensive microservices-based course selling platform built with Spring Boot, React, and Docker.

## Architecture

This platform consists of the following microservices:

- **API Gateway** (Port 8765) - Central entry point for all API requests
- **Eureka Server** (Port 8761) - Service discovery and registration
- **Config Server** (Port 8888) - Centralized configuration management
- **User Management Service** (Port 8082) - User registration, authentication, and profile management
- **Course Management Service** (Port 8083) - Course creation, management, and reviews
- **Enrollment Service** (Port 8084) - Student course enrollment and progress tracking
- **Content Delivery Service** (Port 8087) - Course content upload and streaming
- **Frontend Application** (Port 3000) - React-based user interface

## Quick Start

**📖 See [QUICK_START.md](QUICK_START.md) for detailed instructions!**

### Prerequisites
- Docker and Docker Compose
- Java 21 JDK (for local development)
- Maven 3.9+ (for building services)
- Node.js 20+ (for frontend development)

### Running the Platform

**⚠️ Important:** You need to build JAR files first before using Docker Compose, or use Docker Hub images.

#### Option 1: Build from Source (Development)
```bash
# 1. Build all services (requires Maven)
.\build-all-services.ps1  # Windows

# 2. Start all services
docker-compose up -d

# 3. Check service status
docker-compose ps

# 4. View logs
docker-compose logs -f

# 5. Stop all services
docker-compose down
```

#### Option 2: Using Docker Hub Images (Production)
```bash
# 1. Login to Docker Hub
docker login

# 2. Deploy production images
docker-compose -f docker-compose.prod.yml up -d

# Or use deployment script
.\deploy-prod.bat  # Windows
```

#### Option 3: Using Startup Scripts
- **Linux/Mac:** `./start-platform.sh`
- **Windows:** `start-platform.bat`

### Service URLs

- **Frontend:** http://localhost:3000
- **API Gateway:** http://localhost:8765
- **Eureka Server:** http://localhost:8761

### Database
- **MySQL:** localhost:3307 (Docker Compose) or localhost:3306 (Kubernetes)

## API Documentation

Complete API endpoints documentation is available in [API_ENDPOINTS.md](API_ENDPOINTS.md).

### Key Endpoints

#### User Management
- `POST /user-management-service/api/users/register` - Register new user
- `POST /user-management-service/api/users/login` - User login
- `GET /user-management-service/api/users/profile/{id}` - Get user profile

#### Course Management
- `GET /course-management-service/api/courses` - Get all courses
- `POST /course-management-service/api/courses` - Create new course
- `GET /course-management-service/api/courses/{id}` - Get course by ID

#### Enrollment
- `POST /enrollment-service/api/enrollments` - Enroll in course
- `GET /enrollment-service/api/enrollments/student/{id}` - Get student enrollments

#### Content Delivery
- `POST /content-delivery-service/api/content/{courseId}/upload` - Upload content
- `GET /content-delivery-service/api/content/course/{courseId}` - Get course content

## Development

### Local Development Setup

1. **Start Infrastructure Services:**
   ```bash
   docker-compose up mysql redis rabbitmq eureka-server -d
   ```

2. **Run Individual Services:**
   ```bash
   # User Management Service
   cd user-management-service
   ./mvnw spring-boot:run

   # Course Management Service
   cd course-management-service
   ./mvnw spring-boot:run

   # Continue for other services...
   ```

3. **Run Frontend:**
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

### Service Configuration

All services are configured to work without a centralized config server. Each service has its own `application.yml` with:
- Direct database connections
- Eureka service discovery
- Health check endpoints
- CORS configuration

## Monitoring

### Health Checks
All services expose health endpoints at `/actuator/health`:
- User Service: http://localhost:8082/actuator/health
- Course Service: http://localhost:8083/actuator/health
- Enrollment Service: http://localhost:8084/enrollment-service/actuator/health
- Content Service: http://localhost:8087/actuator/health
- API Gateway: http://localhost:8765/actuator/health
- Config Server: http://localhost:8888/actuator/health
- Eureka Server: http://localhost:8761/actuator/health

### Service Discovery
- Eureka Dashboard: http://localhost:8761

## Features

- **User Management:** Registration, authentication, profile management
- **Course Management:** Create, update, delete courses with reviews
- **Enrollment System:** Student enrollment with progress tracking
- **Content Delivery:** Video upload and streaming capabilities
- **Service Discovery:** Automatic service registration and discovery
- **API Gateway:** Centralized routing and load balancing
- **Inter-Service Communication:** Strong backend integration using OpenFeign clients
- **Enhanced Workflows:** Multi-service validation and data aggregation

## Technology Stack

- **Backend:** Spring Boot, Spring Cloud Gateway, Spring Security, Spring Cloud Config
- **Frontend:** React, TypeScript, Vite
- **Database:** MySQL
- **Service Discovery:** Netflix Eureka
- **Containerization:** Docker, Docker Compose
- **CI/CD:** Jenkins

## AWS EC2 Deployment

### Quick Deploy on AWS EC2 (Free Tier)

**📖 See [AWS_EC2_DEPLOYMENT.md](AWS_EC2_DEPLOYMENT.md) for complete guide!**

#### Prerequisites
- AWS Free Tier Account
- EC2 instance with Docker & Docker Compose installed
- Security group configured with ports: 22, 80, 443, 3000, 8761, 8765, 8888, 8082-8087

#### Automated Deployment

**Option 1: Use the automated script**
```bash
# Clone repository
git clone https://github.com/RUGU2211/course-selling-platf.git
cd course-selling-platf

# Make script executable
chmod +x deploy-ec2.sh

# Run deployment script
./deploy-ec2.sh
```

**Option 2: Manual deployment**
```bash
# Clone repository
git clone https://github.com/RUGU2211/course-selling-platf.git
cd course-selling-platf

# Create swap space (for 1GB RAM instances)
sudo dd if=/dev/zero of=/swapfile bs=128M count=16
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Start all services
docker-compose up -d
```

#### Access Your Application

After deployment (wait 10-15 minutes for first build):
- Frontend: `http://YOUR_EC2_PUBLIC_IP:3000`
- API Gateway: `http://YOUR_EC2_PUBLIC_IP:8765`
- Eureka Dashboard: `http://YOUR_EC2_PUBLIC_IP:8761`

#### Deployment Notes

- **First build takes 10-15 minutes** (downloading images & building services)
- **Memory**: 1GB RAM (t2.micro) requires swap space
- **Storage**: Uses ~10GB for Docker images and data
- **Monitor logs**: `docker-compose logs -f`

For detailed instructions, see [AWS_EC2_DEPLOYMENT.md](AWS_EC2_DEPLOYMENT.md)

## Project Structure

```
course-selling-platform/
├── api-gateway/                 # API Gateway service
├── eureka-server/              # Service discovery
├── config-server/              # Centralized configuration
├── user-management-service/    # User management
├── course-management-service/  # Course management
├── enrollmentservice/          # Enrollment service
├── content-delivery-service/   # Content delivery
├── frontend/                  # React frontend
├── k8s/                      # Kubernetes manifests
├── docker/                    # Docker configurations
├── docker-compose.yml         # Docker Compose setup
├── deploy-ec2.sh              # EC2 deployment script
├── AWS_EC2_DEPLOYMENT.md      # EC2 deployment guide
└── API_ENDPOINTS.md          # API documentation
```

## Troubleshooting

### Common Issues

1. **Services not starting:**
   ```bash
   docker-compose logs [service-name]
   ```

2. **Database connection issues:**
   - Ensure MySQL container is running
   - Check database credentials in service configurations

3. **Service discovery issues:**
   - Verify Eureka server is running
   - Check service registration in Eureka dashboard

4. **Frontend not loading:**
   - Ensure API Gateway is running
   - Check CORS configuration

### Useful Commands

```bash
# View all running containers
docker-compose ps

# View logs for specific service
docker-compose logs -f [service-name]

# Restart specific service
docker-compose restart [service-name]

# Stop all services
docker-compose down

# Remove all containers and volumes
docker-compose down -v
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License. 
=======
# Course Selling Platform - Configuration Files

This repository contains the centralized configuration files for the Course Selling Platform microservices architecture.


## Services Configuration

### 1. User Management Service
- **File**: `user-management-service.yml`
- **Port**: 8082
- **Database**: users_db
- **Features**: JWT authentication, user CRUD operations

### 2. Course Management Service
- **File**: `course-management-service.yml`
- **Port**: 8083
- **Database**: courses_db
- **Features**: Course CRUD, JWT validation

### 3. Payment Service
- **File**: `payment-service.yml`
- **Port**: 8086
- **Database**: payment_db
- **Features**: Razorpay integration, payment processing

### 4. Enrollment Service
- **File**: `enrollmentservice.yml`
- **Port**: 8084
- **Database**: enrollment_db
- **Features**: Course enrollment management

### 5. Notification Service
- **File**: `notification-service.yml`
- **Port**: 8085
- **Database**: notification_db
- **Features**: User notifications, email services

### 6. Content Delivery Service
- **File**: `content-delivery-service.yml`
- **Port**: 8087
- **Database**: content_db
- **Features**: Course content management

### 7. API Gateway
- **File**: `api-gateway.yml`
- **Port**: 8765
- **Features**: Service discovery, routing, load balancing

### 8. Eureka Server
- **File**: `eureka-server.yml`
- **Port**: 8761
- **Features**: Service discovery and registration

## Configuration Server Integration

These configuration files are used by the Spring Cloud Config Server to provide centralized configuration management for all microservices.

### Config Server URL
http://config-server:8888

### Accessing Service ConfigurationsGet specific service configuration
GET http://config-server:8888/{service-name}/{profile}
Examples:
GET http://config-server:8888/user-management-service/default
GET http://config-server:8888/payment-service/default
GET http://config-server:8888/api-gateway/default

## Environment Variables

For production deployment, the following environment variables should be set:
- `DB_USERNAME`: Database username
- `DB_PASSWORD`: Database password
- `JWT_SECRET`: JWT signing secret
- `RAZORPAY_KEY_ID`: Razorpay API key ID
- `RAZORPAY_KEY_SECRET`: Razorpay API secret

## Docker Integration

All services are configured to work with Docker Compose:
- **Eureka Server**: `eureka-server:8761`
- **Config Server**: `config-server:8888`
- **MySQL Database**: `mysql:3306`

## Security Notes

⚠️ **Important**: The configuration files contain test credentials and should be updated for production use:
- Change JWT secrets
- Update Razorpay credentials
- Use environment variables for sensitive data
- Implement proper security measures

## Usage

1. Clone this repository
2. Update the Config Server to point to this repository
3. Deploy the microservices
4. Services will automatically fetch their configurations from this repository

## Support

For questions or issues, please contact the development team.
>>>>>>> config-repo/main
