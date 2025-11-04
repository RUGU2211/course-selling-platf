# Jenkins CI/CD Setup Guide

Complete guide to set up and use Jenkins for your Course Selling Platform CI/CD pipeline.

## Overview

Jenkins is configured in your `docker-compose.yml` and will run on **port 8090**.

**Access URL:** `http://YOUR_EC2_PUBLIC_IP:8090`

## Quick Start

### Step 1: Start Jenkins

Jenkins is included in your docker-compose setup:

```bash
# Start all services including Jenkins
docker-compose up -d

# OR start only Jenkins
docker-compose up -d jenkins

# Check Jenkins logs
docker logs course-platform-jenkins -f
```

**Wait 2-3 minutes** for Jenkins to fully initialize.

---

### Step 2: Access Jenkins

Open your browser and go to:
```
http://YOUR_EC2_PUBLIC_IP:8090
```

**Default Login:**
- **Setup Wizard:** Disabled (Jenkins is pre-configured)
- **No initial password required!**

---

### Step 3: Create Your First Jenkins Pipeline

#### Option A: Create Pipeline from Scratch

1. **Click "New Item"**
2. **Enter name:** `course-platform-pipeline`
3. **Select:** "Pipeline"
4. **Click "OK"**

#### Option B: Create from Jenkinsfile (Recommended)

1. **Click "New Item"**
2. **Enter name:** `course-platform-pipeline`
3. **Select:** "Pipeline"
4. **Click "OK"**
5. **Scroll to "Pipeline" section**
6. **Definition:** Select "Pipeline script from SCM"
7. **SCM:** Select "Git"
8. **Repository URL:** `https://github.com/RUGU2211/course-selling-platf.git`
9. **Branch:** `*/master`
10. **Script Path:** `Jenkinsfile`
11. **Click "Save"**

---

### Step 4: Configure Docker Hub Credentials (Required!)

Your pipeline needs Docker Hub credentials to push images.

#### A. Create Docker Hub Account (if you don't have one)
1. Go to https://hub.docker.com
2. Sign up for free account
3. Create a repository: `course-plat-eureka-server` (optional, Jenkins will create)
4. Note your username and password

#### B. Add Credentials in Jenkins

1. **Go to:** Jenkins Dashboard → Manage Jenkins → Credentials
2. **Click:** "Stores scoped to Jenkins" → "(global)"
3. **Click:** "Add Credentials"
4. **Configure:**
   - **Kind:** Username with password
   - **Scope:** Global
   - **Username:** Your Docker Hub username
   - **Password:** Your Docker Hub password
   - **ID:** `dockerhub-creds` (exact name - don't change!)
   - **Description:** Docker Hub Credentials
5. **Click:** "OK"

---

### Step 5: Configure the Pipeline

1. **Click on your pipeline** (`course-platform-pipeline`)
2. **Click:** "Configure"
3. **In "Build Triggers" section:**
   - ✅ Check "Poll SCM"
   - **Schedule:** `* * * * *` (every minute)
4. **Scroll down and click:** "Save"

---

### Step 6: Run Your First Build

1. **Click:** "Build Now"
2. **Watch progress** in the console output
3. **Wait 15-30 minutes** for first build

**What happens:**
1. ✅ Git checkout
2. ✅ Build & test all microservices
3. ✅ Build Docker images
4. ✅ Push images to Docker Hub
5. ✅ Deploy to Docker (if configured)
6. ✅ Deploy to Kubernetes (if configured)

---

## Pipeline Stages

Your Jenkins pipeline includes these stages:

### 1. Checkout
- Clones repository from GitHub
- Sets build tags and branch info

### 2. Build & Test
- Builds all 8 microservices with Maven
- Runs unit tests (can skip with parameter)
- Continues even if some tests fail

### 3. Build Docker Images
- Builds Docker images for each service
- Tags with commit hash and "latest"

### 4. Push Docker Images
- Pushes images to Docker Hub
- Retries on failure
- Uses credentials configured earlier

### 5. Deploy to Docker (Optional)
- Pulls images from Docker Hub
- Restarts containers with docker-compose
- Continues on failures

### 6. Deploy to Kubernetes (Optional)
- Applies Kubernetes manifests
- Updates deployments
- Waits for rollouts

---

## Manual Build Parameters

When running a build, you can adjust:

1. **Click:** "Build with Parameters"
2. **Configure:**
   - **FORCE_DEPLOY:** true/false (deploy to Docker/K8s)
   - **SKIP_TESTS:** true/false (skip unit tests)
3. **Click:** "Build"

---

## Monitoring Builds

### View Build History

- Go to your pipeline
- Click on build number to view details

### View Console Output

1. **Click:** On any build number
2. **Click:** "Console Output"
3. **Watch real-time logs**

### View Blue Ocean Dashboard (Recommended!)

1. **Click:** "Open Blue Ocean" (left sidebar)
2. **See visual pipeline:** beautiful UI showing each stage
3. **Click:** On any stage to see logs

---

## GitHub Webhook (Optional)

To trigger builds automatically on git push:

### On GitHub:

1. Go to: Your Repo → Settings → Webhooks
2. Click: "Add webhook"
3. **Configure:**
   - **Payload URL:** `http://YOUR_EC2_PUBLIC_IP:8090/github-webhook/`
   - **Content type:** `application/json`
   - **Events:** Just the "push" event
   - **Active:** ✅ Checked
4. **Click:** "Add webhook"

### On Jenkins:

1. Go to: Pipeline → Configure
2. In "Build Triggers":
   - ✅ Check "GitHub hook trigger for GITScm polling"
3. Click: "Save"

Now, every push to GitHub triggers a Jenkins build automatically!

---

## Troubleshooting

### Issue: Jenkins won't start

**Solution:**
```bash
# Check logs
docker logs course-platform-jenkins -f

# Check if port 8090 is available
sudo netstat -tlnp | grep 8090

# Restart Jenkins
docker restart course-platform-jenkins
```

### Issue: Pipeline fails at "Push Docker Images"

**Solution:**
1. Verify Docker Hub credentials are correct
2. Check credentials ID is exactly `dockerhub-creds`
3. Test Docker Hub login manually:
   ```bash
   docker login -u YOUR_USERNAME
   ```

### Issue: Build fails at "Build & Test"

**Solution:**
1. Check Maven installation in logs
2. Enable "SKIP_TESTS" parameter
3. Check Docker has enough memory (swap enabled)

### Issue: Can't access Jenkins UI

**Check:**
1. Security group allows port 8090
2. Jenkins container is running: `docker ps | grep jenkins`
3. Access: `http://YOUR_IP:8090` (not localhost)

### Issue: Git checkout fails

**Solution:**
1. Verify GitHub repository URL is correct
2. Check branch name: should be `*/master`
3. Ensure git is installed in Jenkins container (should be automatic)

---

## Accessing Jenkins Remotely

### Local Development Setup

If running locally with port forwarding:

```bash
# Forward port from EC2 to local
ssh -L 8090:localhost:8090 -i YOUR_KEY.pem ec2-user@YOUR_EC2_IP

# Then access Jenkins at
http://localhost:8090
```

### Production Setup

**Security warning:** Jenkins on port 8090 is NOT secure!

For production:
1. ✅ Set up firewall rules
2. ✅ Use reverse proxy (Nginx) with SSL
3. ✅ Enable Jenkins security
4. ✅ Restrict access by IP
5. ✅ Use VPN or bastion host

---

## Jenkins Plugins

Already installed in your Jenkins image:
- ✅ Git
- ✅ GitHub
- ✅ Docker Pipeline
- ✅ Blue Ocean (visual interface)
- ✅ Credentials
- ✅ Kubernetes CLI
- ✅ Workflow Aggregator

### Install More Plugins

1. **Go to:** Manage Jenkins → Plugins
2. **Available:** Browse and search
3. **Install:** Click "Install without restart"
4. **Restart:** When prompted

---

## CI/CD Pipeline Flow

```
┌─────────────────────────────────────────────────┐
│  Developer Pushes Code to GitHub                │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Jenkins Detects Change (Poll or Webhook)       │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Git Checkout                                   │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Build All Services (Maven)                     │
│  Run Unit Tests                                 │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Build Docker Images                            │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Push to Docker Hub                             │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  Deploy to Docker / Kubernetes                  │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│  ✅ Application Updated Live                    │
└─────────────────────────────────────────────────┘
```

---

## Quick Reference

### URLs

| Service | URL |
|---------|-----|
| **Jenkins** | `http://YOUR_IP:8090` |
| **Pipeline** | `http://YOUR_IP:8090/job/course-platform-pipeline` |
| **Blue Ocean** | `http://YOUR_IP:8090/blue` |
| **Manage Jenkins** | `http://YOUR_IP:8090/manage` |
| **Credentials** | `http://YOUR_IP:8090/credentials` |

### Commands

```bash
# View Jenkins logs
docker logs course-platform-jenkins -f

# Restart Jenkins
docker restart course-platform-jenkins

# Check Jenkins container
docker ps | grep jenkins

# Access Jenkins shell
docker exec -it course-platform-jenkins bash

# Rebuild Jenkins image
docker-compose build jenkins
docker-compose up -d jenkins
```

---

## Next Steps

1. ✅ Set up Docker Hub credentials
2. ✅ Create your first pipeline
3. ✅ Configure GitHub webhook (optional)
4. ✅ Enable Blue Ocean for visual pipeline
5. ✅ Set up notifications (email/Slack)
6. ✅ Configure production deployment strategy

---

## Security Checklist

For production deployment:

- [ ] Enable Jenkins security
- [ ] Create admin user account
- [ ] Restrict Jenkins access (firewall/security group)
- [ ] Use HTTPS with reverse proxy
- [ ] Rotate Docker Hub credentials regularly
- [ ] Enable pipeline security scan
- [ ] Set up backup for Jenkins data
- [ ] Monitor Jenkins logs for unauthorized access

---

## Support

**Common Issues:**
- Jenkins won't start: Check Docker logs
- Pipeline fails: Check console output
- Credentials error: Verify ID is `dockerhub-creds`
- Timeout: Increase pipeline timeout in config

**Resources:**
- Jenkins Docs: https://www.jenkins.io/doc/
- Blue Ocean: https://www.jenkins.io/doc/book/blueocean/
- Docker Hub: https://hub.docker.com

---

**Congratulations! Your CI/CD pipeline is now set up!** 🎉

