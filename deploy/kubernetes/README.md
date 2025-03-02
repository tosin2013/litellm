# LiteLLM Proxy on OpenShift

This directory contains Kubernetes manifests for deploying LiteLLM Proxy on OpenShift.

## Prerequisites

- OpenShift 4.x cluster with cluster-admin access
- `oc` CLI tool installed and configured
- Access to Quay.io registry

## Image Building and Pushing

### GitHub Actions (Automated)

The repository includes a GitHub Actions workflow that automatically builds and pushes the image to Quay.io on pushes and pull requests to the `dev` branch.

Required GitHub Secrets:
- `QUAY_USERNAME`: Your Quay.io username
- `QUAY_PASSWORD`: Your Quay.io password/token

The workflow:
- Tags images with both the git commit SHA (8 characters) and `latest`
- Pushes to `quay.io/takinosh/litellm-proxy`

### Manual Build and Push

To build and push manually:

```bash
# Login to Quay.io
podman login -u='takinosh+litellmproxy' quay.io

# Get the git commit SHA
COMMIT_SHA=$(git rev-parse --short HEAD)

# Build the image
podman build -t quay.io/takinosh/litellm-proxy:${COMMIT_SHA} .
podman tag quay.io/takinosh/litellm-proxy:${COMMIT_SHA} quay.io/takinosh/litellm-proxy:latest

# Push the images
podman push quay.io/takinosh/litellm-proxy:${COMMIT_SHA}
podman push quay.io/takinosh/litellm-proxy:latest
```

## OpenShift Configuration

### Security Context Constraints (SCC)

The deployment requires a custom SCC to run as user 1001. Apply it before deploying:

```bash
# Create the custom SCC
oc apply -f deploy/kubernetes/base/litellm-proxy-scc.yaml

# Bind the SCC to the service account (done automatically in base/openshift-deployment.yaml)
```

### Deployment

Two overlay configurations are provided:
- `dev`: For development/testing
- `prod`: For production deployment

To deploy the dev environment:

```bash
# Create dev secrets from example
cp deploy/kubernetes/overlays/dev/.env.secret.example deploy/kubernetes/overlays/dev/.env.secret
# Edit .env.secret with your actual values

# Apply the dev overlay
oc apply -k deploy/kubernetes/overlays/dev/
```

To deploy to production:

```bash
# Create prod secrets from example
cp deploy/kubernetes/overlays/prod/.env.secret.example deploy/kubernetes/overlays/prod/.env.secret
# Edit .env.secret with your actual values

# Apply the prod overlay
oc apply -k deploy/kubernetes/overlays/prod/
```

### Verifying the Deployment

```bash
# Check the deployment status
oc get deployment -n litellm-dev  # or litellm-prod for production

# Check the pods
oc get pods -n litellm-dev

# Check the route
oc get route -n litellm-dev
```

## Configuration

The base configuration is in `base/proxy_server_config.yaml`. Environment-specific overrides can be added in the respective overlay directories.
