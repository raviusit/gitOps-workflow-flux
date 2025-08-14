# Backend Configuration Fix

## The Issue
The S3 bucket naming and DynamoDB table references were causing cross-region conflicts. Each region needs completely independent backend resources.

## Root Cause
1. **S3 Bucket Cross-Region Access**: When Terraform tried to access `sre-challenge-terraform-state-staging-us-east-1` from `eu-central-1`, it got a redirect error
2. **DynamoDB Table Naming**: The DynamoDB table names weren't region-specific in the backend.hcl files

## Fixed Configuration

### ✅ Backend Resources (Per Region)
Each region now gets its own:
```
S3 Bucket: sre-challenge-terraform-state-{environment}-{region}
DynamoDB:  sre-challenge-terraform-locks-{environment}-{region}
KMS Key:   sre-challenge-terraform-state-key-{environment}-{region}
```

### ✅ Updated backend.hcl Files
- **staging/us-east-1**: Uses `sre-challenge-terraform-locks-staging-us-east-1`
- **staging/eu-central-1**: Uses `sre-challenge-terraform-locks-staging-eu-central-1`
- **production/us-east-1**: Uses `sre-challenge-terraform-locks-production-us-east-1`
- **production/eu-central-1**: Uses `sre-challenge-terraform-locks-production-eu-central-1`

## Resolution Steps

### Step 1: Clean Up Existing Backend State
```bash
# For the problematic eu-central-1 region
cd terraform/backend
rm -rf .terraform
rm -f terraform.tfstate*
```

### Step 2: Create Region-Specific Backend
```bash
# Create backend for eu-central-1 with correct region context
cd terraform/backend
terraform init
terraform workspace new staging-eu-central-1  # Create isolated workspace
terraform workspace select staging-eu-central-1

# Deploy with correct region
AWS_PROFILE=staging-215876814712-raisin terraform plan \
    -var="environment=staging" \
    -var="region=eu-central-1" \
    -var="project_name=sre-challenge"

AWS_PROFILE=staging-215876814712-raisin terraform apply \
    -var="environment=staging" \
    -var="region=eu-central-1" \
    -var="project_name=sre-challenge" \
    -auto-approve
```

### Step 3: Verify Backend Resources
```bash
# Check that eu-central-1 backend resources exist
AWS_PROFILE=staging-215876814712-raisin aws s3 ls | grep staging-eu-central-1
AWS_PROFILE=staging-215876814712-raisin aws dynamodb list-tables --region eu-central-1
```

### Step 4: Deploy Infrastructure
```bash
# Now deploy the infrastructure
cd terraform/environments/staging/eu-central-1
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Alternative: Simplified Script Approach

I've also created a cleanup script. Use it like this:

```bash
# Clean up and recreate backend for eu-central-1
./scripts/cleanup-backend-state.sh staging eu-central-1 staging-215876814712-raisin
```

## Expected Backend Resources After Fix

### Staging Environment
**us-east-1**:
- S3: `sre-challenge-terraform-state-staging-us-east-1`
- DynamoDB: `sre-challenge-terraform-locks-staging-us-east-1`

**eu-central-1**:
- S3: `sre-challenge-terraform-state-staging-eu-central-1`  
- DynamoDB: `sre-challenge-terraform-locks-staging-eu-central-1`

### Production Environment
**us-east-1**:
- S3: `sre-challenge-terraform-state-production-us-east-1`
- DynamoDB: `sre-challenge-terraform-locks-production-us-east-1`

**eu-central-1**:
- S3: `sre-challenge-terraform-state-production-eu-central-1`
- DynamoDB: `sre-challenge-terraform-locks-production-eu-central-1`

This ensures complete isolation between regions and prevents cross-region access issues.