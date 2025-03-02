#!/bin/bash

# Destroy existing deployment
echo "Destroying existing deployment..."
kustomize build deploy/kubernetes/overlays/dev | oc delete -n litellm -f -

# Create new deployment
echo "Creating new deployment..."
kustomize build deploy/kubernetes/overlays/dev | oc apply -n litellm -f -

# Verify pod status with more detailed output
echo "Waiting for pods to be ready..."
while true; do
    echo "Current pod status:"
    oc get pods -n litellm
    if [ "$(oc get pods -n litellm -o jsonpath='{.items[?(@.status.phase=="Running")].status.conditions[?(@.type=="Ready")].status}' | wc -w)" -eq 2 ]; then
        break
    fi
    echo "Waiting 5 seconds..."
    sleep 5
done

echo "Pods are ready!"

# Get pod names
PROXY_POD=$(oc get pods -n litellm -l app=litellm-proxy -o jsonpath='{.items[0].metadata.name}')
DB_POD=$(oc get pods -n litellm -l app=litellm-db -o jsonpath='{.items[0].metadata.name}')

# Check logs
echo "Checking logs for database pod..."
oc logs -n litellm $DB_POD

echo "Checking logs for litellm-proxy pod..."
oc logs -n litellm $PROXY_POD -c proxy

# Test health endpoint
echo "Testing health endpoint..."
curl -v -X GET https://litellm-proxy-litellm.apps.cluster-gs59q.gs59q.sandbox2933.opentlc.com/health \
-H "Authorization: Bearer dev-master-key-123"

# Test LLM endpoint
echo "Testing LLM endpoint..."
curl -v -X POST https://litellm-proxy-litellm.apps.cluster-gs59q.gs59q.sandbox2933.opentlc.com/v1/completions \
-H "Authorization: Bearer dev-master-key-123" \
-H "Content-Type: application/json" \
-d '{"prompt": "Hello, world!", "model": "mistralai/Mistral-7B-Instruct-v0.2", "max_tokens": 10}'
