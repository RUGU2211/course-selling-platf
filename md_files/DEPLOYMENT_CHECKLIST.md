# AWS EC2 Deployment Checklist

Complete step-by-step checklist to deploy your Course Selling Platform on AWS EC2.

## ✅ Pre-Deployment Checklist

### On Your Local Machine
- [ ] Git repository is up-to-date
- [ ] All changes committed and pushed to master branch
- [ ] You have your EC2 key pair (.pem file) downloaded
- [ ] You have your EC2 public IP address

### On AWS EC2
- [ ] EC2 instance is running (t2.micro Free Tier)
- [ ] Docker is installed
- [ ] Docker Compose is installed
- [ ] Security group is configured with required ports

---

## 🚀 Deployment Steps

### Step 1: Connect to Your EC2 Instance

**From Windows PowerShell:**

```powershell
# Navigate to where your PEM file is located
cd C:\Users\YourName\Downloads

# Connect to EC2
ssh -i course-platform-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

**Replace:**
- `course-platform-key-pair.pem` with your actual key file name
- `YOUR_EC2_PUBLIC_IP` with your EC2 instance's public IP address

**Expected Output:**
```
The authenticity of host 'XXX.XXX.XXX.XXX' can't be established.
Are you sure you want to continue connecting (yes/no)? yes
       __|  __|_  )
       _|  (     /   Amazon Linux 2023 AMI
      ___|\___|___|
```

---

### Step 2: Install Git

Once connected to EC2:

```bash
# Check if Git is installed
git --version

# If not installed, install it
sudo yum install git -y
```

**Expected Output:**
```
Git version 2.x.x
```

---

### Step 3: Create Swap Space (IMPORTANT!)

Your t2.micro instance has only 1GB RAM. Maven builds need more:

```bash
# Check current memory
free -h

# Create 2GB swap file
sudo dd if=/dev/zero of=/swapfile bs=128M count=16

# Set permissions (required for swap)
sudo chmod 600 /swapfile

# Make it a swap file
sudo mkswap /swapfile

# Enable swap
sudo swapon /swapfile

# Verify swap is active
free -h

# Make it permanent (survive reboots)
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**Expected Output:**
```
Before:
              total        used        free      shared  buff/cache   available
Mem:           960M        145M        456M        10M        358M        805M
Swap:            0B          0B          0B

After:
              total        used        free      shared  buff/cache   available
Mem:           960M        145M        456M        10M        358M        805M
Swap:          2.0G          0B        2.0G
```

**✅ Checkpoint:** Swap should show 2.0G

---

### Step 4: Configure Docker

We need to configure Docker for better memory management:

```bash
# Create Docker daemon config
sudo mkdir -p /etc/docker

# Create configuration file
sudo nano /etc/docker/daemon.json
```

**Add this content:**
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

**Save:** Ctrl+X, then Y, then Enter

```bash
# Restart Docker
sudo systemctl restart docker

# Verify Docker is running
sudo systemctl status docker
```

---

### Step 5: Clone Your Repository

```bash
# Clone your repository
git clone https://github.com/RUGU2211/course-selling-platf.git

# Navigate to project
cd course-selling-platf

# Verify you're on master branch
git branch

# Ensure latest code is pulled
git pull origin master
```

**✅ Checkpoint:** You should be in `/home/ec2-user/course-selling-platf`

---

### Step 6: Choose Deployment Method

**Method A: Automated Script (Recommended for First Time)**

```bash
# Make script executable
chmod +x deploy-ec2.sh

# Run automated deployment
./deploy-ec2.sh
```

This script will:
- ✅ Check system requirements
- ✅ Install dependencies
- ✅ Create swap space
- ✅ Configure Docker
- ✅ Clone repository
- ✅ Build and start all services
- ✅ Display access URLs

**OR**

**Method B: Manual Deployment**

```bash
# Stop any existing containers
docker-compose down 2>/dev/null || true

# Build and start all services
docker-compose up -d --build

# Watch the logs
docker-compose logs -f
```

---

### Step 7: Monitor Initial Build (10-15 minutes)

**Open logs in another terminal:**

```bash
# Connect to EC2 in a new terminal (don't close first one)
ssh -i course-platform-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP

# Watch all logs
docker-compose logs -f

# OR watch specific service
docker-compose logs -f api-gateway
docker-compose logs -f frontend
```

**What to expect:**
1. **0-2 minutes:** Downloading base images (mysql, nginx, etc.)
2. **2-5 minutes:** Building Java services with Maven
3. **5-8 minutes:** Building React frontend with npm
4. **8-12 minutes:** Starting services and connecting to databases
5. **12-15 minutes:** All services healthy and running

**Look for these success messages:**
```
✅ course-platform-eureka    started
✅ course-platform-api-gateway    started
✅ course-platform-frontend    started
✅ course-platform-mysql    healthy
```

---

### Step 8: Verify Services Are Running

**Check container status:**

```bash
# List all containers
docker-compose ps

# Check if containers are up
docker ps

# Check memory usage
docker stats --no-stream
```

**Expected Output:**
```
NAME                           STATUS        PORTS
course-platform-eureka         Up 5 minutes  0.0.0.0:8761->8761/tcp
course-platform-api-gateway    Up 4 minutes  0.0.0.0:8765->8765/tcp
course-platform-frontend       Up 3 minutes  0.0.0.0:3000->80/tcp
course-platform-mysql          Up 10 minutes 0.0.0.0:3307->3306/tcp
... (all services running)
```

**✅ Checkpoint:** All services should show "Up"

---

### Step 9: Test Services

**Test Eureka (Service Discovery):**
```bash
curl http://localhost:8761
```

**Test API Gateway:**
```bash
curl http://localhost:8765
```

**Test Frontend:**
```bash
curl http://localhost:3000
```

All should return HTML or JSON responses.

---

### Step 10: Access Your Application

**Open your browser and visit:**

| Service | URL |
|---------|-----|
| **Frontend** | `http://YOUR_EC2_PUBLIC_IP:3000` |
| **API Gateway** | `http://YOUR_EC2_PUBLIC_IP:8765` |
| **Eureka Dashboard** | `http://YOUR_EC2_PUBLIC_IP:8761` |
| **Grafana (optional)** | `http://YOUR_EC2_PUBLIC_IP:3030` |

**Replace `YOUR_EC2_PUBLIC_IP` with your actual EC2 IP**

**Login Credentials:**
- Grafana: admin/admin
- MySQL: root/root

---

## 🎉 Success Criteria

- [ ] Frontend loads in browser
- [ ] Can register a new user
- [ ] Can login successfully
- [ ] Can view courses
- [ ] Eureka dashboard shows all services registered
- [ ] No errors in `docker-compose logs`

---

## 🛠️ Useful Commands

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f frontend

# Check service status
docker-compose ps

# Restart a service
docker-compose restart frontend

# Stop all services
docker-compose down

# Start all services (after stopping)
docker-compose up -d

# Rebuild and start
docker-compose up -d --build

# View resource usage
docker stats

# Connect to MySQL
docker exec -it course-platform-mysql mysql -uroot -proot

# View container logs
docker logs course-platform-frontend -f

# Clean up unused images
docker image prune -a
```

---

## 🚨 Troubleshooting

### Issue: Containers keep restarting

**Solution:**
```bash
# Check logs for errors
docker-compose logs [service-name]

# Check if port is already in use
sudo netstat -tlnp | grep :3000

# Rebuild the service
docker-compose up -d --build [service-name]
```

### Issue: Out of memory errors

**Solution:**
```bash
# Check swap is enabled
free -h
swapon --show

# Restart Docker
sudo systemctl restart docker

# Clean Docker cache
docker system prune -a
```

### Issue: Can't access services from browser

**Check:**
1. Security group allows inbound traffic on required ports
2. EC2 instance is running
3. Services are actually running: `docker ps`
4. Try from EC2 itself: `curl http://localhost:3000`

### Issue: Database connection errors

**Solution:**
```bash
# Check MySQL is running
docker ps | grep mysql

# Check MySQL logs
docker-compose logs mysql

# Restart MySQL
docker-compose restart mysql

# Wait 5 minutes for MySQL to fully start
```

---

## 🔄 Updating Application

**To update with latest code:**

```bash
# Navigate to project
cd ~/course-selling-platf

# Pull latest changes
git pull origin master

# Rebuild and restart
docker-compose down
docker-compose up -d --build

# Check logs
docker-compose logs -f
```

---

## 💰 Cost Monitoring

**Free Tier (First 12 months):**
- ✅ 750 hours/month of t2.micro
- ✅ 30 GB storage
- ✅ 15 GB data transfer

**After Free Tier:**
- t2.micro: ~$8-10/month
- 30GB EBS: ~$3/month
- Data transfer: varies

**To minimize costs:**
- Stop instance when not in use
- Use smaller instance types if possible
- Monitor usage in AWS Console

---

## 📊 Monitoring

**Check health:**
```bash
# All services health
docker-compose ps

# Resource usage
docker stats

# Disk usage
df -h

# Memory usage
free -h
```

**AWS CloudWatch:**
- Monitor EC2 instance metrics
- Set up billing alerts
- Track disk and network usage

---

## 🔒 Security Notes

**Current setup is for development/testing!**

For production:
- [ ] Change all default passwords
- [ ] Use AWS RDS for database
- [ ] Set up SSL/HTTPS
- [ ] Configure firewall properly
- [ ] Enable CloudWatch monitoring
- [ ] Set up automated backups
- [ ] Use IAM roles
- [ ] Enable VPC and private subnets

---

## 📚 Next Steps

1. **Set up Domain:** Point your domain to EC2 IP
2. **SSL Certificate:** Use Let's Encrypt for HTTPS
3. **Auto-Scaling:** Configure load balancer
4. **Backup Strategy:** Automated database backups
5. **CI/CD:** GitHub Actions for auto-deployment
6. **Monitoring:** Set up alerts and dashboards

---

## ✅ Deployment Complete!

Your Course Selling Platform is now running on AWS EC2!

**Access URLs:**
- Frontend: http://YOUR_IP:3000
- API: http://YOUR_IP:8765
- Eureka: http://YOUR_IP:8761

**Questions?** Check:
- [AWS_EC2_DEPLOYMENT.md](AWS_EC2_DEPLOYMENT.md)
- [README.md](README.md)
- Docker logs: `docker-compose logs -f`

---

**Congratulations! 🎉**

