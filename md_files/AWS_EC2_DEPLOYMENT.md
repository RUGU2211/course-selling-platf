# AWS EC2 Deployment Guide - Course Selling Platform

Complete step-by-step guide to deploy your Course Selling Platform on AWS EC2 Free Tier.

## Prerequisites

- AWS Free Tier Account (12 months)
- Docker & Docker Compose installed on EC2 (✅ Already Done!)
- Git installed on EC2 (we'll do this)
- SSH access to your EC2 instance

## Your Current Setup

- **Instance Type**: t2.micro (Free Tier)
- **Operating System**: Amazon Linux 2023
- **Docker**: ✅ Installed
- **Docker Compose**: ✅ Installed

## Deployment Steps on EC2

### Step 1: Connect to Your EC2 Instance

From your local Windows machine:
```powershell
ssh -i path\to\course-platform.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

Replace:
- `path\to\course-platform.pem` with your actual key file path
- `YOUR_EC2_PUBLIC_IP` with your EC2 instance's public IP

### Step 2: Install Additional Tools

Once connected to EC2:
```bash
# Update system
sudo yum update -y

# Install Git
sudo yum install git -y

# Install Git
git --version
```

### Step 3: Clone Your Repository

```bash
# Clone your repository
git clone https://github.com/RUGU2211/course-selling-platf.git

# Navigate to project directory
cd course-selling-platf

# Switch to master branch if not already on it
git checkout master
```

### Step 4: Add Swap Space (Critical for 1GB RAM!)

The t2.micro instance has only 1GB RAM. We need swap space for Maven builds:

```bash
# Create 2GB swap file
sudo dd if=/dev/zero of=/swapfile bs=128M count=16

# Set permissions
sudo chmod 600 /swapfile

# Make it a swap file
sudo mkswap /swapfile

# Enable swap
sudo swapon /swapfile

# Make it permanent (survive reboots)
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify swap is active
free -h
```

You should see `Swap: 2.0Gi` in the output.

### Step 5: Increase Docker Resources

We need to ensure Docker has enough memory for Maven builds:

```bash
# Increase Docker's max memory usage
sudo systemctl stop docker

# Edit Docker daemon configuration
sudo nano /etc/docker/daemon.json
```

Add this content:
```json
{
  "default-ulimits": {
    "memlock": {
      "name": "memlock",
      "soft": -1,
      "hard": -1
    }
  },
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Save (Ctrl+X, then Y, then Enter).

```bash
# Restart Docker
sudo systemctl start docker
```

### Step 6: Start the Platform

Now we'll start all services using Docker Compose:

```bash
# Make sure you're in the project directory
cd ~/course-selling-platf

# Start all services in detached mode
docker-compose up -d

# Watch the logs (this will take 5-10 minutes for first build)
docker-compose logs -f
```

**Important**: The first run will:
1. Download all base images
2. Build Java services with Maven (this is CPU-intensive)
3. Build React frontend with npm
4. Start all 8 microservices + MySQL + monitoring

**Be patient!** It can take 10-15 minutes.

### Step 7: Monitor Progress

Open a new SSH terminal and watch the logs:

```bash
# See all running containers
docker ps

# Check specific service logs
docker logs course-platform-eureka -f
docker logs course-platform-api-gateway -f
docker logs course-platform-frontend -f

# Check if any container crashed
docker ps -a
```

### Step 8: Verify Services Are Running

After 10-15 minutes, check health endpoints:

```bash
# Check Eureka Dashboard
curl http://localhost:8761

# Check API Gateway
curl http://localhost:8765

# Check Frontend
curl http://localhost:3000
```

### Step 9: Access Your Application

Open your browser and visit:

- **Frontend**: `http://YOUR_EC2_PUBLIC_IP:3000`
- **API Gateway**: `http://YOUR_EC2_PUBLIC_IP:8765`
- **Eureka Dashboard**: `http://YOUR_EC2_PUBLIC_IP:8761`
- **MySQL**: Not publicly accessible (port 3307 only internal)

### Step 10: Enable HTTPS with Nginx Reverse Proxy (Optional)

For production, you should set up Nginx reverse proxy with SSL:

```bash
# Install Nginx
sudo yum install nginx -y

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

Then configure Nginx to proxy to your frontend. This is advanced and requires SSL certificate.

## Troubleshooting

### Out of Memory Errors

If you see Maven build failures:

```bash
# Check memory usage
free -h

# Check if swap is enabled
swapon --show

# Restart Docker
sudo systemctl restart docker

# Clean Docker cache
docker system prune -a
```

### Services Not Starting

Check logs:
```bash
docker-compose logs [service-name]
```

Common issues:
- MySQL taking too long to start - wait 5 minutes
- Eureka not ready - wait 2 minutes
- Build timeout - increase Docker resources

### Container Keeps Restarting

```bash
# Check why a container crashed
docker logs [container-name]

# Restart a specific service
docker restart [container-name]
```

### Need to Rebuild Services

```bash
# Stop all services
docker-compose down

# Rebuild and start
docker-compose up -d --build
```

### Database Issues

```bash
# Connect to MySQL
docker exec -it course-platform-mysql mysql -uroot -proot

# Show databases
SHOW DATABASES;

# Exit
exit;
```

## Useful Commands

```bash
# View all containers
docker ps

# View logs for all services
docker-compose logs -f

# Stop all services
docker-compose down

# Start all services
docker-compose up -d

# Restart a specific service
docker-compose restart [service-name]

# View resource usage
docker stats

# Clean up unused images
docker image prune -a

# Update from Git and rebuild
cd ~/course-selling-platf
git pull
docker-compose down
docker-compose up -d --build
```

## Security Considerations

⚠️ **IMPORTANT**: Your current setup is for development/testing only!

For production:
1. Change all default passwords (MySQL, etc.)
2. Use environment variables for secrets
3. Set up AWS RDS for database (not free tier)
4. Use AWS Elastic Load Balancer
5. Enable HTTPS/SSL
6. Configure firewall properly
7. Use IAM roles instead of access keys
8. Enable CloudWatch monitoring
9. Set up auto-scaling
10. Implement backup strategy

## Cost Monitoring

Free Tier includes:
- 750 hours/month of t2.micro for 12 months
- 30 GB storage
- 15 GB data transfer

After 12 months, approximate costs:
- t2.micro: ~$10/month
- 30GB EBS: ~$3/month
- Data transfer: varies

Keep your instance stopped when not in use to save costs!

## Stopping Your Instance

When you're done testing:
```bash
# Stop all containers
docker-compose down

# Or stop the EC2 instance from AWS Console
```

## Next Steps

1. **Push to GitHub**: Follow the guide below to push your code to master branch
2. **Set up Auto-Deploy**: Use GitHub Actions to auto-deploy on push
3. **Add CI/CD**: Set up automated testing before deployment
4. **Production Setup**: Move to larger instance type when going live

## Support

If you encounter issues:
1. Check Docker logs: `docker-compose logs -f`
2. Check service health: `docker ps`
3. Verify security groups in AWS Console
4. Check CloudWatch for instance metrics

---

**Congratulations!** Your Course Selling Platform is now running on AWS EC2! 🎉

