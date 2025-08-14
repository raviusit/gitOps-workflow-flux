#!/bin/bash

# Complete global and regional deployment script
# Usage: ./deploy-global-regional.sh <environment> <region> [action]

set -e

ENVIRONMENT=$1
REGION=$2
ACTION=${3:-"plan"}

if [ $# -lt 2 ]; then
    echo "Usage: $0 <environment> <region> [plan|apply|destroy]"
    echo ""
    echo "Examples:"
    echo "  $0 staging us-east-1 plan       # Plan staging us-east-1"
    echo "  $0 staging eu-central-1 apply   # Deploy staging eu-central-1"
    echo "  $0 production us-east-1 apply   # Deploy production us-east-1"
    echo ""
    echo "This script will deploy in phases:"
    echo "  1. Backend resources (if needed)"
    echo "  2. Global resources (IAM, Route53, ECR)"
    echo "  3. Regional resources (VPC, EKS, ALB, IRSA roles)"
    exit 1
fi

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(staging|production)$ ]]; then
    echo "❌ Error: Environment must be 'staging' or 'production'"
    exit 1
fi

if [[ ! "$REGION" =~ ^(us-east-1|eu-central-1)$ ]]; then
    echo "❌ Error: Region must be 'us-east-1' or 'eu-central-1'"
    exit 1
fi

if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    echo "❌ Error: Action must be 'plan', 'apply', or 'destroy'"
    exit 1
fi

# Set AWS profile based on environment
if [[ "$ENVIRONMENT" == "staging" ]]; then
    AWS_PROFILE="staging-215876814712-raisin"
elif [[ "$ENVIRONMENT" == "production" ]]; then
    AWS_PROFILE="production-746848447423-raisin"
fi

echo "🚀 Deploying $ENVIRONMENT in $REGION using global/regional approach"
echo "📋 Using AWS profile: $AWS_PROFILE"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity --profile "$AWS_PROFILE" > /dev/null 2>&1; then
    echo "❌ Error: AWS CLI not configured for profile '$AWS_PROFILE'"
    echo "Run: aws configure --profile $AWS_PROFILE"
    exit 1
fi

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_BASE_DIR="$SCRIPT_DIR/../terraform/environments/$ENVIRONMENT"

if [ ! -d "$ENV_BASE_DIR" ]; then
    echo "❌ Error: Directory $ENV_BASE_DIR does not exist"
    exit 1
fi

echo "📁 Environment base directory: $ENV_BASE_DIR"

# Helper function to create backend resources
create_backend() {
    local BACKEND_TYPE=$1
    local BACKEND_REGION=$2
    
    echo ""
    echo "=== Creating Backend for $BACKEND_TYPE ($BACKEND_REGION) ==="
    
    # Create temporary backend resources
    TEMP_DIR=$(mktemp -d)
    
    cat > "$TEMP_DIR/main.tf" << EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "$BACKEND_REGION"
  profile = "$AWS_PROFILE"
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "sre-challenge-terraform-state-$ENVIRONMENT-$BACKEND_TYPE"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "sre-challenge-terraform-locks-$ENVIRONMENT-$BACKEND_TYPE"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "bucket_name" { value = aws_s3_bucket.terraform_state.id }
output "dynamodb_table" { value = aws_dynamodb_table.terraform_locks.name }
EOF

    cd "$TEMP_DIR"
    terraform init
    terraform apply -auto-approve
    
    BUCKET_NAME=$(terraform output -raw bucket_name)
    DYNAMODB_TABLE=$(terraform output -raw dynamodb_table)
    
    echo "✅ Backend created: $BUCKET_NAME"
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    # Return values via global variables
    BACKEND_BUCKET="$BUCKET_NAME"
    BACKEND_DYNAMODB="$DYNAMODB_TABLE"
}

# Step 1: Deploy Global Resources
echo ""
echo "=== PHASE 1: Global Resources ==="
GLOBAL_DIR="$ENV_BASE_DIR/global"

if [ ! -d "$GLOBAL_DIR" ]; then
    echo "❌ Error: Global directory $GLOBAL_DIR does not exist"
    exit 1
fi

cd "$GLOBAL_DIR"
echo "📁 Global directory: $(pwd)"

# Check if backend exists, create if needed
GLOBAL_BUCKET="sre-challenge-terraform-state-$ENVIRONMENT-global"
if ! aws s3 ls "s3://$GLOBAL_BUCKET" --profile "$AWS_PROFILE" &> /dev/null; then
    echo "🔧 Creating global backend resources..."
    create_backend "global" "us-east-1"
else
    echo "✅ Global backend already exists"
    BACKEND_BUCKET="$GLOBAL_BUCKET"
    BACKEND_DYNAMODB="sre-challenge-terraform-locks-$ENVIRONMENT-global"
fi

# Create backend config
cat > "backend-config.hcl" << EOF
bucket         = "$BACKEND_BUCKET"
key            = "global/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "$BACKEND_DYNAMODB"
encrypt        = true
profile        = "$AWS_PROFILE"
EOF

# Initialize and deploy global resources
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing global Terraform..."
    AWS_PROFILE=$AWS_PROFILE terraform init -backend-config=backend-config.hcl
fi

case $ACTION in
    "plan"|"apply")
        echo "📋 Planning global resources..."
        AWS_PROFILE=$AWS_PROFILE terraform plan -var-file=terraform.tfvars

        if [[ "$ACTION" == "apply" ]]; then
            echo ""
            read -p "Deploy global resources? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "🚀 Applying global resources..."
                AWS_PROFILE=$AWS_PROFILE terraform apply -var-file=terraform.tfvars -auto-approve
                echo "✅ Global resources deployed!"
            else
                echo "❌ Global deployment cancelled"
                exit 1
            fi
        fi
        ;;
    "destroy")
        echo "⚠️  WARNING: This will destroy global resources!"
        read -p "Are you sure? Type 'yes' to confirm: " confirmation
        if [[ "$confirmation" == "yes" ]]; then
            AWS_PROFILE=$AWS_PROFILE terraform destroy -var-file=terraform.tfvars -auto-approve
            echo "✅ Global resources destroyed!"
            # Don't proceed to regional if global is destroyed
            exit 0
        else
            echo "❌ Global destroy cancelled"
            exit 1
        fi
        ;;
esac

# Step 2: Deploy Regional Resources  
echo ""
echo "=== PHASE 2: Regional Resources ==="
REGIONAL_DIR="$ENV_BASE_DIR/regional/$REGION"

if [ ! -d "$REGIONAL_DIR" ]; then
    echo "❌ Error: Regional directory $REGIONAL_DIR does not exist"
    exit 1
fi

cd "$REGIONAL_DIR"
echo "📁 Regional directory: $(pwd)"

# Check if regional backend exists, create if needed
REGIONAL_BUCKET="sre-challenge-terraform-state-$ENVIRONMENT-$REGION"
if ! aws s3 ls "s3://$REGIONAL_BUCKET" --profile "$AWS_PROFILE" --region "$REGION" &> /dev/null; then
    echo "🔧 Creating regional backend resources..."
    create_backend "$REGION" "$REGION"
else
    echo "✅ Regional backend already exists"
    BACKEND_BUCKET="$REGIONAL_BUCKET"
    BACKEND_DYNAMODB="sre-challenge-terraform-locks-$ENVIRONMENT-$REGION"
fi

# Create regional backend config
cat > "backend-config.hcl" << EOF
bucket         = "$BACKEND_BUCKET"
key            = "regional/$REGION/terraform.tfstate"
region         = "$REGION"
dynamodb_table = "$BACKEND_DYNAMODB"
encrypt        = true
profile        = "$AWS_PROFILE"
EOF

# Initialize and deploy regional resources
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing regional Terraform..."
    AWS_PROFILE=$AWS_PROFILE terraform init -backend-config=backend-config.hcl
fi

case $ACTION in
    "plan"|"apply")
        echo "📋 Planning regional resources..."
        AWS_PROFILE=$AWS_PROFILE terraform plan -var-file=terraform.tfvars

        if [[ "$ACTION" == "apply" ]]; then
            echo ""
            read -p "Deploy regional resources? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "🚀 Applying regional resources..."
                AWS_PROFILE=$AWS_PROFILE terraform apply -var-file=terraform.tfvars -auto-approve
                
                echo ""
                echo "✅ Regional resources deployed!"
                echo ""
                echo "📝 Next steps:"
                echo "1. Update kubeconfig:"
                echo "   aws eks update-kubeconfig --region $REGION --name sre-challenge-$ENVIRONMENT --profile $AWS_PROFILE"
                echo "2. Verify cluster access:"
                echo "   kubectl cluster-info"
                echo "3. Check nodes:"
                echo "   kubectl get nodes"
                echo ""
                echo "🎯 Environment URLs:"
                echo "   Regional: https://$REGION.sre-challenge-$ENVIRONMENT.local"
            else
                echo "❌ Regional deployment cancelled"
                exit 1
            fi
        fi
        ;;
    "destroy")
        echo "⚠️  WARNING: This will destroy regional resources!"
        echo "Region: $REGION"
        read -p "Are you sure? Type 'yes' to confirm: " confirmation
        if [[ "$confirmation" == "yes" ]]; then
            AWS_PROFILE=$AWS_PROFILE terraform destroy -var-file=terraform.tfvars -auto-approve
            echo "✅ Regional resources destroyed!"
        else
            echo "❌ Regional destroy cancelled"
            exit 1
        fi
        ;;
esac

echo ""
echo "🎉 Global/Regional deployment completed successfully!"