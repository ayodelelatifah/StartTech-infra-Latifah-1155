#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

echo "-------------------------------------------------------"
echo "🏗️  STARTTECH INFRASTRUCTURE DEPLOYMENT"
echo "-------------------------------------------------------"

# 1. AWS Pre-check: Clean up 'Ghost' Resources
echo "🧹 Step 1: Cleaning up conflicting resources in us-east-1..."

# Delete conflicting Log Group if it exists
aws logs delete-log-group --log-group-name "/ecs/starttech-backend" --region us-east-1 2>/dev/null || echo "Checked: Log group already clear."

# Delete conflicting Target Group if it exists
TG_ARN=$(aws elbv2 describe-target-groups --names "starttech-backend-tg" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
if [ ! -z "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
    echo "Removing existing Target Group: $TG_ARN"
    aws elbv2 delete-target-group --target-group-arn "$TG_ARN" || echo "Note: Target group in use, skipping deletion."
fi

# 2. Terraform Lifecycle
echo "📂 Step 2: Navigating to Terraform Directory..."
# This moves the script into the folder where your .tf files live
cd terraform 

echo "📍 Current Directory: $(pwd)"

echo "⚙️ Step 3: Initializing Terraform..."
terraform init

echo "🔍 Step 4: Validating Configuration..."
terraform validate

echo "🚀 Step 5: Applying Infrastructure Changes..."
terraform apply -auto-approve

# 3. Move back to root for follow-up actions
cd ..

echo "-------------------------------------------------------"
echo "✅ Infrastructure is Ready!"
echo "-------------------------------------------------------"

# Optional: Trigger the backend deployment automatically
# chmod +x scripts/deployment-backend.sh
# ./scripts/deployment-backend.sh