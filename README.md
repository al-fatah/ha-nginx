# HA NGINX Helm Chart

## Overview
This Helm chart deploys a **Highly Available (HA) NGINX reverse proxy** on Kubernetes with **3 replicas** by default. It supports configurable upstream servers and an optional SSL/TLS mode for secure production deployment.

---

## Features
- **High Availability:** Three replicas with PodAntiAffinity and topology spread constraints.
- **Configurable Upstreams:** Define backend server pools in `values.yaml`.
- **TLS Toggle:** Enable or disable HTTPS by switching `tls.enabled` (true/false).
- **PodDisruptionBudget:** Ensures at least two pods remain available during node maintenance.
- **Safe Rollouts:** Any ConfigMap change triggers a rolling update automatically.
- **Security:** Runs NGINX as a non-root user with resource limits.

---

## Folder Structure
```
ha-nginx/
├── Chart.yaml                # Chart metadata
├── values.yaml               # Default configuration
└── templates/
    ├── _helpers.tpl          # Helper templates for naming & labels
    ├── configmap.yaml        # Generates nginx.conf (upstreams + TLS)
    ├── deployment.yaml       # Deployment definition (3 replicas)
    ├── service.yaml          # Exposes ports 80 and 443
    ├── pdb.yaml              # PodDisruptionBudget
    └── NOTES.txt             # Post-installation instructions
```

---

## Prerequisites
- A running Kubernetes cluster (minikube, kind, EKS, GKE, etc.)
- `kubectl` and `helm` (v3+) installed and configured

Verify setup:
```bash
kubectl version --short
helm version
```

---

## Installation
### 1. Create Namespace
```bash
kubectl create namespace web
```

### 2. Install Chart (HTTP mode)
```bash
helm install my-ha ./ha-nginx -n web
```

Verify deployment:
```bash
kubectl -n web get deploy,po,svc -l app.kubernetes.io/instance=my-ha
```

Port-forward for testing:
```bash
kubectl -n web port-forward svc/my-ha-ha-nginx 8080:80
curl -i http://127.0.0.1:8080/health
```

---

## Configuration
### Upstream Servers
Define your backend servers in a custom `my-values.yaml` file:
```yaml
upstreams:
  name: api_pool
  servers:
    - host: my-api-1.default.svc.cluster.local
      port: 9000
      weight: 1
    - host: my-api-2.default.svc.cluster.local
      port: 9000
serverNames:
  - example.internal
```
Apply the configuration:
```bash
helm upgrade my-ha ./ha-nginx -n web -f my-values.yaml
```

---

### Enabling TLS/HTTPS
1. Create a TLS secret:
```bash
kubectl -n web create secret tls ha-nginx-tls --cert=tls.crt --key=tls.key
```

2. Add TLS settings to `tls-values.yaml`:
```yaml
tls:
  enabled: true
  secretName: ha-nginx-tls
```

3. Upgrade release:
```bash
helm upgrade my-ha ./ha-nginx -n web -f my-values.yaml -f tls-values.yaml
```

4. Test via HTTPS:
```bash
kubectl -n web port-forward svc/my-ha-ha-nginx 8443:443
curl -ik https://127.0.0.1:8443/health
```

---

## Exposing the Service
Choose how you want to make it accessible:

**LoadBalancer:**
```bash
helm upgrade my-ha ./ha-nginx -n web --set service.type=LoadBalancer
kubectl -n web get svc my-ha-ha-nginx -w
```

**NodePort:**
```bash
helm upgrade my-ha ./ha-nginx -n web --set service.type=NodePort
kubectl -n web get svc my-ha-ha-nginx
```

**Ingress (recommended):** Use an Ingress resource for domain-based routing with cert-manager.

---

## Verification & Testing
### Check Resources
```bash
kubectl -n web get pods,svc -l app.kubernetes.io/instance=my-ha
kubectl -n web describe svc my-ha-ha-nginx
```

### Health Endpoint
```bash
curl -i http://127.0.0.1:8080/health
# or if TLS enabled
curl -ik https://127.0.0.1:8443/health
```

### Logs & Configuration
```bash
kubectl -n web logs deploy/my-ha-ha-nginx --tail=50
kubectl -n web get configmap my-ha-ha-nginx-conf -o jsonpath='{.data.nginx\.conf}' | head -n 40
```

---

## Operational Commands
| Task | Command |
|------|----------|
| **Scale replicas** | `helm upgrade my-ha ./ha-nginx -n web --set replicaCount=5` |
| **Rollout restart** | `kubectl -n web rollout restart deploy/my-ha-ha-nginx` |
| **Rollback** | `helm rollback my-ha <REV> -n web` |
| **Uninstall** | `helm uninstall my-ha -n web` |

---

## Troubleshooting
| Issue | Cause / Fix |
|--------|--------------|
| `namespace not found` | Run `kubectl create namespace web` or use `--create-namespace` |
| `cluster unreachable` | Fix kubeconfig or ensure cluster is running |
| `gt type error` | Cast value: use `(int .Values.replicaCount)` in template |
| `toBool not defined` | Remove `toBool` (old Helm versions <3.5) |
| `Empty reply from server` | Ensure port-forward active and scheme (HTTP/HTTPS) matches TLS config |

---

## Demonstrating High Availability
1. Drain a node:
```bash
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --force
```
2. Check PDB:
```bash
kubectl -n web get pdb
```
3. Observe pods remain available (minAvailable=2).

---

## Next Steps / Extensions
- Add **Ingress** for domain-based access.
- Integrate **cert-manager** for automatic TLS certificates.
- Add **HorizontalPodAutoscaler (HPA)** for dynamic scaling.
- Ship **NGINX logs** to monitoring stack (Promtail, Fluent Bit).

---

## License
This chart is open for educational and demonstration purposes.
