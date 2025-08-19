#!/bin/bash

# Flux Bootstrap Script for SRE Challenge
# Export the environment variable GITHUB_TOKEN before running this script. export GITHUB_TOKEN=<your-token>
# Usage: ./install-flux.sh <github-username> <environment>

set -e

GITHUB_USER=$1
ENVIRONMENT=${2:-"staging"}

if [ -z "$GITHUB_USER" ]; then
    echo "❌ Error: GitHub username is required"
    echo "Usage: $0 <github-username> [environment]"
    echo ""
    echo "Example: $0 yourusername staging"
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(staging|production)$ ]]; then
    echo "❌ Error: Environment must be 'staging' or 'production'"
    exit 1
fi

REPO_NAME="gitOps-workflow-flux"
CLUSTER_PATH="clusters/$ENVIRONMENT"

echo "🚀 Installing Flux for SRE Challenge"
echo "📋 GitHub User: $GITHUB_USER"
echo "📋 Repository: $REPO_NAME"
echo "📋 Environment: $ENVIRONMENT"
echo "📋 Cluster Path: $CLUSTER_PATH"
echo ""

# Check if flux CLI is installed
if ! command -v flux &> /dev/null; then
    echo "❌ Error: Flux CLI is not installed"
    echo "Install it with:"
    echo "  brew install fluxcd/tap/flux"
    echo "  OR"
    echo "  curl -s https://fluxcd.io/install.sh | sudo bash"
    exit 1
fi

# Check if kubectl is working
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: kubectl is not configured or cluster is not accessible"
    echo "Run: aws eks update-kubeconfig --region <region> --name <cluster-name>"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Get cluster info
CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2 2>/dev/null || echo "unknown")
CLUSTER_REGION=$(kubectl config current-context | cut -d'.' -f3 2>/dev/null || echo "unknown")

echo "📊 Current Cluster Info:"
echo "   Name: $CLUSTER_NAME"
echo "   Region: $CLUSTER_REGION"
echo ""

# Check GitHub token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: GITHUB_TOKEN environment variable is not set"
    echo "Create a GitHub Personal Access Token with repo permissions and export it:"
    echo "  export GITHUB_TOKEN=<your-token>"
    exit 1
fi

echo "✅ GitHub token found"
echo ""

# Pre-flight checks
echo "🔍 Running Flux pre-flight checks..."
flux check --pre

echo ""
echo "🚀 Bootstrapping Flux..."
echo "This will:"
echo "  1. Install Flux components in flux-system namespace"
echo "  2. Configure GitRepository pointing to your repo"
echo "  3. Setup Kustomization to sync $CLUSTER_PATH"
echo ""

# Ask for confirmation
read -p "Continue with Flux bootstrap? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Bootstrap cancelled"
    exit 1
fi

# Bootstrap Flux
flux bootstrap github \
  --owner="$GITHUB_USER" \
  --repository="$REPO_NAME" \
  --branch=main \
  --path="$CLUSTER_PATH" \
  --personal
  --components-extra=image-reflector-controller,image-automation-controller
  

echo ""
echo "✅ Flux bootstrap completed!"
echo ""

# Wait for Flux to be ready
echo "⏳ Waiting for Flux system to be ready..."
kubectl wait --for=condition=ready pod -l app=source-controller -n flux-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=kustomize-controller -n flux-system --timeout=300s

echo ""
echo "🔍 Checking Flux status..."
flux get sources git
echo ""
flux get kustomizations

echo ""
echo "📊 Flux Installation Summary:"
echo "✅ Flux controllers installed in flux-system namespace"
echo "✅ GitRepository configured: $GITHUB_USER/$REPO_NAME"
echo "✅ Kustomization syncing path: $CLUSTER_PATH"
echo ""
echo "🎯 Next steps:"
echo "1. Commit and push any changes to trigger sync"
echo "2. Monitor with: flux get kustomizations --watch"
echo "3. Check logs with: flux logs --follow"
echo ""
echo "🎉 Flux is now managing your cluster via GitOps!"