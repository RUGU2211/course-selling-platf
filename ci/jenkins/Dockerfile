FROM jenkins/jenkins:lts
USER root
# Install tools
RUN apt-get update && apt-get install -y curl ca-certificates gnupg && rm -rf /var/lib/apt/lists/*
# Install Docker CLI
# Get Debian codename from /etc/os-release instead of lsb-release (workaround for 403 error)
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg \
 && ARCH=$(dpkg --print-architecture) \
 && CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2 | tr -d '"' || echo "bookworm") \
 && echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian $CODENAME stable" > /etc/apt/sources.list.d/docker.list \
 && apt-get update && apt-get install -y docker-ce-cli && rm -rf /var/lib/apt/lists/*
# Install kubectl
RUN curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.29.6/bin/linux/amd64/kubectl \
 && chmod +x /usr/local/bin/kubectl
# Install kind
RUN curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64 \
 && chmod +x /usr/local/bin/kind
# Install required Jenkins plugins (latest)
RUN jenkins-plugin-cli --plugins \
  credentials \
  credentials-binding \
  git \
  github \
  workflow-aggregator \
  docker-workflow \
  blueocean \
  pipeline-stage-view \
  ssh-agent \
  kubernetes-cli \
  configuration-as-code
# Disable setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
# Keep as root user - docker-compose will control the user
# USER jenkins
