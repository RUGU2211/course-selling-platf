#!/bin/bash
set -e

echo "=========================================="
echo "Fixing Jenkins Service Configuration"
echo "=========================================="

# Stop Jenkins
echo "Stopping Jenkins..."
sudo systemctl stop jenkins 2>/dev/null || true

# Fix permissions - Jenkins needs to run as jenkins user OR ec2-user
# Since we need Docker access, we'll keep it as ec2-user but fix permissions

# Option 1: Run as jenkins user (default) - requires Docker socket permissions
# Option 2: Run as ec2-user - requires fixing all directories

echo "Fixing directory permissions..."

# Make sure ec2-user is in docker group
sudo usermod -aG docker ec2-user

# Fix Jenkins directories ownership
sudo chown -R ec2-user:ec2-user /var/lib/jenkins
sudo chown -R ec2-user:ec2-user /var/cache/jenkins
sudo chown -R ec2-user:ec2-user /var/log/jenkins

# Clean up cache directory
sudo rm -rf /var/cache/jenkins/war
sudo mkdir -p /var/cache/jenkins/war
sudo chown -R ec2-user:ec2-user /var/cache/jenkins

# Fix Docker socket permissions (allow ec2-user to access)
sudo chmod 666 /var/run/docker.sock || true
sudo chgrp docker /var/run/docker.sock || true

# Update systemd service override
echo "Updating systemd service override..."
sudo mkdir -p /etc/systemd/system/jenkins.service.d
sudo tee /etc/systemd/system/jenkins.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="JENKINS_PORT=8090"
Environment="JAVA_OPTS=-Djenkins.install.runSetupWizard=false -DhttpPort=8090"
Environment="DOCKER_HOST=unix:///var/run/docker.sock"
Environment="KUBECONFIG=/home/ec2-user/.kube/config"
Environment="JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto.x86_64"
User=ec2-user
Group=ec2-user
EOF

# Update Jenkins config.xml to use port 8090 if it exists
if [ -f /var/lib/jenkins/config.xml ]; then
  echo "Updating Jenkins config.xml to use port 8090..."
  sudo sed -i 's/<port>8080<\/port>/<port>8090<\/port>/g' /var/lib/jenkins/config.xml
  sudo sed -i 's/<httpPort>8080<\/httpPort>/<httpPort>8090<\/httpPort>/g' /var/lib/jenkins/config.xml
  sudo chown ec2-user:ec2-user /var/lib/jenkins/config.xml
fi

# Reload systemd and start Jenkins
echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Starting Jenkins..."
sudo systemctl start jenkins

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
sleep 20

# Check status
echo "=========================================="
echo "Jenkins Status:"
echo "=========================================="
sudo systemctl status jenkins --no-pager | head -15

# Check if Jenkins is listening on port 8090
echo ""
echo "Checking if Jenkins is listening on port 8090..."
sudo netstat -tlnp | grep 8090 || sudo ss -tlnp | grep 8090 || echo "Jenkins not listening on 8090 yet"

# Check logs if there are errors
echo ""
echo "Recent Jenkins logs:"
sudo journalctl -u jenkins -n 20 --no-pager || echo "No logs available"

