#!/bin/bash

# Magic Movie Machine - Infrastructure Deployment Script
# This script automates the deployment process

set -e

echo "╔═════════════════════════════════════════════════════════════╗"
echo "║     Magic Movie Machine Infrastructure Deployment Script    ║"
echo "╚═════════════════════════════════════════════════════════════╝"

# Check prerequisites
echo ""
echo "📋 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform >= 1.0"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI v2"
    exit 1
fi

echo "✅ Terraform version: $(terraform version -json | jq -r .terraform_version)"
echo "✅ AWS CLI installed"

# Change to terraform directory
cd terraform/

# Initialize Terraform
echo ""
echo "🔧 Initializing Terraform..."
terraform init

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    echo ""
    echo "📝 Creating terraform.tfvars..."
    cp terraform.tfvars.example terraform.tfvars
    echo "⚠️  Please review and customize terraform.tfvars if needed"
fi

# Validate configuration
echo ""
echo "✓ Validating Terraform configuration..."
terraform validate

# Plan deployment
echo ""
echo "📊 Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "Do you want to apply this plan? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Deployment cancelled"
    rm -f tfplan
    exit 1
fi

# Apply configuration
echo ""
echo "🚀 Applying Terraform configuration..."
terraform apply tfplan

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Outputs:"
terraform output

echo ""
echo "⚠️  NEXT STEPS:"
echo "   1. Upload training data to S3:"
echo "      aws s3 cp interactions.csv s3://$(terraform output -raw s3_bucket_name)/interactions/"
echo "      aws s3 cp items.csv s3://$(terraform output -raw s3_bucket_name)/items/"
echo "      aws s3 cp users.csv s3://$(terraform output -raw s3_bucket_name)/users/"
echo ""
echo "   2. Create Personalize resources using AWS Console"
echo ""
echo "   3. Update Lambda environment variables with Personalize ARNs"
echo ""
echo "   4. Test the API endpoints"
echo ""
echo "For detailed instructions, see terraform/README.md"
