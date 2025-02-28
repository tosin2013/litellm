# OpenShift Deployment Guide

This guide explains how to deploy LiteLLM Proxy on OpenShift 4.17+.

## Prerequisites

- OpenShift 4.17+ cluster
- OpenShift CLI (`oc`) installed and configured
- Access to Red Hat Container Registry

## Building the Container Image

### Local Testing

Before deploying to OpenShift, you can test the container build and run it locally:

1. Build the container image:
```bash
# Build with latest tag for local testing
podman build -t litellm-proxy:latest -f Containerfile .
```

2. Test running the container locally:

First, ensure your system is set up for rootless containers:
```bash
# Check if your user has proper subuid/subgid mappings
grep $(whoami) /etc/subuid
grep $(whoami) /etc/subgid

# If missing, set up user namespaces (as root)
sudo usermod --add-subuids 100000-165535 $(whoami)
sudo usermod --add-subgids 100000-165535 $(whoami)

# Verify podman can run rootless
podman info
```

Run the container:
```bash
# Run the container with explicit user namespace
podman run -d --name litellm-proxy \
  --userns=keep-id \
  -p 4000:4000 \
  litellm-proxy:latest

# Check container logs
podman logs -f litellm-proxy

# Test the health endpoint
curl http://localhost:4000/health
```

3. Troubleshooting permission issues:
- If you see "Permission denied" errors:
  ```bash
  # Remove any existing container
  podman rm -f litellm-proxy

  # Run with debug logging
  podman run -d --name litellm-proxy \
    --userns=keep-id \
    --security-opt label=disable \
    -p 4000:4000 \
    litellm-proxy:latest
  ```

- Check container user and permissions:
  ```bash
  # Verify user inside container
  podman exec litellm-proxy id
  
  # Check directory permissions
  podman exec litellm-proxy ls -la /opt/app-root/src
  
  # View container security settings
  podman inspect litellm-proxy --format '{{.HostConfig.SecurityOpt}}'
  ```

### Building for OpenShift

1. Get the git commit ID and build the container image:
```bash
# Get the git commit ID
GIT_COMMIT=$(git rev-parse --short HEAD)

# Build with git commit as tag
podman build -t litellm-proxy:${GIT_COMMIT} -f Containerfile .

# Also tag as latest
podman tag litellm-proxy:${GIT_COMMIT} litellm-proxy:latest
```

2. Tag and push to your container registry:
```bash
# Replace with your registry
podman tag litellm-proxy:${GIT_COMMIT} <your-registry>/litellm-proxy:${GIT_COMMIT}
podman tag litellm-proxy:${GIT_COMMIT} <your-registry>/litellm-proxy:latest

# Push both tags
podman push <your-registry>/litellm-proxy:${GIT_COMMIT}
podman push <your-registry>/litellm-proxy:latest
```

## Deployment

1. Update the image reference in `openshift-deployment.yaml`:
```yaml
spec:
  template:
    spec:
      containers:
      - name: litellm-proxy
        # Use specific git commit version
        image: <your-registry>/litellm-proxy:${GIT_COMMIT}
        # Or use latest
        # image: <your-registry>/litellm-proxy:latest
```

2. Deploy to OpenShift:
```bash
oc apply -f deploy/kubernetes/openshift-deployment.yaml
```

3. Verify the deployment:
```bash
oc get pods
oc get services
oc get routes
```

## Configuration

### Environment Variables

Add environment variables in the `openshift-deployment.yaml` under the `env` section:

```yaml
env:
- name: PYTHONUNBUFFERED
  value: "1"
- name: PORT
  value: "4000"
# Add your configuration here
```

### Resource Limits

The deployment is configured with the following resource limits:
- CPU: 1000m (1 core)
- Memory: 1Gi

Adjust these in `openshift-deployment.yaml` based on your needs.

### Health Checks

The deployment includes:
- Readiness probe: `/health`
- Liveness probe: `/health`

Both probes are configured with:
- Initial delay: 30 seconds
- Period: 10 seconds
- Timeout: 3 seconds

## Security

The container runs with:
- Non-root user (UID 1001)
- Restricted security context
- No privilege escalation
- All capabilities dropped

## Networking

The service is exposed via:
- Internal Service: Port 4000
- OpenShift Route: HTTPS with edge termination

## Monitoring

Monitor the deployment using:
```bash
# View logs
oc logs deploymentconfig/litellm-proxy

# Check deployment status
oc status
```

## Troubleshooting

1. If pods fail to start, check logs:
```bash
oc get pods
oc logs <pod-name>
```

2. For permission issues, verify the service account has necessary permissions:
```bash
oc describe pod <pod-name>
```

3. For networking issues, verify the route is created:
```bash
oc get routes
