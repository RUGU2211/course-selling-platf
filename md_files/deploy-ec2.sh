#!/bin/bash
# Course Selling Platform - EC2 Deployment Script
# This script automates the deployment process on AWS EC2

set -e  # Exit on any error

echo "=========================================="
echo "Course Selling Platform - EC2 Deployment"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on EC2
if [ ! -f /sys/class/dmi/id/product-uuid ] || ! grep -q "^ec2" /sys/class/dmi/id/product-uuid; then
    print_warning "This script is designed for EC2. Proceeding anyway..."
fi

# Step 1: Update system
print_status "Step 1: Updating system packages..."
sudo yum update -y

# Step 2: Install Git if not already installed
if ! command -v git &> /dev/null; then
    print_status "Step 2: Installing Git..."
    sudo yum install git -y
else
    print_status "Step 2: Git already installed"
fi

# Step 3: Check swap space
print_status "Step 3: Checking swap space..."
if ! swapon --show | grep -q swapfile; then
    print_warning "No swap file detected. Creating 2GB swap..."
    
    # Create 2GB swap file
    sudo dd if=/dev/zero of=/swapfile bs=128M count=16
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    
    # Make it permanent
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    
    print_status "Swap file created successfully"
else
    print_status "Swap file already exists"
fi

# Display memory info
print_status "Memory information:"
free -h

# Step 4: Configure Docker if needed
print_status "Step 4: Configuring Docker..."
if [ ! -f /etc/docker/daemon.json ]; then
    print_status "Creating Docker daemon configuration..."
    sudo mkdir -p /etc/docker
    # Use a simpler configuration that works reliably on all systems
    sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    
    # Validate JSON before restarting
    if python3 -m json.tool /etc/docker/daemon.json > /dev/null 2>&1 || true; then
        print_status "Docker daemon.json is valid"
    fi
    
    # Restart Docker and check status
    if sudo systemctl restart docker; then
        print_status "Docker configured and restarted"
    else
        print_warning "Docker restart failed, checking status..."
        sudo systemctl status docker
        print_warning "Attempting to fix Docker configuration..."
        # Remove potentially problematic config
        sudo rm -f /etc/docker/daemon.json
        sudo systemctl start docker || print_error "Docker start failed"
    fi
else
    print_status "Docker configuration already exists"
fi

# Step 5: Clone repository if not already cloned
if [ ! -d "course-selling-platf" ]; then
    print_status "Step 5: Cloning repository..."
    git clone https://github.com/RUGU2211/course-selling-platf.git
    cd course-selling-platf
else
    print_status "Step 5: Repository already exists. Pulling latest changes..."
    cd course-selling-platf
    git pull origin master
fi

# Step 6: Stop any existing containers
print_status "Step 6: Stopping any existing containers..."
docker-compose down 2>/dev/null || true

# Step 7: Build and start all services
print_status "Step 7: Building and starting all services..."
print_warning "This will take 10-15 minutes. Please be patient..."

docker-compose up -d --build

# Step 8: Wait for services to start
print_status "Step 8: Waiting for services to become healthy..."
sleep 30

# Step 9: Display status
print_status "Step 9: Current status of services:"
docker-compose ps

# Step 10: Check if services are responding
print_status "Step 10: Checking service health..."

services=(
    "8761:Eureka Server"
    "8765:API Gateway"
    "3000:Frontend"
)

for service in "${services[@]}"; do
    port="${service%%:*}"
    name="${service##*:}"
    
    if curl -f -s http://localhost:$port > /dev/null 2>&1; then
        print_status "$name (port $port) is responding ✓"
    else
        print_warning "$name (port $port) is not responding yet"
    fi
done

# Step 11: Display access information
echo ""
echo "=========================================="
print_status "Deployment Complete!"
echo "=========================================="
echo ""

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "your-ec2-public-ip")

echo "Access your application at:"
echo "  Frontend:     http://$PUBLIC_IP:3000"
echo "  API Gateway:  http://$PUBLIC_IP:8765"
echo "  Eureka:       http://$PUBLIC_IP:8761"
echo ""

echo "Useful commands:"
echo "  View logs:    docker-compose logs -f"
echo "  View status:  docker-compose ps"
echo "  Stop:         docker-compose down"
echo "  Restart:      docker-compose restart [service-name]"
echo ""

print_warning "It may take 5-10 minutes for all services to fully start."
print_warning "Use 'docker-compose logs -f' to monitor progress."

echo ""
echo "=========================================="

