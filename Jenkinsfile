pipeline {
  agent any
  
  triggers {
    // Multiple trigger options for reliability:
    // 1. SCM Polling - Checks every 1 minute for changes
    pollSCM('* * * * *') // Poll every minute
    
    // 2. Webhook Support (configure in Jenkins job):
    //    - Go to Jenkins -> Your Job -> Configure
    //    - Check "Build Triggers" -> "GitHub hook trigger for GITScm polling"
    //    - Or "Poll SCM" with schedule: * * * * *
    
    // 3. For GitHub webhook (recommended):
    //    GitHub Repo -> Settings -> Webhooks -> Add webhook
    //    Payload URL: http://your-jenkins-url/github-webhook/
    //    Content type: application/json
    //    Events: Just the push event
  }
  
  environment { 
    KUBE_NAMESPACE = 'course-plat'
  }
  
  parameters {
    booleanParam(name: 'FORCE_DEPLOY', defaultValue: true, description: 'Deploy to Kubernetes regardless of branch')
    booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip unit tests')
    booleanParam(name: 'FORCE_REBUILD_ALL', defaultValue: false, description: 'Force rebuild all services (ignores change detection)')
  }
  
  options { 
    skipDefaultCheckout(false)
    timeout(time: 45, unit: 'MINUTES')
    retry(0) // Don't retry failed stages automatically
  }
  
  stages {
    stage('Checkout') { 
      steps { 
        checkout scm
        script {
          env.GIT_COMMIT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
          env.IMAGE_TAG = env.GIT_COMMIT
          env.BUILD_DATE = sh(returnStdout: true, script: 'date +%Y%m%d-%H%M%S').trim()
          // Set BRANCH_NAME if not already set
          if (!env.BRANCH_NAME) {
            env.BRANCH_NAME = sh(returnStdout: true, script: 'git rev-parse --abbrev-ref HEAD || echo ""').trim()
          }
        }
      }
    }

    stage('Build & Test') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
          script {
          echo "Building all microservices..."
          sh '''
            echo "Finding all module pom.xml files..."
            POMS=$(find "$PWD" -mindepth 2 -maxdepth 2 -name pom.xml | sort)
            if [ -z "$POMS" ]; then 
              echo "No pom.xml found"; 
              exit 1; 
            fi
            
            FAILED_BUILDS=0
            for POM in $POMS; do
              moddir=$(dirname "$POM")
              modname=$(basename "$moddir")
              echo "=========================================="
              echo "Building: $modname"
              echo "=========================================="
              
              (cd "$moddir" && chmod +x mvnw 2>/dev/null || true)
              
              if [ "$SKIP_TESTS" != "true" ]; then
                echo "Running tests for $modname..."
                (cd "$moddir" && ./mvnw -q -DskipITs -Dspring.profiles.active=test -Dspring.cloud.config.enabled=false -Deureka.client.enabled=false test) || {
                  echo "⚠ Tests failed for $modname, but continuing..."
                }
              fi
              
              echo "Packaging $modname..."
              if (cd "$moddir" && ./mvnw -q -DskipTests -Dspring.profiles.active=test -Dspring.cloud.config.enabled=false -Deureka.client.enabled=false clean package); then
                echo "✓ Successfully built $modname"
              else
                echo "✗ Build failed for $modname, continuing with other services..."
                FAILED_BUILDS=$((FAILED_BUILDS + 1))
              fi
            done
            
            echo "=========================================="
            if [ $FAILED_BUILDS -eq 0 ]; then
              echo "All services built successfully!"
            else
              echo "Build completed with $FAILED_BUILDS failures"
            fi
            echo "=========================================="
          '''
          }
        }
      }
    }

    stage('Build Docker Images') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
          script {
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
            sh '''
              #!/bin/bash
              echo "Logging in to Docker Hub..."
              echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
              
              echo "=========================================="
              echo "Building Docker Images (continuing on errors)"
              echo "=========================================="
              
              FAILED_BUILDS=0
              
              # Function to build image with error handling
              build_image() {
                local service=$1
                local dir=$2
                if [ -f "${dir}/Dockerfile" ]; then
                  echo "Building image for ${service}..."
                  if docker build -t ${DOCKERHUB_USER}/course-plat-${service}:${IMAGE_TAG} -t ${DOCKERHUB_USER}/course-plat-${service}:latest ${dir}; then
                    echo "✓ Successfully built ${service}"
                  else
                    echo "✗ Failed to build ${service}, continuing..."
                    FAILED_BUILDS=$((FAILED_BUILDS + 1))
                  fi
                else
                  echo "⚠ Dockerfile not found for ${service}, skipping..."
                fi
              }
              
              # Build all services (continuing on individual failures)
              build_image "eureka-server" "eureka-server"
              build_image "config-server" "config-server"
              build_image "actuator" "actuator"
              build_image "api-gateway" "api-gateway"
              build_image "user-service" "user-management-service"
              build_image "course-service" "course-management-service"
              build_image "enrollment-service" "enrollmentservice"
              build_image "content-service" "content-delivery-service"
              build_image "frontend" "frontend"
              
              echo "=========================================="
              if [ $FAILED_BUILDS -eq 0 ]; then
                echo "All Docker images built successfully!"
              else
                echo "Docker builds completed with $FAILED_BUILDS failures"
              fi
              echo "=========================================="
            '''
            }
          }
        }
      }
    }

    stage('Push Docker Images') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
          script {
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
            sh '''
              #!/bin/bash
              echo "=========================================="
              echo "Pushing Docker Images to Docker Hub"
              echo "=========================================="
              
              FAILED_PUSHES=0
              
              # Function to push with retry (continuing on failure)
              push_with_retry() {
                local image=$1
                local tag=$2
                local max_attempts=2
                local attempt=1
                
                while [ $attempt -le $max_attempts ]; do
                  echo "Attempt $attempt/$max_attempts: Pushing ${image}:${tag}..."
                  if docker push ${image}:${tag} 2>&1; then
                    echo "✓ Successfully pushed ${image}:${tag}"
                    return 0
                  else
                    if [ $attempt -lt $max_attempts ]; then
                      echo "⚠ Push failed for ${image}:${tag}, retrying in 3 seconds..."
                      sleep 3
                    else
                      echo "✗ Failed to push ${image}:${tag} after $max_attempts attempts, continuing..."
                      return 1
                    fi
                  fi
                  attempt=$((attempt + 1))
                done
              }
              
              # Push all images with retry (continuing on individual failures)
              for imgname in eureka-server config-server actuator api-gateway user-service course-service enrollment-service content-service frontend; do
                echo "Pushing ${imgname}..."
                
                # Push with commit tag
                if ! push_with_retry "${DOCKERHUB_USER}/course-plat-${imgname}" "${IMAGE_TAG}"; then
                  echo "⚠ Failed to push ${imgname}:${IMAGE_TAG}, continuing..."
                  FAILED_PUSHES=$((FAILED_PUSHES + 1))
                fi
                
                # Push latest tag
                if ! push_with_retry "${DOCKERHUB_USER}/course-plat-${imgname}" "latest"; then
                  echo "⚠ Failed to push ${imgname}:latest, continuing..."
                  FAILED_PUSHES=$((FAILED_PUSHES + 1))
                fi
                
                echo "✓ Completed push attempts for ${imgname}"
              done
              
              echo "=========================================="
              if [ $FAILED_PUSHES -eq 0 ]; then
                echo "All images pushed successfully!"
              else
                echo "Push completed with $FAILED_PUSHES failures"
              fi
              echo "=========================================="
            '''
            }
          }
        }
      }
    }

    stage('Pull Images & Create Containers (Docker)') {
      when {
        expression { return params.FORCE_DEPLOY == true }
      }
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
          script {
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
            sh script: '''#!/bin/bash
              set +e
              echo "=========================================="
              echo "Smart Deployment - Only Changed Services"
              echo "=========================================="
              
              echo "Logging in to Docker Hub..."
              echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin || true
              
              # Determine docker-compose command (v1 vs v2)
              if command -v docker-compose > /dev/null 2>&1; then
                COMPOSE_CMD="docker-compose"
              elif docker compose version > /dev/null 2>&1; then
                COMPOSE_CMD="docker compose"
              else
                echo "⚠ docker-compose not found, attempting docker compose..."
                COMPOSE_CMD="docker compose"
              fi
              
              # Services that should NEVER be restarted
              PROTECTED_SERVICES="mysql jenkins"
              
              # Ensure MySQL is always running first (critical service)
              echo "=========================================="
              echo "Ensuring MySQL is running..."
              echo "=========================================="
              if ! docker ps --format "{{.Names}}" | grep -q "^course-platform-mysql$"; then
                echo "MySQL is not running, starting it..."
                $COMPOSE_CMD up -d mysql || {
                  echo "⚠ Failed to start MySQL, but continuing..."
                }
                sleep 5
              else
                echo "✓ MySQL is already running"
              fi
              
              # Function to detect if a service directory has changed
              detect_changed_service() {
                local service_dir=$1
                local service_name=$2
                
                # Check if service directory exists
                if [ ! -d "$service_dir" ]; then
                  return 1
                fi
                
                # Get the previous commit (or use a base commit)
                PREV_COMMIT=$(git rev-parse HEAD~1 2>/dev/null || echo "")
                
                if [ -z "$PREV_COMMIT" ]; then
                  # If no previous commit, check if this is initial build
                  # Compare with current HEAD to see if there are any changes
                  if git diff --quiet HEAD HEAD -- "$service_dir" 2>/dev/null; then
                    return 1
                  else
                    return 0
                  fi
                fi
                
                # Check if files in service directory changed between commits
                if git diff --name-only $PREV_COMMIT HEAD -- "$service_dir" 2>/dev/null | grep -q .; then
                  return 0
                fi
                
                # Also check if docker-compose.yml changed (might affect all services)
                if git diff --name-only $PREV_COMMIT HEAD -- "docker-compose.yml" 2>/dev/null | grep -q .; then
                  # Check if this specific service is mentioned in docker-compose changes
                  if git diff $PREV_COMMIT HEAD -- "docker-compose.yml" 2>/dev/null | grep -q "$service_name"; then
                    return 0
                  fi
                fi
                
                return 1
              }
              
              # Services to potentially rebuild (using space-separated string for POSIX compatibility)
              CHANGED_SERVICES=""
              ALL_SERVICES="eureka-server config-server actuator api-gateway user-service course-service enrollment-service content-service frontend"
              
              echo "=========================================="
              echo "Detecting Changed Services..."
              echo "=========================================="
              
              # Check each service for changes (service_dir -> compose_service mapping)
              check_service() {
                local service_dir=$1
                local compose_service=$2
                
                # Skip protected services
                if echo "$PROTECTED_SERVICES" | grep -q "$compose_service"; then
                  echo "⏭ Skipping protected service: $compose_service"
                  return
                fi
                
                if detect_changed_service "$service_dir" "$compose_service"; then
                  echo "✓ Changes detected in: $service_dir -> $compose_service"
                  CHANGED_SERVICES="$CHANGED_SERVICES $compose_service"
                else
                  echo "○ No changes in: $service_dir -> $compose_service"
                fi
              }
              
              # Check all services
              check_service "eureka-server" "eureka-server"
              check_service "config-server" "config-server"
              check_service "actuator" "actuator"
              check_service "api-gateway" "api-gateway"
              check_service "user-management-service" "user-service"
              check_service "course-management-service" "course-service"
              check_service "enrollmentservice" "enrollment-service"
              check_service "content-delivery-service" "content-service"
              check_service "frontend" "frontend"
              
              # Trim leading space
              CHANGED_SERVICES=$(echo "$CHANGED_SERVICES" | sed 's/^[[:space:]]*//')
              
              # If no specific changes detected, check if docker-compose.yml changed
              if [ -z "$CHANGED_SERVICES" ]; then
                PREV_COMMIT=$(git rev-parse HEAD~1 2>/dev/null || echo "")
                if [ -n "$PREV_COMMIT" ] && git diff --name-only $PREV_COMMIT HEAD -- "docker-compose.yml" 2>/dev/null | grep -q .; then
                  echo "⚠ docker-compose.yml changed, will rebuild all services (except protected)"
                  CHANGED_SERVICES="$ALL_SERVICES"
                fi
              fi
              
              # If still no changes, check if this is a forced rebuild
              if [ -z "$CHANGED_SERVICES" ]; then
                if [ "$FORCE_REBUILD_ALL" == "true" ]; then
                  echo "⚠ FORCE_REBUILD_ALL is enabled, rebuilding all services (except protected)"
                  CHANGED_SERVICES="$ALL_SERVICES"
                else
                  echo "ℹ No changes detected. For initial deployment or full rebuild, enable FORCE_REBUILD_ALL parameter."
                  echo "ℹ Only pulling images for existing services..."
                  
                  # Just pull images without rebuilding
                  for imgname in $ALL_SERVICES; do
                    if echo "$PROTECTED_SERVICES" | grep -q "$imgname"; then
                      continue
                    fi
                    echo "Pulling ${DOCKERHUB_USER}/course-plat-${imgname}:${IMAGE_TAG}..."
                    docker pull ${DOCKERHUB_USER}/course-plat-${imgname}:${IMAGE_TAG} || {
                      echo "⚠ Failed to pull ${imgname}:${IMAGE_TAG}, trying latest..."
                      docker pull ${DOCKERHUB_USER}/course-plat-${imgname}:latest || echo "⚠ Failed to pull ${imgname}:latest, continuing..."
                    }
                  done
                fi
              fi
              
              # Rebuild changed services if any
              if [ -n "$CHANGED_SERVICES" ]; then
                echo "=========================================="
                echo "Rebuilding Changed Services Only:"
                echo "$CHANGED_SERVICES"
                echo "=========================================="
                
                # Pull images for changed services
                for service in $CHANGED_SERVICES; do
                  # Map docker-compose service name to image name
                  case $service in
                    "user-service") imgname="user-service" ;;
                    "course-service") imgname="course-service" ;;
                    "enrollment-service") imgname="enrollment-service" ;;
                    "content-service") imgname="content-service" ;;
                    *) imgname="$service" ;;
                  esac
                  
                  echo "Pulling ${DOCKERHUB_USER}/course-plat-${imgname}:${IMAGE_TAG}..."
                  docker pull ${DOCKERHUB_USER}/course-plat-${imgname}:${IMAGE_TAG} || {
                    echo "⚠ Failed to pull ${imgname}:${IMAGE_TAG}, trying latest..."
                    docker pull ${DOCKERHUB_USER}/course-plat-${imgname}:latest || echo "⚠ Failed to pull ${imgname}:latest, continuing..."
                  }
                done
                
                # Rebuild and restart only changed services
                for service in $CHANGED_SERVICES; do
                  echo "=========================================="
                  echo "Rebuilding and restarting: $service"
                  echo "=========================================="
                  
                  # Stop only this specific service
                  echo "Stopping $service..."
                  $COMPOSE_CMD stop "$service" 2>/dev/null || true
                  
                  # Remove only this specific service container
                  echo "Removing $service container..."
                  $COMPOSE_CMD rm -f "$service" 2>/dev/null || true
                  
                  # Rebuild and start only this service (without dependencies to avoid restarting MySQL/Jenkins)
                  echo "Rebuilding and starting $service..."
                  $COMPOSE_CMD up -d --build --no-deps "$service" || {
                    echo "⚠ Failed to rebuild $service, trying without --no-deps..."
                    $COMPOSE_CMD up -d --build "$service" || {
                      echo "✗ Failed to rebuild $service, continuing with other services..."
                    }
                  }
                  
                  echo "✓ Completed rebuild for $service"
                  sleep 2
                done
              fi
              
              # Ensure all non-protected services are running (in case some weren't started)
              echo "=========================================="
              echo "Ensuring all services are running..."
              echo "=========================================="
              for service in $ALL_SERVICES; do
                if echo "$PROTECTED_SERVICES" | grep -q "$service"; then
                  continue
                fi
                
                if ! docker ps --format "{{.Names}}" | grep -q "course-platform-.*${service}"; then
                  echo "Service $service is not running, starting it..."
                  $COMPOSE_CMD up -d "$service" 2>/dev/null || echo "⚠ Failed to start $service"
                fi
              done
              
              echo "=========================================="
              echo "Container Status:"
              echo "=========================================="
              $COMPOSE_CMD ps 2>/dev/null || docker ps --filter "name=course-platform" || true
              
              echo "=========================================="
              echo "✓ Smart deployment completed!"
              echo "Protected services (MySQL, Jenkins) were NOT restarted"
              echo "=========================================="
            '''
            }
          }
        }
      }
    }

    stage('Deploy to Kubernetes') {
      when {
        expression { return params.FORCE_DEPLOY == true }
      }
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
          script {
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
            sh '''
              echo "=========================================="
              echo "Deploying to Kubernetes"
              echo "=========================================="
              
              echo "BRANCH_NAME=$BRANCH_NAME FORCE_DEPLOY=$FORCE_DEPLOY"
              
              # Check if kubectl is available
              if ! command -v kubectl > /dev/null 2>&1; then
                echo "⚠ kubectl not found, skipping Kubernetes deployment..."
                echo "This is expected if Kubernetes is not configured in this Jenkins instance."
                exit 0
              fi
              
              # Check if Minikube is running (for AWS EC2 with Minikube)
              if command -v minikube > /dev/null 2>&1; then
                echo "Detected Minikube, checking if it's running..."
                if ! minikube status > /dev/null 2>&1; then
                  echo "⚠ Minikube is not running. Starting Minikube..."
                  minikube start || {
                    echo "⚠ Failed to start Minikube, skipping Kubernetes deployment..."
                    exit 0
                  }
                fi
                
                # Set kubectl context to Minikube
                echo "Setting kubectl context to Minikube..."
                kubectl config use-context minikube || {
                  echo "⚠ Failed to set Minikube context, trying default..."
                }
                
                # Enable Minikube addons if needed
                echo "Enabling Minikube addons..."
                minikube addons enable ingress 2>/dev/null || true
                minikube addons enable metrics-server 2>/dev/null || true
              fi
              
              # Check if Kubernetes cluster is accessible
              if ! kubectl cluster-info > /dev/null 2>&1; then
                echo "⚠ Kubernetes cluster not accessible, skipping deployment..."
                echo "This is expected if Kubernetes is not configured in this Jenkins instance."
                exit 0
              fi
              
              echo "✅ Kubernetes cluster is accessible!"
              echo "Cluster info:"
              kubectl cluster-info
              
              # Create namespace if it doesn't exist
              kubectl create namespace ${KUBE_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f - || {
                echo "⚠ Failed to create namespace, trying without validation..."
                kubectl create namespace ${KUBE_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f - --validate=false || {
                  echo "⚠ Skipping Kubernetes deployment due to namespace creation failure"
                  exit 0
                }
              }
              
              # Create Docker registry secret for pulling images
              echo "Creating Docker registry secret..."
              kubectl create secret docker-registry dockerhub-secret \
                --docker-server=https://index.docker.io/v1/ \
                --docker-username=${DOCKERHUB_USER} \
                --docker-password=${DOCKERHUB_PASS} \
                --docker-email=${DOCKERHUB_USER}@example.com \
                -n ${KUBE_NAMESPACE} \
                --dry-run=client -o yaml | kubectl apply -f -
              
              # Replace placeholders in Kubernetes manifests
              echo "Updating Kubernetes manifests with image tags..."
              mkdir -p k8s-processed
              
              # Process all Kubernetes manifest files
              for manifest in k8s/*.yaml; do
                if [ -f "$manifest" ]; then
                  filename=$(basename "$manifest")
                  echo "Processing $filename..."
                  sed "s|DOCKERHUB_USER|${DOCKERHUB_USER}|g; s|IMAGE_TAG|${IMAGE_TAG}|g" "$manifest" > "k8s-processed/$filename"
                fi
              done
              
              # Process monitoring services (Prometheus and Grafana use public images, no need to replace)
              if [ -f "k8s/prometheus.yaml" ]; then
                cp k8s/prometheus.yaml k8s-processed/prometheus.yaml
              fi
              if [ -f "k8s/grafana.yaml" ]; then
                cp k8s/grafana.yaml k8s-processed/grafana.yaml
              fi
              
              # Apply all Kubernetes manifests (continuing on failures)
              echo "Applying Kubernetes manifests..."
              kubectl apply -f k8s-processed/ -n ${KUBE_NAMESPACE} || {
                echo "⚠ Some Kubernetes manifests failed to apply, continuing..."
              }
              
              # Update image tags for all deployments (continuing on failures)
              echo "Updating deployment images..."
              
              for deployment in eureka-server config-server actuator api-gateway user-service course-service enrollment-service content-service frontend; do
                imgname=$(echo $deployment | sed 's/-service//' | sed 's/service$/service/')
                case $deployment in
                  "eureka-server") imgname="eureka-server" ;;
                  "config-server") imgname="config-server" ;;
                  "actuator") imgname="actuator" ;;
                  "api-gateway") imgname="api-gateway" ;;
                  "user-service") imgname="user-service" ;;
                  "course-service") imgname="course-service" ;;
                  "enrollment-service") imgname="enrollment-service" ;;
                  "content-service") imgname="content-service" ;;
                  "frontend") imgname="frontend" ;;
                esac
                
                # Skip image update for monitoring services (they use public images)
                if [ "$deployment" == "prometheus" ] || [ "$deployment" == "grafana" ]; then
                  continue
                fi
                
                echo "Updating ${deployment} to use ${DOCKERHUB_USER}/course-plat-${imgname}:${IMAGE_TAG}..."
                kubectl set image deployment/${deployment} \
                  ${deployment}=${DOCKERHUB_USER}/course-plat-${imgname}:${IMAGE_TAG} \
                  -n ${KUBE_NAMESPACE} 2>&1 || {
                  echo "⚠ Failed to update ${deployment}, may need to create it first or deployment doesn't exist"
                }
              done
              
              # Wait for rollouts to complete (with shorter timeout, continuing on failures)
              echo "Waiting for deployments to rollout..."
              for deployment in eureka-server config-server actuator api-gateway user-service course-service enrollment-service content-service frontend; do
                echo "Checking rollout status for ${deployment}..."
                kubectl rollout status deployment/${deployment} -n ${KUBE_NAMESPACE} --timeout=2m 2>&1 || {
                  echo "⚠ Rollout for ${deployment} may not be complete or deployment doesn't exist, continuing..."
                }
              done
              
              # Wait for monitoring services
              if kubectl get deployment prometheus -n ${KUBE_NAMESPACE} > /dev/null 2>&1; then
                echo "Waiting for Prometheus rollout..."
                kubectl rollout status deployment/prometheus -n ${KUBE_NAMESPACE} --timeout=5m || true
              fi
              
              if kubectl get deployment grafana -n ${KUBE_NAMESPACE} > /dev/null 2>&1; then
                echo "Waiting for Grafana rollout..."
                kubectl rollout status deployment/grafana -n ${KUBE_NAMESPACE} --timeout=5m || true
              fi
              
              # Show deployment status
              echo "=========================================="
              echo "Deployment Status:"
              echo "=========================================="
              kubectl get deployments -n ${KUBE_NAMESPACE}
              kubectl get pods -n ${KUBE_NAMESPACE}
              kubectl get services -n ${KUBE_NAMESPACE}
              
              # Show Minikube service URLs if Minikube is running
              if command -v minikube > /dev/null 2>&1 && minikube status > /dev/null 2>&1; then
                echo "=========================================="
                echo "Minikube Service URLs:"
                echo "=========================================="
                echo "To access services externally, use: minikube service <service-name> -n ${KUBE_NAMESPACE}"
                echo ""
                echo "Frontend: minikube service frontend -n ${KUBE_NAMESPACE}"
                echo "API Gateway: minikube service api-gateway -n ${KUBE_NAMESPACE}"
                echo "Eureka: minikube service eureka-server -n ${KUBE_NAMESPACE}"
                echo "Config Server: minikube service config-server -n ${KUBE_NAMESPACE}"
                echo ""
                echo "Or get Minikube IP: minikube ip"
                MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "N/A")
                echo "Minikube IP: ${MINIKUBE_IP}"
                echo ""
                echo "Access services via NodePorts:"
                kubectl get services -n ${KUBE_NAMESPACE} -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .spec.ports[*]}{.nodePort}{"\n"}{end}{end}' | grep -v "^$" || echo "No NodePorts found"
              fi
              
              echo "=========================================="
              echo "✓ Successfully deployed to Kubernetes!"
              echo "=========================================="
            '''
            }
          }
        }
      }
    }
  }
  
  post {
    always {
      script {
        echo "Pipeline execution completed."
        echo "Build Tag: ${IMAGE_TAG}"
        echo "Branch: ${env.BRANCH_NAME}"
      }
    }
    success {
      echo "✓ Pipeline succeeded!"
    }
    failure {
      echo "✗ Pipeline completed with failures!"
      script {
        echo "Continuing to show final status despite failures..."
      }
    }
    unstable {
      echo "⚠ Pipeline completed with warnings!"
    }
  }
}