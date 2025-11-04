#!/bin/bash
set -e

echo "=========================================="
echo "Installing Jenkins Plugins"
echo "=========================================="

JENKINS_URL="http://localhost:8090"
JENKINS_CLI="/usr/lib/jenkins/jenkins-cli.jar"

# Required plugins for the pipeline
PLUGINS="workflow-aggregator pipeline-stage-view git github docker-workflow blueocean kubernetes-cli configuration-as-code credentials credentials-binding ssh-agent"

# Check if Jenkins is running
if ! curl -s "$JENKINS_URL" > /dev/null 2>&1; then
    echo "❌ Jenkins is not running. Please start Jenkins first:"
    echo "   sudo systemctl start jenkins"
    exit 1
fi

echo "Jenkins is running at $JENKINS_URL"

# Method 1: Install via Jenkins CLI (if available)
if [ -f "$JENKINS_CLI" ]; then
    echo "Installing plugins via Jenkins CLI..."
    
    # Get initial admin password if needed
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        INITIAL_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
        echo "Using initial admin password..."
        
        for plugin in $PLUGINS; do
            echo "Installing $plugin..."
            java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth admin:"$INITIAL_PASSWORD" install-plugin "$plugin" -deploy || \
            java -jar "$JENKINS_CLI" -s "$JENKINS_URL" install-plugin "$plugin" -deploy || \
            echo "⚠ Failed to install $plugin"
        done
        
        echo "Restarting Jenkins..."
        java -jar "$JENKINS_CLI" -s "$JENKINS_URL" -auth admin:"$INITIAL_PASSWORD" safe-restart || \
        sudo systemctl restart jenkins
        
        echo "Waiting for Jenkins to restart..."
        sleep 30
    else
        echo "⚠ Initial admin password not found. Install plugins manually via web UI."
    fi
else
    echo "⚠ Jenkins CLI not found at $JENKINS_CLI"
fi

# Method 2: Install via web UI (manual instructions)
echo ""
echo "=========================================="
echo "Manual Installation Instructions:"
echo "=========================================="
echo "1. Go to: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'localhost'):8090"
echo "2. Login with admin and initial password (if needed):"
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo "   Password: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)"
fi
echo "3. Go to: Manage Jenkins -> Plugins -> Available plugins"
echo "4. Search and install these plugins:"
for plugin in $PLUGINS; do
    echo "   - $plugin"
done
echo "5. Restart Jenkins after installation"
echo ""
echo "Or use Jenkins REST API:"
echo "curl -X POST -u admin:PASSWORD $JENKINS_URL/pluginManager/installNecessaryPlugins -d '<install plugin=\"workflow-aggregator@latest\" />'"
echo ""
echo "=========================================="

