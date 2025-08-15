# SRE Challenge - Monitoring and Logging Guide

## Overview

This guide covers the complete monitoring and logging setup for the SRE Challenge infrastructure, implementing observability best practices with Prometheus, Grafana, and Fluentd.

## Architecture

### Monitoring Stack
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Applications  │───▶│   Prometheus    │───▶│     Grafana     │
│   + Exporters   │    │   (Metrics)     │    │  (Dashboards)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         │              │  AlertManager   │              │
         │              │   (Alerting)    │              │
         │              └─────────────────┘              │
         │                                               │
┌─────────────────┐    ┌─────────────────┐              │
│   Kubernetes    │───▶│     Fluentd     │              │
│   Cluster Logs  │    │ (Log Aggregation)│              │
└─────────────────┘    └─────────────────┘              │
                                │                        │
                       ┌─────────────────┐              │
                       │  Log Storage    │              │
                       │   (Optional)    │              │
                       └─────────────────┘              │
                                                        │
                       ┌─────────────────┐              │
                       │   Ingress ALB   │◀─────────────┘
                       │ grafana/prometheus.example.com │
                       └─────────────────┘
```

## Components

### 1. Prometheus Stack (Kube-Prometheus-Stack)

**Purpose**: Metrics collection, storage, and alerting
**Namespace**: `monitoring`

**Key Features**:
- **Metrics Retention**: 7 days with 5GB limit
- **Storage**: 10GB persistent volume (AWS gp2)
- **Resources**: 400Mi-2Gi memory, 100m-1000m CPU
- **Auto-Discovery**: ServiceMonitor and PodMonitor support

**Monitored Components**:
- Kubernetes cluster metrics (nodes, pods, deployments)
- Application metrics (nginx, custom exporters)
- Flux GitOps metrics
- AWS Load Balancer Controller metrics
- System metrics (node-exporter, kube-state-metrics)

### 2. Grafana

**Purpose**: Visualization and dashboards
**Namespace**: `monitoring`

**Key Features**:
- **Storage**: 5GB persistent volume
- **Resources**: 128Mi-512Mi memory, 50m-200m CPU
- **Default Credentials**: admin/admin123 (change in production)
- **Pre-configured Dashboards**:
  - Kubernetes Cluster Monitoring (GrafanaID: 7249)
  - Kubernetes Pod Monitoring (GrafanaID: 6417)
  - Nginx Ingress Controller (GrafanaID: 9614)
  - Node Exporter (GrafanaID: 1860)
  - Custom SRE Challenge Application Dashboard

### 3. Fluentd

**Purpose**: Log aggregation and forwarding
**Namespace**: `monitoring`

**Key Features**:
- **Deployment**: DaemonSet (runs on every node)
- **Log Sources**:
  - Container logs (/var/log/containers/*.log)
  - Kubelet logs (/var/log/kubelet.log)
  - Docker logs (/var/log/docker.log)
- **Processing**: Kubernetes metadata enrichment
- **Output**: Stdout (configurable for external systems)

## Access URLs

### Production Access
- **Grafana**: https://grafana.eu-central-1.sre-challenge-panther.network
- **Prometheus**: https://prometheus.eu-central-1.sre-challenge-panther.network

### Port Forwarding (Development)
```bash
# Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# AlertManager
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
```

## Application Metrics

### SRE Challenge App Metrics

The application includes nginx-prometheus-exporter for detailed metrics:

**Metrics Endpoint**: `http://sre-challenge-app:9113/metrics`

**Available Metrics**:
- `nginx_connections_active` - Active connections
- `nginx_connections_reading` - Connections reading requests
- `nginx_connections_writing` - Connections writing responses
- `nginx_connections_waiting` - Idle connections
- `nginx_http_requests_total` - Total HTTP requests
- `nginx_up` - Nginx exporter status

### Custom Dashboard

The SRE Challenge Application Dashboard includes:
- **Application Availability**: Service uptime monitoring
- **CPU Usage**: Container CPU utilization
- **Memory Usage**: Container memory consumption
- **Pod Replicas**: Deployment replica status

## Log Analysis

### Fluentd Log Collection

**Log Format Enhancement**:
```json
{
  "log": "original log message",
  "stream": "stdout|stderr",
  "kubernetes": {
    "pod_name": "sre-challenge-app-xxx",
    "namespace_name": "sre-challenge",
    "container_name": "nginx"
  },
  "hostname": "node-name",
  "cluster_name": "sre-challenge",
  "environment": "staging"
}
```

### Log Query Examples

**View Application Logs**:
```bash
kubectl logs -n monitoring -l app=fluentd | grep sre-challenge-app
```

**Monitor Flux Logs**:
```bash
kubectl logs -n monitoring -l app=fluentd | grep flux-system
```

## Operational Procedures

### 1. Deployment Verification

```bash
# Check all monitoring components
kubectl get pods -n monitoring

# Verify Prometheus targets
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090/targets

# Check Grafana dashboards
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Open http://localhost:3000
```

### 2. Troubleshooting

**Prometheus Issues**:
```bash
# Check Prometheus pod logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Verify ServiceMonitor configuration
kubectl get servicemonitor -n monitoring -o yaml

# Check storage
kubectl get pvc -n monitoring
```

**Grafana Issues**:
```bash
# Check Grafana pod logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Reset admin password (if needed)
kubectl exec -n monitoring deployment/kube-prometheus-stack-grafana -- grafana-cli admin reset-admin-password newpassword
```

**Fluentd Issues**:
```bash
# Check Fluentd pod status
kubectl get pods -n monitoring -l app=fluentd

# View Fluentd logs
kubectl logs -n monitoring -l app=fluentd --tail=100

# Check log file permissions
kubectl exec -n monitoring -it daemonset/fluentd -- ls -la /var/log/containers/
```

### 3. Scaling Considerations

**Prometheus Storage**:
- Monitor retention and storage usage
- Adjust retention period: `retention: 15d` for longer history
- Scale storage: Increase `storage: 20Gi` for more capacity

**Grafana Performance**:
- Monitor dashboard load times
- Consider read replicas for high query volume
- Optimize dashboard queries and time ranges

**Fluentd Resources**:
- Monitor memory usage per node
- Adjust buffer configurations for high log volume
- Consider log sampling for non-critical applications

## Integration with GitOps

### Flux Monitoring

The setup includes monitoring for Flux components:
- **Image Automation**: Track image update frequency
- **Git Repository**: Monitor sync status and errors
- **Kustomization**: Deployment success/failure rates

### Automated Rollback Monitoring

Integration with the existing rollback system:
- **Health Check Metrics**: Track rollback trigger frequency
- **Deployment Status**: Monitor rolling update success rates
- **Application Availability**: Measure zero-downtime achievement

## Security Considerations

### Network Policies
```yaml
# Restrict Prometheus access
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: prometheus-netpol
  namespace: monitoring
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: prometheus
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    - namespaceSelector:
        matchLabels:
          name: kube-system
```

### RBAC
- Fluentd has minimal cluster read permissions
- Prometheus uses least-privilege service accounts
- Grafana authentication configured (change default password)

## Maintenance

### Regular Tasks
1. **Weekly**: Review dashboard performance and accuracy
2. **Monthly**: Analyze storage usage and retention policies
3. **Quarterly**: Update monitoring stack components
4. **As Needed**: Add new ServiceMonitors for new applications

### Backup Procedures
```bash
# Backup Grafana dashboards
kubectl get configmaps -n monitoring -l grafana_dashboard=1 -o yaml > grafana-dashboards-backup.yaml

# Backup Prometheus configuration
kubectl get prometheus -n monitoring -o yaml > prometheus-config-backup.yaml
```

## Performance Metrics

### SLA Targets
- **Application Availability**: 99.9%
- **Monitoring System Availability**: 99.95%
- **Log Processing Latency**: < 30 seconds
- **Metrics Collection Interval**: 15 seconds
- **Dashboard Load Time**: < 3 seconds

### Capacity Planning
- **Metrics Storage**: ~100MB per day per application
- **Log Storage**: ~1GB per day per node
- **Resource Usage**: ~2GB memory, 1 CPU core for full stack