# AWS EC2 Setup Guide - Before Starting Deployment

Complete pre-deployment guide to set up your AWS EC2 instance for the Course Selling Platform.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Account Setup](#aws-account-setup)
3. [EC2 Instance Creation](#ec2-instance-creation)
4. [Security Group Configuration](#security-group-configuration)
5. [Key Pair Setup](#key-pair-setup)
6. [Network Configuration](#network-configuration)
7. [Storage Configuration](#storage-configuration)
8. [IAM Roles (Optional)](#iam-roles-optional)
9. [Instance Configuration Summary](#instance-configuration-summary)
10. [Verification Checklist](#verification-checklist)

---

## Prerequisites

### Required Items
- [ ] AWS Account (Free Tier eligible for 12 months)
- [ ] Valid email address for AWS account
- [ ] Credit card or debit card (may be charged after free tier expires)
- [ ] Access to AWS Management Console
- [ ] Basic understanding of SSH connections

### What You'll Create
- EC2 Instance (t2.micro - Free Tier)
- Security Group with all required rules
- Key Pair (.pem file) for SSH access
- Elastic IP (optional but recommended)

---

## AWS Account Setup

### Step 1: Create AWS Account

1. Go to [https://aws.amazon.com/](https://aws.amazon.com/)
2. Click **"Create an AWS Account"**
3. Fill in your details:
   - Email address
   - Account name
   - Password
4. Complete verification (phone number required)
5. Add payment information (required but won't be charged within Free Tier limits)

### Step 2: Verify Free Tier Eligibility

- AWS Free Tier includes:
  - **750 hours/month** of t2.micro instance (for 12 months)
  - **30 GB** of EBS storage
  - **15 GB** of data transfer out
  - **2 million** I/O requests

**⚠️ Important:** Monitor your usage to avoid charges!

### Step 3: Set Up Billing Alerts

1. Go to **Billing & Cost Management**
2. Click **"Preferences"**
3. Enable **"Receive Billing Alerts"**
4. Go to **CloudWatch** → **Billing Alarms**
5. Create alarm for $5 threshold (or your preferred amount)

---

## EC2 Instance Creation

### Step 1: Launch EC2 Instance

1. Login to [AWS Console](https://console.aws.amazon.com/)
2. Navigate to **EC2** service
3. Click **"Launch Instance"** button

### Step 2: Configure Instance Details

#### **Name and Tags**
- **Name:** `course-selling-platform` (or your preferred name)
- **Tags:** Add tags for organization:
  - `Project: course-platform`
  - `Environment: development`

#### **Application and OS Images (Amazon Machine Image)**
- **AMI:** Select **Amazon Linux 2023 AMI** (Free Tier eligible)
- **Architecture:** x86_64
- **Version:** Latest (recommended)

#### **Instance Type**
- **Instance type:** `t2.micro` (Free Tier eligible)
- **Specifications:**
  - 1 vCPU
  - 1 GB RAM
  - Network Performance: Low to Moderate
  - EBS-Optimized: No

**⚠️ Important:** t2.micro has only 1GB RAM. You MUST create swap space later!

#### **Key Pair (Login)**
- Click **"Create new key pair"**
- **Name:** `course-platform-key-pair`
- **Key pair type:** RSA
- **Private key file format:** `.pem` (for OpenSSH)
- Click **"Create key pair"**
- **⚠️ CRITICAL:** Download the `.pem` file immediately - you can't download it again!

**Save the `.pem` file securely:**
- Save to: `C:\Users\YourName\Downloads\course-platform-key-pair.pem`
- **DO NOT** share or lose this file!

#### **Network Settings**
- **VPC:** Default VPC (or create new if needed)
- **Subnet:** Any availability zone
- **Auto-assign Public IP:** **Enable** (required for SSH access)
- **Firewall (security groups):** Select **"Create security group"**
  - We'll configure this in detail below

#### **Configure Storage**
- **Volume Type:** General Purpose SSD (gp3)
- **Size:** 20 GB (minimum recommended for Docker images)
- **IOPS:** 3000 (default)
- **Throughput:** 125 MB/s (default)
- **Volume Name:** `course-platform-root-volume`
- **Delete on Termination:** Keep checked if you want automatic cleanup

**💡 Tip:** You can increase later, but 20GB is minimum for Docker builds.

#### **Advanced Details (Optional)**
- **IAM instance profile:** None (or create role if needed)
- **Shutdown behavior:** Stop
- **Stop - Hibernate behavior:** Disabled
- **Enable termination protection:** **Enable** (prevents accidental deletion)
- **Monitoring:** **Disable** detailed monitoring (costs extra)
- **Tenancy:** Shared

### Step 3: Review and Launch

1. Review all settings
2. Click **"Launch Instance"**
3. Wait for instance to be in **"Running"** state
4. Note your **Public IPv4 address** - you'll need this!

---

## Security Group Configuration

### Step 1: Access Security Groups

1. In EC2 Console, click **"Security Groups"** (left sidebar)
2. Find your security group (named like: `launch-wizard-1`)
3. Click on the security group name

### Step 2: Add Inbound Rules

Click **"Edit inbound rules"** and add the following rules:

#### **Rule 1: SSH (Required for Access)**
- **Type:** SSH
- **Protocol:** TCP
- **Port Range:** 22
- **Source:** My IP (recommended) OR Custom `0.0.0.0/0` (less secure)
- **Description:** Allow SSH access from my IP

#### **Rule 2: Frontend Application**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 3000
- **Source:** `0.0.0.0/0` (or restrict to your IP)
- **Description:** Frontend React application

#### **Rule 3: API Gateway**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 8765
- **Source:** `0.0.0.0/0` (or restrict to your IP)
- **Description:** API Gateway - main API endpoint

#### **Rule 4: Eureka Service Discovery**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 8761
- **Source:** `0.0.0.0/0` (or restrict to your IP)
- **Description:** Eureka Service Registry Dashboard

#### **Rule 5: Config Server**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 8888
- **Source:** `0.0.0.0/0` (or restrict to your IP)
- **Description:** Spring Cloud Config Server

#### **Rule 6: Actuator Service**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 8081
- **Source:** `0.0.0.0/0` (or restrict to your IP)
- **Description:** Spring Boot Actuator Service

#### **Rule 7: User Management Service**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 8082
- **Source:** `0.0.0.0/0` (or restrict to your IP)
- **Description:** User Management Microservice

#### **Rule 8: Course Management Service**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 8083
- **Source:** `0.0.0.0/0` (or restrict to your IP)
- **Description:** Course Management Microservice

#### **Rule 9: Enrollment Service**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 8084
- **Source:** `0.0.0.0/0` (or restrict to your IP)
- **Description:** Enrollment Microservice

#### **Rule 10: Content Delivery Service**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 8087
- **Source:** `0.0.0.0/0` (or restrict to your IP)
- **Description:** Content Delivery Microservice

#### **Rule 11: MySQL Database (Optional - for direct access)**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 3307
- **Source:** `0.0.0.0/0` (⚠️ **NOT RECOMMENDED FOR PRODUCTION**)
  - **Better:** Restrict to your IP only for development
- **Description:** MySQL Database (external port)

**⚠️ Security Warning:** Opening MySQL to 0.0.0.0/0 is unsafe for production!
- For production: Remove this rule or restrict to specific IPs
- Better: Don't expose MySQL publicly, use only Docker internal network

#### **Rule 12: Jenkins CI/CD**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 8090
- **Source:** `0.0.0.0/0` (or restrict to your IP)
- **Description:** Jenkins CI/CD Server

#### **Rule 13: Prometheus Monitoring**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 9090
- **Source:** `0.0.0.0/0` (or restrict to your IP)
- **Description:** Prometheus Metrics Collection

#### **Rule 14: Grafana Dashboards**
- **Type:** Custom TCP
- **Protocol:** TCP
- **Port Range:** 3030
- **Source:** `0.0.0.0/0` (or restrict to your IP)
- **Description:** Grafana Visualization Dashboard

### Step 3: Outbound Rules (Default)

Default outbound rules allow all traffic (0.0.0.0/0), which is fine for this setup.

**For production:** Restrict outbound to specific ports/domains.

### Step 4: Save Rules

Click **"Save rules"** after adding all rules.

### Complete Security Group Rules Summary

| Type | Protocol | Port | Source | Description |
|------|----------|------|--------|-------------|
| SSH | TCP | 22 | Your IP / 0.0.0.0/0 | SSH Access |
| Custom TCP | TCP | 3000 | 0.0.0.0/0 | Frontend |
| Custom TCP | TCP | 8765 | 0.0.0.0/0 | API Gateway |
| Custom TCP | TCP | 8761 | 0.0.0.0/0 | Eureka |
| Custom TCP | TCP | 8888 | 0.0.0.0/0 | Config Server |
| Custom TCP | TCP | 8081 | 0.0.0.0/0 | Actuator |
| Custom TCP | TCP | 8082 | 0.0.0.0/0 | User Service |
| Custom TCP | TCP | 8083 | 0.0.0.0/0 | Course Service |
| Custom TCP | TCP | 8084 | 0.0.0.0/0 | Enrollment Service |
| Custom TCP | TCP | 8087 | 0.0.0.0/0 | Content Service |
| Custom TCP | TCP | 3307 | Your IP only | MySQL (optional) |
| Custom TCP | TCP | 8090 | 0.0.0.0/0 | Jenkins |
| Custom TCP | TCP | 9090 | 0.0.0.0/0 | Prometheus |
| Custom TCP | TCP | 3030 | 0.0.0.0/0 | Grafana |

---

## Key Pair Setup

### Step 1: Download Key Pair (if not done)

- Already downloaded during instance creation? Skip to Step 2.
- If not, you cannot download it again - create a new instance with new key pair.

### Step 2: Secure Key Pair File (Windows)

1. **Move key to secure location:**
   ```powershell
   # Create directory for keys
   mkdir C:\Users\YourName\.ssh
   
   # Move key file
   move C:\Users\YourName\Downloads\course-platform-key-pair.pem C:\Users\YourName\.ssh\
   ```

2. **Set correct permissions (Important!):**
   ```powershell
   # Right-click on .pem file
   # Properties → Security → Advanced
   # Remove all users except yourself
   # Give yourself "Full Control"
   ```

### Step 3: Test SSH Connection

**From Windows PowerShell:**
```powershell
# Navigate to key location
cd C:\Users\YourName\.ssh

# Test SSH connection
ssh -i course-platform-key-pair.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

**Replace:**
- `YOUR_EC2_PUBLIC_IP` with your actual EC2 public IP

**Expected Output:**
```
The authenticity of host 'XXX.XXX.XXX.XXX' can't be established.
Are you sure you want to continue connecting (yes/no)? yes
       __|  __|_  )
       _|  (     /   Amazon Linux 2023 AMI
      ___|\___|___|
```

**✅ If successful, you're connected!**

---

## Network Configuration

### Default VPC Configuration

If using default VPC (recommended for beginners):

- **VPC CIDR:** 172.31.0.0/16
- **Subnet:** Automatically assigned
- **Internet Gateway:** Enabled by default
- **Route Table:** Default routes (0.0.0.0/0 → Internet Gateway)

### Custom VPC (Advanced - Optional)

Only needed if you require custom networking:

1. **Create VPC:**
   - CIDR: 10.0.0.0/16
   - Enable DNS hostnames
   - Enable DNS resolution

2. **Create Public Subnet:**
   - CIDR: 10.0.1.0/24
   - Availability Zone: Same as instance
   - Auto-assign public IP: Enable

3. **Create Internet Gateway:**
   - Attach to VPC

4. **Create Route Table:**
   - Add route: 0.0.0.0/0 → Internet Gateway
   - Associate with public subnet

**💡 Recommendation:** Use default VPC for simplicity.

---

## Storage Configuration

### EBS Volume Setup

#### **Root Volume (Already Created)**
- **Type:** gp3 (General Purpose SSD)
- **Size:** 20 GB (minimum)
- **Encryption:** Can enable for production
- **Delete on Termination:** Your choice

#### **Additional Volume (Optional - Not Required)**

If you need more storage:

1. Go to **EC2** → **Volumes**
2. Click **"Create Volume"**
3. **Volume Type:** gp3
4. **Size:** Add as needed
5. **Availability Zone:** Must match instance AZ
6. Click **"Create Volume"**
7. Attach to instance:
   - Right-click volume → **Attach Volume**
   - Select your instance
   - Device: `/dev/sdf` (example)

### Storage Requirements

**Estimated Storage Needs:**
- Docker images: ~5-8 GB
- Application code: ~500 MB
- MySQL data: ~1-2 GB
- Logs: ~1 GB
- System files: ~2 GB
- **Total:** ~20 GB minimum recommended

---

## IAM Roles (Optional)

### Basic Setup (Not Required)

For basic deployment, IAM roles are not required. The default instance profile is sufficient.

### Create IAM Role (Advanced - Optional)

If you need AWS services access:

1. Go to **IAM** → **Roles** → **Create Role**
2. **Trusted entity:** EC2
3. **Permissions:** 
   - CloudWatchReadOnlyAccess (for monitoring)
   - AmazonS3ReadOnlyAccess (if needed)
4. **Role name:** `ec2-monitoring-role`
5. Attach to instance:
   - EC2 → Instances → Select instance
   - Actions → Security → Modify IAM role
   - Select your role

---

## Instance Configuration Summary

### Final Instance Specifications

```
Instance Name: course-selling-platform
AMI: Amazon Linux 2023 AMI
Instance Type: t2.micro
vCPU: 1
RAM: 1 GB
Storage: 20 GB gp3
Network: Default VPC
Public IP: [Your IP Address]
Security Group: [Your Security Group Name]
Key Pair: course-platform-key-pair.pem
```

### Required Ports Open

✅ **All 14 ports configured in security group:**
- 22 (SSH)
- 3000 (Frontend)
- 8765 (API Gateway)
- 8761 (Eureka)
- 8888 (Config Server)
- 8081 (Actuator)
- 8082 (User Service)
- 8083 (Course Service)
- 8084 (Enrollment Service)
- 8087 (Content Service)
- 3307 (MySQL - optional)
- 8090 (Jenkins)
- 9090 (Prometheus)
- 3030 (Grafana)

---

## Verification Checklist

Before proceeding to deployment, verify all items:

### AWS Account
- [ ] AWS account created and verified
- [ ] Free Tier eligible (checked)
- [ ] Billing alerts configured
- [ ] Payment method added

### EC2 Instance
- [ ] Instance created (t2.micro)
- [ ] Instance status: **Running**
- [ ] Public IP address noted
- [ ] Instance in default VPC
- [ ] Storage: 20 GB minimum
- [ ] Termination protection enabled (optional)

### Security Group
- [ ] Security group created
- [ ] All 14 inbound rules added
- [ ] SSH rule allows your IP
- [ ] Outbound rules allow all (default)
- [ ] Security group attached to instance

### Key Pair
- [ ] Key pair created
- [ ] `.pem` file downloaded
- [ ] Key file saved securely
- [ ] Key permissions set correctly
- [ ] SSH connection tested and working

### Network
- [ ] Public IP address assigned
- [ ] Internet Gateway attached (default VPC)
- [ ] Route table configured correctly
- [ ] Can access instance via SSH

### Documentation
- [ ] Public IP address saved
- [ ] Key pair path noted
- [ ] Security group name noted
- [ ] Instance ID noted

---

## Security Best Practices

### ⚠️ Important Security Recommendations

1. **SSH Access:**
   - ✅ Restrict SSH (port 22) to your IP only
   - ❌ Don't allow 0.0.0.0/0 for SSH

2. **Database Access:**
   - ❌ Don't expose MySQL (3307) to 0.0.0.0/0 in production
   - ✅ Use Docker internal network only
   - ✅ If needed, restrict to specific IPs

3. **Jenkins:**
   - ⚠️ Change default password immediately
   - ✅ Restrict to your IP if possible

4. **Monitoring Ports:**
   - ⚠️ Grafana and Prometheus should have authentication
   - ✅ Change default passwords

5. **Firewall (EC2 Level):**
   - After deployment, consider installing `ufw` or `firewalld`
   - Configure iptables if needed

### Production Security Checklist

For production deployment:
- [ ] Use AWS RDS instead of Docker MySQL
- [ ] Enable SSL/TLS (HTTPS)
- [ ] Use Application Load Balancer
- [ ] Restrict all ports to specific IPs
- [ ] Enable CloudWatch monitoring
- [ ] Set up VPC with private subnets
- [ ] Use IAM roles for permissions
- [ ] Enable encryption at rest
- [ ] Regular security updates
- [ ] Implement WAF (Web Application Firewall)

---

## Next Steps

Once all items are verified, proceed to:

1. **Connect to EC2:** Follow [AWS_EC2_DEPLOYMENT.md](AWS_EC2_DEPLOYMENT.md)
2. **Install Dependencies:** Docker, Docker Compose, Git
3. **Clone Repository:** Your project repository
4. **Deploy Services:** Run docker-compose up

---

## Troubleshooting

### Can't SSH to Instance

**Check:**
1. Security group allows port 22 from your IP
2. Instance is in "Running" state
3. Key file permissions are correct
4. Correct username: `ec2-user` (Amazon Linux)
5. Correct public IP address

**Test:**
```powershell
ssh -v -i course-platform-key-pair.pem ec2-user@YOUR_IP
```

### Can't Access Application Ports

**Check:**
1. Security group has rule for the port
2. Instance is running
3. Correct public IP
4. Services are actually running on EC2

**Test from EC2:**
```bash
curl http://localhost:3000
```

### Instance Not Accessible

**Check:**
1. Internet Gateway attached to VPC
2. Route table has default route (0.0.0.0/0)
3. Public IP assigned
4. Security group rules correct

---

## Cost Estimation

### Free Tier (First 12 Months)
- ✅ EC2 t2.micro: 750 hours/month FREE
- ✅ EBS Storage: 30 GB FREE
- ✅ Data Transfer: 15 GB out FREE
- **Total:** $0/month (within limits)

### After Free Tier Expires
- EC2 t2.micro: ~$8-10/month
- 20 GB EBS gp3: ~$1.60/month
- Data transfer: Varies
- **Estimated:** ~$10-15/month

**💡 Tip:** Stop instance when not in use to save costs!

---

## Additional Resources

- **AWS EC2 Documentation:** [https://docs.aws.amazon.com/ec2/](https://docs.aws.amazon.com/ec2/)
- **AWS Free Tier:** [https://aws.amazon.com/free/](https://aws.amazon.com/free/)
- **Security Best Practices:** [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

---

## Support

If you encounter issues:
1. Check AWS EC2 Console for instance status
2. Review Security Group rules
3. Check CloudWatch for instance metrics
4. Verify key pair permissions
5. Review AWS documentation

---

**✅ You're ready to proceed to deployment!**

Next: Follow [AWS_EC2_DEPLOYMENT.md](AWS_EC2_DEPLOYMENT.md) for installation and deployment steps.

---

**Last Updated:** 2024
**Platform:** Course Selling Platform
**Environment:** Development/Testing

