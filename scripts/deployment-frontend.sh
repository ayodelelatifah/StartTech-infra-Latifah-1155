# Inside deploy-frontend.sh
# Pull the bucket name from Terraform instead of hardcoding it
BUCKET_NAME=$(terraform output -raw frontend_bucket_name)

echo "Deploying to $BUCKET_NAME..."
aws s3 sync ./frontend/dist s3://$BUCKET_NAME --delete