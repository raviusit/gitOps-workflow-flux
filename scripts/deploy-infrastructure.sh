#!/bin/bash

# Script to deploy infrastructure using Terraform
# Usage: ./deploy-infrastructure.sh <environment> <region> [action]

set -e

ENVIRONMENT=$1
REGION=$2
ACTION=${3:-"plan"}

if [ $# -lt 2 ]; then
    echo "Usage: $0 <environment> <region> [plan|apply|destroy]"
    echo "Example: $0 staging us-east-1 apply"
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

if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    echo "Error: Action must be 'plan', 'apply', or 'destroy'"
    exit 1
fi

# Set AWS profile based on environment
if [[ "$ENVIRONMENT" == "staging" ]]; then
    AWS_PROFILE="staging"
elif [[ "$ENVIRONMENT" == "production" ]]; then
    AWS_PROFILE="production"
fi

echo "🚀 $ACTION infrastructure for $ENVIRONMENT in $REGION"
echo "📋 Using AWS profile: $AWS_PROFILE"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity --profile "$AWS_PROFILE" > /dev/null 2>&1; then
    echo "❌ Error: AWS CLI not configured for profile '$AWS_PROFILE'"
    echo "Run: aws configure --profile $AWS_PROFILE"
    exit 1
fi

# Get current directory and navigate to environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$SCRIPT_DIR/../terraform/environments/$ENVIRONMENT/$REGION"

if [ ! -d "$ENV_DIR" ]; then
    echo "❌ Error: Directory $ENV_DIR does not exist"
    exit 1
fi

cd "$ENV_DIR"
echo "📁 Working directory: $(pwd)"

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    AWS_PROFILE=$AWS_PROFILE terraform init -backend-config=backend.hcl
else
    echo "✅ Terraform already initialized"
fi

# Execute the requested action
case $ACTION in
    "plan")
        echo "📋 Planning infrastructure..."
        AWS_PROFILE=$AWS_PROFILE terraform plan -var-file=terraform.tfvars
        ;;
    "apply")
        echo "📋 Planning infrastructure..."
        AWS_PROFILE=$AWS_PROFILE terraform plan -var-file=terraform.tfvars
        
        echo ""
        read -p "Do you want to apply these changes? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🚀 Applying infrastructure..."
            AWS_PROFILE=$AWS_PROFILE terraform apply -var-file=terraform.tfvars -auto-approve
            
            echo "✅ Infrastructure deployment completed!"
            echo ""
            echo "📝 Next steps:"
            echo "1. Update kubeconfig:"
            echo "   aws eks update-kubeconfig --region $REGION --name sre-challenge-$ENVIRONMENT --profile $AWS_PROFILE"
            echo "2. Verify cluster access:"
            echo "   kubectl cluster-info"
            echo "3. Check nodes:"
            echo "   kubectl get nodes"
        else
            echo "❌ Deployment cancelled"
            exit 1
        fi
        ;;
    "destroy")
        echo "⚠️  WARNING: This will destroy all infrastructure!"
        echo "Environment: $ENVIRONMENT"
        echo "Region: $REGION"
        echo ""
        read -p "Are you sure you want to destroy this infrastructure? Type 'yes' to confirm: " confirmation
        
        if [[ "$confirmation" == "yes" ]]; then
            echo "🗑️  Destroying infrastructure..."
            AWS_PROFILE=$AWS_PROFILE terraform destroy -var-file=terraform.tfvars -auto-approve
            echo "✅ Infrastructure destroyed!"
        else
            echo "❌ Destroy cancelled"
            exit 1
        fi
        ;;
esac