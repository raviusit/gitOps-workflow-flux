#!/bin/bash

# Complete environment deployment script
# Usage: ./deploy-environment.sh <environment> <region> [action]

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
    echo "This script will:"
    echo "  1. Create backend resources (S3, DynamoDB, KMS)"
    echo "  2. Initialize infrastructure with remote state"
    echo "  3. Deploy/plan/destroy the complete environment"
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
    AWS_PROFILE="production"
fi

echo "🚀 Deploying $ENVIRONMENT in $REGION"
echo "📋 Using AWS profile: $AWS_PROFILE"
echo ""

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

echo "📁 Environment directory: $ENV_DIR"

# Step 1: Deploy Backend Resources
echo ""
echo "=== STEP 1: Backend Setup ==="
BACKEND_DIR="$ENV_DIR/0-backend"

if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Error: Backend directory $BACKEND_DIR does not exist"
    exit 1
fi

cd "$BACKEND_DIR"
echo "📁 Backend directory: $(pwd)"

# Initialize and deploy backend
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing backend Terraform..."
    terraform init
fi

case $ACTION in
    "plan"|"apply")
        echo "📋 Planning backend resources..."
        AWS_PROFILE=$AWS_PROFILE terraform plan

        if [[ "$ACTION" == "apply" ]]; then
            echo ""
            read -p "Deploy backend resources? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "🚀 Creating backend resources..."
                AWS_PROFILE=$AWS_PROFILE terraform apply -auto-approve
                
                # Get backend configuration
                echo "📋 Getting backend configuration..."
                BUCKET_NAME=$(AWS_PROFILE=$AWS_PROFILE terraform output -raw s3_bucket_name)
                DYNAMODB_TABLE=$(AWS_PROFILE=$AWS_PROFILE terraform output -raw dynamodb_table_name)
                
                echo "✅ Backend resources created:"
                echo "   S3 Bucket: $BUCKET_NAME"
                echo "   DynamoDB: $DYNAMODB_TABLE"
            else
                echo "❌ Backend deployment cancelled"
                exit 1
            fi
        fi
        ;;
    "destroy")
        echo "⚠️  WARNING: This will destroy backend resources!"
        echo "Environment: $ENVIRONMENT"
        echo "Region: $REGION"
        echo ""
        read -p "Are you sure? Type 'yes' to confirm: " confirmation
        
        if [[ "$confirmation" == "yes" ]]; then
            echo "🗑️  Destroying backend resources..."
            AWS_PROFILE=$AWS_PROFILE terraform destroy -auto-approve
            echo "✅ Backend destroyed!"
            # Don't proceed to infrastructure destroy if backend is destroyed
            exit 0
        else
            echo "❌ Backend destroy cancelled"
            exit 1
        fi
        ;;
esac

# Step 2: Deploy Infrastructure
echo ""
echo "=== STEP 2: Infrastructure Deployment ==="
cd "$ENV_DIR"
echo "📁 Infrastructure directory: $(pwd)"

# Create backend configuration file dynamically
BACKEND_CONFIG_FILE="backend-config.hcl"
cat > "$BACKEND_CONFIG_FILE" << EOF
bucket         = "$BUCKET_NAME"
key            = "infrastructure/terraform.tfstate"
region         = "$REGION"
dynamodb_table = "$DYNAMODB_TABLE"
encrypt        = true
profile        = "$AWS_PROFILE"
EOF

echo "📄 Created backend config: $BACKEND_CONFIG_FILE"


# Initialize infrastructure with remote backend if not already initialized
if [ ! -d ".terraform" ] || [ ! -f ".terraform/plugins" ]; then
    echo "🔧 Initializing infrastructure Terraform..."
    AWS_PROFILE=$AWS_PROFILE terraform init -backend-config="$BACKEND_CONFIG_FILE"
else
    echo "✅ Infrastructure Terraform already initialized"
fi

# Execute the requested action on infrastructure
case $ACTION in
    "plan")
        echo "📋 Planning infrastructure..."
        AWS_PROFILE=$AWS_PROFILE terraform plan -var-file=terraform.tfvars
        ;;
    "apply")
        echo "📋 Planning infrastructure..."
        AWS_PROFILE=$AWS_PROFILE terraform plan -var-file=terraform.tfvars
        
        echo ""
        read -p "Destroying infrastructure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🚀 destroying infrastructure..."
            AWS_PROFILE=$AWS_PROFILE terraform destroy -var-file=terraform.tfvars -auto-approve
            
            echo ""
            echo "✅ Infrastructure deployment completed!"
            echo ""
            echo "📝 Next steps:"
            echo "1. Update kubeconfig:"
            echo "   aws eks update-kubeconfig --region $REGION --name sre-challenge-$ENVIRONMENT --profile $AWS_PROFILE"
            echo "2. Verify cluster access:"
            echo "   kubectl cluster-info"
            echo "3. Check nodes:"
            echo "   kubectl get nodes"
            echo ""
            echo "🎯 Environment URL (when DNS is configured):"
            echo "   https://$ENVIRONMENT.sre-challenge-panther.network"
        else
            echo "❌ Infrastructure deployment cancelled"
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
            echo "❌ Infrastructure destroy cancelled"
            exit 1
        fi
        ;;
esac

echo ""
echo "🎉 Operation completed successfully!"