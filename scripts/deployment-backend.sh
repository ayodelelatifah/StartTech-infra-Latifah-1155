#!/bin/bash
set -e # Exit immediately if a command fails

echo "🚀 Starting Backend Deployment..."

# 1. Get the ECR Repository URL from Terraform (Navigate to the folder first)
echo "🔍 Fetching ECR URL from Terraform..."
ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)

# 2. Prepare the Registry URL for Docker login (removes the repository name)
# Example: 1234567890.dkr.ecr.us-east-1.amazonaws.com/repo -> 1234567890.dkr.ecr.us-east-1.amazonaws.com
ECR_REGISTRY=$(echo $ECR_URL | cut -d/ -f1)

# 3. Authenticate Docker to AWS ECR
echo "🔐 Logging into ECR: $ECR_REGISTRY"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# 4. Build and Tag the Image
echo "📦 Building Docker image..."
# Make sure we point to the backend folder relative to the root
docker build -t starttech-backend ./backend
docker tag starttech-backend:latest $ECR_URL:latest

# 5. Push to ECR
echo "📤 Pushing image to AWS ECR..."
docker push $ECR_URL:latest

# 6. Force ECS to redeploy with the new image
echo "🔄 Updating ECS Service to pick up new image..."
CLUSTER_NAME=$(cd terraform && terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(cd terraform && terraform output -raw ecs_service_name)

aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment --region us-east-1

echo "✅ Backend deployment triggered!"