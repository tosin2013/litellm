#!/bin/bash

# Get the master key
MASTER_KEY=$(oc get secret litellm-secret -n litellm -o jsonpath='{.data.master-key}' | base64 -d)

# Create test key using master key
echo "Creating test key..."
curl -X POST https://litellm-proxy-litellm.apps.cluster-gs59q.gs59q.sandbox2933.opentlc.com/key/generate \
-H "Authorization: Bearer $MASTER_KEY" \
-H "Content-Type: application/json" \
-d '{"duration":"1h"}' > key_response.json

echo "Created key response saved to key_response.json"
