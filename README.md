## 🎖 Executive Summary
As a Senior DevOps Engineer at StartTech, I have architected and implemented a robust, scalable, and fully automated cloud ecosystem. This project transitions the StartTech stack into a professional **GitOps-driven environment**, utilizing Infrastructure as Code (IaC) and comprehensive CI/CD pipelines to manage a multi-tier application.

---

## 🏗 System Architecture
The application is deployed across a highly available AWS infrastructure designed for 99.9% uptime:

* **Frontend (React):** Hosted on **Amazon S3** with **Amazon CloudFront** providing global content delivery (CDN) and SSL termination.
* **Backend API (Golang):** Containerized application running on **EC2 instances** within an **Auto Scaling Group (ASG)**.
* **Load Balancing:** An **Application Load Balancer (ALB)** manages traffic distribution and performs health checks.
* **Caching Layer:** **Amazon ElastiCache (Redis)** cluster provides high-speed session management and data caching.
* **Database:** **MongoDB Atlas** (External SaaS) providing managed NoSQL persistence.
* **Networking:** Custom VPC with public and private subnets, NAT Gateways, and strict Security Group rules.

---

## 📂 Repository Structure
```text
starttech-infra/
├── .github/workflows/       # GitHub Actions Pipelines
│   ├── frontend-ci-cd.yml   # React Build -> S3 -> CloudFront
│   ├── backend-ci-cd.yml    # Golang Build -> ECR -> EC2/ASG
│   └── infrastructure.yml   # Terraform Plan/Apply
├── terraform/               # Infrastructure as Code (Modular)
│   ├── modules/             # Reusable modules (VPC, ASG, ALB, S3, Redis)
│   ├── main.tf              # Root configuration
│   └── variables.tf         # Variable definitions
├── frontend/                # React Application Source
├── backend/                 # Golang API Source & Dockerfile
├── scripts/                 # Operations (Deploy, Health-check, Rollback)
├── monitoring/              # CloudWatch Dashboards & Alarms
└── README.md                # Documentation
🚀 CI/CD Pipeline Implementation
1. Infrastructure Pipeline (Terraform)
Validation: Automated terraform validate and tflint on pull requests.

Automation: GitHub Actions executes terraform apply upon merging to main, ensuring the cloud state matches the code.

2. Frontend Pipeline (React)
Build: Node.js environment installs dependencies and builds production assets.

Security: Runs npm audit and unit tests.

Deployment: Syncs assets to S3 and triggers a CloudFront Invalidation to clear edge caches.

3. Backend Pipeline (Golang)
Quality: Runs Golang unit tests and static code analysis.

Containerization: Builds Docker image and performs Vulnerability Scanning before pushing to Amazon ECR.

Deployment: Triggers a Rolling Update on the Auto Scaling Group, ensuring zero-downtime deployments.

📈 Monitoring & Observability
Centralized Logging: All Golang application logs and EC2 system logs are streamed to CloudWatch Log Groups.

Metrics: Custom CloudWatch Dashboard tracking CPU Utilization, Request Latency, and Redis Memory usage.

Alerting: SNS-integrated Alarms notify the engineering team via email if health checks fail or latency spikes.

🔐 Security & Governance
Network Isolation: Backend EC2 instances reside in private subnets with no direct internet access.

IAM Roles: EC2 instances use the Principle of Least Privilege, granted only the permissions needed to write logs and pull from ECR.

Secret Management: No credentials are hardcoded. AWS Keys and MongoDB URIs are managed via GitHub Secrets.

Scanning: Automated Docker image scanning and dependency auditing are integrated into every pipeline run.

🛠 Setup & Deployment Guide
Prerequisites
AWS CLI & Terraform installed.

Configured GitHub Secrets for AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and MONGODB_ATLAS_URI.

Deployment Steps
Provision Infrastructure:

Bash

cd terraform
terraform init
terraform apply -auto-approve
Deploy Application: Push code to the main branch to trigger the GitHub Actions workflows.

Verify Status: Run the health check script:

Bash

./scripts/health-check.sh <ALB_ENDPOINT>