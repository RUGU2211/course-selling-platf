#!/bin/bash
set -e

echo "=========================================="
echo "Installing Jenkins locally on EC2"
echo "=========================================="

# Install Java 21 (required for Jenkins LTS)
echo "Installing Java 21..."
sudo yum update -y
sudo yum install -y java-21-amazon-corretto

# Install Jenkins
echo "Installing Jenkins..."
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins

# Install Docker CLI (if not already installed)
if ! command -v docker &> /dev/null; then
    echo "Installing Docker CLI..."
    sudo yum install -y docker
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker ec2-user
fi

# Install kubectl (if not already installed)
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
fi

# Create Jenkins home directory
echo "Setting up Jenkins home directory..."
sudo mkdir -p /var/lib/jenkins
sudo mkdir -p /var/cache/jenkins
sudo mkdir -p /var/log/jenkins
sudo chown -R ec2-user:ec2-user /var/lib/jenkins
sudo chown -R ec2-user:ec2-user /var/cache/jenkins
sudo chown -R ec2-user:ec2-user /var/log/jenkins

# Migrate data from Docker volume if it exists
if docker volume inspect course-selling-platf_jenkins_home &> /dev/null; then
    echo "Migrating Jenkins data from Docker volume..."
    docker run --rm -v course-selling-platf_jenkins_home:/source -v /var/lib/jenkins:/target busybox sh -c "cp -r /source/* /target/ 2>/dev/null || true"
    sudo chown -R ec2-user:ec2-user /var/lib/jenkins
fi

# Configure Jenkins port to 8090
echo "Configuring Jenkins to use port 8090..."
sudo sed -i 's/JENKINS_PORT=8080/JENKINS_PORT=8090/g' /etc/sysconfig/jenkins || true

# Add Jenkins configuration for Docker and Kubernetes access
echo "Configuring Jenkins environment..."
sudo mkdir -p /etc/sysconfig
sudo tee -a /etc/sysconfig/jenkins > /dev/null <<EOF

# Docker access
DOCKER_HOST=unix:///var/run/docker.sock

# Kubernetes access
KUBECONFIG=/home/ec2-user/.kube/config
EOF

# Configure Jenkins to run as ec2-user (to access Docker and kubectl)
echo "Configuring Jenkins user..."
sudo sed -i 's/JENKINS_USER="jenkins"/JENKINS_USER="ec2-user"/g' /etc/sysconfig/jenkins || true

# Add ec2-user to docker group (if not already added)
sudo usermod -aG docker ec2-user

# Ensure kubeconfig is accessible
echo "Setting up kubeconfig..."
if [ -f /home/ec2-user/.kube/config ]; then
    sudo chown ec2-user:ec2-user /home/ec2-user/.kube/config
    chmod 600 /home/ec2-user/.kube/config
fi

# Create systemd service override to set environment variables
echo "Creating systemd service override..."
sudo mkdir -p /etc/systemd/system/jenkins.service.d
sudo tee /etc/systemd/system/jenkins.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="JENKINS_PORT=8090"
Environment="JAVA_OPTS=-Djenkins.install.runSetupWizard=false -DhttpPort=8090"
Environment="DOCKER_HOST=unix:///var/run/docker.sock"
Environment="KUBECONFIG=/home/ec2-user/.kube/config"
User=ec2-user
Group=ec2-user
EOF

# Clean up any existing cache directories with wrong ownership
echo "Cleaning up Jenkins cache directories..."
sudo rm -rf /var/cache/jenkins/war 2>/dev/null || true
sudo mkdir -p /var/cache/jenkins/war
sudo chown -R ec2-user:ec2-user /var/cache/jenkins

# Update Jenkins config.xml if it exists
if [ -f /var/lib/jenkins/config.xml ]; then
    echo "Updating Jenkins config.xml to use port 8090..."
    sudo sed -i 's/<port>8080<\/port>/<port>8090<\/port>/g' /var/lib/jenkins/config.xml
    sudo sed -i 's/<httpPort>8080<\/httpPort>/<httpPort>8090<\/httpPort>/g' /var/lib/jenkins/config.xml
    sudo chown ec2-user:ec2-user /var/lib/jenkins/config.xml
fi

# Stop Jenkins if it's running (to apply changes)
echo "Stopping Jenkins if running..."
sudo systemctl stop jenkins 2>/dev/null || true

# Reload systemd and start Jenkins
echo "Starting Jenkins service..."
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
sleep 30

# Wait for Jenkins to be fully ready (check if it's responding)
echo "Waiting for Jenkins to be ready..."
for i in {1..30}; do
  if curl -s http://localhost:8090 > /dev/null 2>&1; then
    echo "Jenkins is ready!"
    break
  fi
  echo "Waiting for Jenkins... ($i/30)"
  sleep 2
done

# Install Jenkins plugins
echo "Installing Jenkins plugins..."
JENKINS_CLI="/usr/lib/jenkins/jenkins-cli.jar"
JENKINS_URL="http://localhost:8090"

# Wait for Jenkins to be fully initialized
sleep 10

# Get initial admin password if needed
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
  INITIAL_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
  echo "Initial admin password: $INITIAL_PASSWORD"
fi

# Install plugins using Jenkins CLI (if available) or via script
PLUGINS="workflow-aggregator pipeline-stage-view git github docker-workflow blueocean kubernetes-cli configuration-as-code credentials credentials-binding ssh-agent"

# Try to install plugins via Jenkins CLI
if [ -f "$JENKINS_CLI" ]; then
  echo "Installing plugins via Jenkins CLI..."
  for plugin in $PLUGINS; do
    echo "Installing $plugin..."
    java -jar "$JENKINS_CLI" -s "$JENKINS_URL" install-plugin "$plugin" -deploy || echo "⚠ Failed to install $plugin via CLI"
  done
  
  echo "Restarting Jenkins to apply plugins..."
  sudo systemctl restart jenkins
  sleep 30
else
  echo "⚠ Jenkins CLI not found. Please install plugins manually:"
  echo "   Go to: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'localhost'):8090/pluginManager/available"
  echo "   Install these plugins: $PLUGINS"
fi

# Check Jenkins status
echo "=========================================="
echo "Jenkins Installation Complete!"
echo "=========================================="
echo "Jenkins Status:"
sudo systemctl status jenkins --no-pager | head -10

echo ""
echo "Jenkins should be accessible at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8090"
echo "Or locally: http://localhost:8090"
echo ""
echo "To check Jenkins logs: sudo journalctl -u jenkins -f"
echo "To restart Jenkins: sudo systemctl restart jenkins"

