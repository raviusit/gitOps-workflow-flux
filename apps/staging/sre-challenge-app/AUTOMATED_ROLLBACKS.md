# Automated Rollbacks and Version Management

## Overview

This configuration implements automated rollbacks and version management for the SRE Challenge application using Flux v2.

## Automated Rollback Configuration

### Health Checks
- **Liveness Probe**: Checks application health every 10s, fails after 3 consecutive failures
- **Readiness Probe**: Checks if application is ready to serve traffic every 5s, fails after 2 consecutive failures  
- **Startup Probe**: Initial health check during container startup, allows up to 30s for startup

### Flux Rollback Mechanism
- **Health Check Monitoring**: Flux monitors deployment health via `healthChecks` configuration
- **Automatic Rollback**: If health checks fail, Flux automatically reverts to the last known good state
- **Timeout**: 5-minute timeout for health checks to pass
- **Retry**: 30-second retry interval for failed deployments

### Rolling Update Strategy
- **Max Surge**: 1 additional pod during updates
- **Max Unavailable**: 0 pods unavailable during updates (zero-downtime deployments)

## Automated Version Upgrades

### Image Policy Configuration
- **Semantic Versioning**: Only allows patch and minor updates (1.25.x -> 1.25.y or 1.26.x)
- **Version Range**: `>=1.25.0 <1.27.0` - prevents major version automatic updates
- **Image Filter**: Only alpine-based nginx images for consistency and security

### Automated Update Process
1. **Image Scanning**: Flux scans nginx repository every 1 minute
2. **Policy Evaluation**: New images are evaluated against semver policy
3. **Automated Commits**: Flux automatically commits image updates to Git
4. **GitOps Deployment**: Updated manifests trigger new deployment
5. **Health Validation**: New deployment must pass all health checks
6. **Automatic Rollback**: If health checks fail, automatically rollback to previous version

## Configuration Files

### Core Flux Resources
- `gitrepository.yaml`: Git source configuration
- `kustomization-flux.yaml`: Flux kustomization with health checks and rollback
- `imagerepository.yaml`: Container image repository configuration
- `imagepolicy.yaml`: Semantic versioning policy for automated updates
- `imageupdateautomation.yaml`: Automated image update configuration

### Enhanced Deployment
- Enhanced health checks (liveness, readiness, startup probes)
- Zero-downtime rolling update strategy
- Image automation markers for Flux integration

### Health Monitoring
- `health-monitor.yaml`: Post-deployment health validation job
- HTTP endpoint monitoring
- Pod readiness validation

## Testing Rollback Functionality

### Simulate Failed Deployment
```bash
# 1. Break the application by using an invalid image
kubectl patch deployment sre-challenge-app -n sre-challenge -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:invalid-tag"}]}}}}'

# 2. Watch Flux detect the failure and rollback
flux get kustomizations --watch
kubectl get pods -n sre-challenge -w

# 3. Verify rollback occurred
kubectl rollout history deployment/sre-challenge-app -n sre-challenge
```

### Test Automated Version Upgrade
```bash
# 1. Check current image version
kubectl get deployment sre-challenge-app -n sre-challenge -o yaml | grep image:

# 2. Watch for automatic updates (if newer patch version available)
flux get images all
flux get image policy nginx-policy

# 3. Monitor deployment updates
kubectl get events -n sre-challenge --sort-by='.lastTimestamp'
```

## Monitoring and Alerts

### Flux Events
```bash
# Monitor Flux reconciliation events
flux events --for Kustomization/sre-challenge-app

# Check image automation status
flux get image repository nginx
flux get image policy nginx-policy
```

### Health Check Status
```bash
# Check deployment health
kubectl describe deployment sre-challenge-app -n sre-challenge

# Monitor pod health
kubectl get pods -n sre-challenge -l app=sre-challenge-app

# Check application endpoint
curl -f https://eu-central-1.sre-challenge-panther.network
```

## Key Benefits

1. **Zero-Downtime Deployments**: Rolling updates with health validation
2. **Automatic Recovery**: Failed deployments automatically rollback
3. **Security Updates**: Automated patch-level updates for security fixes
4. **Version Control**: All changes tracked in Git with automated commits
5. **Health Validation**: Multi-level health checks ensure application stability
6. **Controlled Updates**: Only patch/minor versions updated automatically, major versions require manual approval

## Troubleshooting

### Common Issues
1. **Health Check Failures**: Check pod logs and endpoint accessibility
2. **Image Policy Not Working**: Verify image repository and policy configuration
3. **Rollback Not Triggering**: Ensure health checks are properly configured
4. **Update Automation Stopped**: Check Git authentication and branch permissions

### Debug Commands
```bash
# Check Flux reconciliation status
flux get all

# Debug image automation
flux logs --kind=ImageUpdateAutomation --since=1h

# Check health check configuration
kubectl describe deployment sre-challenge-app -n sre-challenge
```