#!/bin/bash

# Script to clean up backend state issues
# Usage: ./cleanup-backend-state.sh <environment> <region> [aws-profile]

set -e

ENVIRONMENT=$1
REGION=$2
AWS_PROFILE=${3:-"default"}

if [ $# -lt 2 ]; then
    echo "Usage: $0 <environment> <region> [aws-profile]"
    echo "Example: $0 staging eu-central-1 staging-215876814712-raisin"
    exit 1
fi

echo "🧹 Cleaning up backend state for $ENVIRONMENT in $REGION"
echo "📋 Using AWS profile: $AWS_PROFILE"

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/../terraform/backend"

# Navigate to backend directory
cd "$BACKEND_DIR"

echo "📁 Working directory: $(pwd)"

# Remove any existing .terraform directory and state
echo "🗑️  Removing existing Terraform state..."
rm -rf .terraform
rm -f terraform.tfstate*

# Re-initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Create workspace for the specific region if it doesn't exist
WORKSPACE="${ENVIRONMENT}-${REGION}"
echo "📋 Creating/selecting workspace: $WORKSPACE"

# List existing workspaces
terraform workspace list

# Select or create the workspace
if terraform workspace list | grep -q "$WORKSPACE"; then
    terraform workspace select "$WORKSPACE"
else
    terraform workspace new "$WORKSPACE"
fi

echo "✅ Workspace setup completed!"
echo ""
echo "📝 Now run:"
echo "AWS_PROFILE=$AWS_PROFILE terraform plan -var=\"environment=$ENVIRONMENT\" -var=\"region=$REGION\""
echo "AWS_PROFILE=$AWS_PROFILE terraform apply -var=\"environment=$ENVIRONMENT\" -var=\"region=$REGION\""