#!/bin/bash
set -e # Exit immediately if a command fails

echo "🚀 Starting Backend Deployment..."

# 1. Get the ECR Repository URL from Terraform
ECR_URL=$(terraform output -raw ecr_repository_url)

# 2. Authenticate Docker to AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL

# 3. Build and Tag the Image
echo "📦 Building Docker image..."
docker build -t starttech-backend ./backend
docker tag starttech-backend:latest $ECR_URL:latest

# 4. Push to ECR
echo "📤 Pushing image to AWS ECR..."
docker push $ECR_URL:latest

# 5. Force ECS to redeploy with the new image
echo "🔄 Updating ECS Service to pick up new image..."
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw ecs_service_name)

aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment

echo "✅ Backend deployment triggered!"