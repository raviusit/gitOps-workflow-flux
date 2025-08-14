#!/bin/bash

# Script to set up Terraform backend infrastructure
# Usage: ./setup-backend.sh <environment> <region> [aws-profile]

set -e

ENVIRONMENT=$1
REGION=$2
AWS_PROFILE=${3:-"default"}

if [ $# -lt 2 ]; then
    echo "Usage: $0 <environment> <region> [aws-profile]"
    echo "Example: $0 staging us-east-1 staging"
    exit 1
fi

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(staging|production)$ ]]; then
    echo "Error: Environment must be 'staging' or 'production'"
    exit 1
fi

if [[ ! "$REGION" =~ ^(us-east-1|eu-central-1)$ ]]; then
    echo "Error: Region must be 'us-east-1' or 'eu-central-1'"
    exit 1
fi

echo "🚀 Setting up Terraform backend for $ENVIRONMENT in $REGION"
echo "📋 Using AWS profile: $AWS_PROFILE"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity --profile "$AWS_PROFILE" > /dev/null 2>&1; then
    echo "❌ Error: AWS CLI not configured for profile '$AWS_PROFILE'"
    echo "Run: aws configure --profile $AWS_PROFILE"
    exit 1
fi

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/../terraform/backend"

# Navigate to backend directory
cd "$BACKEND_DIR"

echo "📁 Working directory: $(pwd)"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan the backend resources
echo "📋 Planning backend resources..."
AWS_PROFILE=$AWS_PROFILE terraform plan \
    -var="environment=$ENVIRONMENT" \
    -var="region=$REGION" \
    -var="project_name=sre-challenge"

# Apply the backend resources
echo "🚀 Creating backend resources..."
read -p "Do you want to create these resources? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    AWS_PROFILE=$AWS_PROFILE terraform apply \
        -var="environment=$ENVIRONMENT" \
        -var="region=$REGION" \
        -var="project_name=sre-challenge" \
        -auto-approve
    
    echo "✅ Backend setup completed successfully!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Navigate to: terraform/environments/$ENVIRONMENT/$REGION/"
    echo "2. Run: terraform init -backend-config=backend.hcl"
    echo "3. Run: terraform plan -var-file=terraform.tfvars"
    echo "4. Run: terraform apply -var-file=terraform.tfvars"
else
    echo "❌ Backend setup cancelled"
    exit 1
fi