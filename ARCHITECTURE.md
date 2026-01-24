## 🟢 Overview
The StartTech ecosystem is a multi-tier, highly available cloud architecture designed to support a modern full-stack application (React/Golang/Redis/MongoDB). The design prioritizes **security isolation**, **horizontal scalability**, and **automated recovery**.

## 🗺 Infrastructure Map


### 1. Network Layer (VPC)
- **Segmentation:** A custom VPC (10.0.0.0/16) divided into **Public** and **Private** subnets across two Availability Zones (us-east-1a, us-east-1b).
- **Public Subnets:** House the Application Load Balancer (ALB) and NAT Gateways.
- **Private Subnets:** House the Golang EC2 instances and the Redis ElastiCache cluster, ensuring no direct exposure to the public internet.

### 2. Compute & Scaling (Golang API)
- **Auto Scaling Group (ASG):** Automatically adjusts the number of EC2 instances based on CPU utilization.
- **Launch Template:** Defines the Dockerized environment and pulls the latest Golang image from Amazon ECR upon instance launch.
- **Load Balancing:** The ALB performs health checks on port 8080. If an instance fails, the ASG terminates it and launches a fresh replacement.

### 3. Data & Caching
- **Redis (ElastiCache):** A clustered Redis setup used for session persistence and API response caching to reduce database load.
- **MongoDB Atlas:** A managed NoSQL database (external to AWS VPC) accessed via secure connection strings stored in GitHub Secrets.

### 4. Content Delivery (Frontend)
- **S3:** Acts as the origin server for the React static assets.
- **CloudFront:** Provides a global CDN edge network, terminating SSL/TLS and serving assets with low latency.

## 🔒 Security Posture
- **Least Privilege IAM:** EC2 instances use an IAM Role with a policy limited to `ecr:GetDownloadUrlForLayer` and `logs:PutLogEvents`.
- **Security Groups:** - **ALB SG:** Allows 80/443 from 0.0.0.0/0.
  - **App SG:** Allows port 8080 ONLY from the ALB SG.
  - **Redis SG:** Allows port 6379 ONLY from the App SG.


### Manual Infrastructure Update
If the CI/CD pipeline is unavailable, infra can be updated locally:
1. `cd terraform`
2. `terraform plan -out=tfplan`
3. `terraform apply tfplan`

### Scaling the Backend
To manually scale the API (e.g., for an expected traffic spike):
```bash
aws autoscaling update-auto-scaling-group --auto-scaling-group-name starttech-backend-asg --desired-capacity 5
🔍 Troubleshooting Scenarios
🚨 Scenario 1: Backend Health Check Failures
Symptoms: ALB returns 502 Bad Gateway; ASG is constantly replacing instances.

Investigation:

Check CloudWatch Logs: /aws/ec2/starttech-backend.

Verify the Golang app is starting on port 8080 within the container.

Ensure the Security Group allows traffic from the ALB on port 8080.

🚨 Scenario 2: Redis Connection Refused
Symptoms: API logs show Redis connection timeout.

Investigation:

Confirm the Redis Endpoint in Terraform outputs matches the app configuration.

Verify the App Security Group is whitelisted in the Redis Security Group (Port 6379).

🚨 Scenario 3: CloudFront 403 Access Denied
Symptoms: Frontend does not load; S3 returns 403.

Fix: Invalidate the CloudFront cache:

Bash

aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"
🛠 Maintenance Tasks
Log Analysis
To query error rates in the last hour via CloudWatch Insights:

SQL

fields @timestamp, @message
| filter @message like /error/
| sort @timestamp desc
Emergency Rollback
If a deployment fails, revert the last commit in Git. The CI/CD pipeline will automatically build and push the previous stable Docker image, and the ASG will perform a rolling update to the stable version.