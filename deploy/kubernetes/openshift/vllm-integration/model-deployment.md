# LiteLLM: VLLM Integration and Model Deployment on OpenShift

This document describes how to integrate VLLM (vLLM: Efficient Memory Management for Large Language Model Serving with PagedAttention) with LiteLLM on OpenShift and deploy models using VLLM.

## Prerequisites

*   **OpenShift Cluster:** Access to an OpenShift cluster with GPU resources.
*   **GPU Operator:** The NVIDIA GPU Operator must be installed and configured on the OpenShift cluster.
*   **LiteLLM Image:** A LiteLLM container image built with VLLM support (as described in the `Containerfile`).  This image should be available in a container registry accessible by OpenShift (e.g., `quay.io/takinosh/litellm-proxy`).
* **Migration Complete:** You must have completed the steps in `migration-guide.md`

## VLLM Configuration

VLLM configuration is primarily done through environment variables. These can be set within the LiteLLM configuration file (`config.yaml`) or directly within the OpenShift Deployment.

### Key Environment Variables

*   **`MODEL_NAME`:**  The name of the model to load (e.g., `codellama/CodeLlama-7b-Instruct-hf`). This should correspond to a model supported by VLLM.
*   **`MODEL_PATH`:** (Optional) The path to a local model directory. If not specified, the model will be downloaded from Hugging Face Hub.
*   **`USE_VLLM`:** Set to `True` to enable VLLM.
*   **`VLLM_GPU_MEMORY_UTILIZATION`:**  (Optional) Controls the fraction of GPU memory to allocate to VLLM.  Default is typically 0.9.
*   **`VLLM_SWAP_SPACE`:** (Optional) The size of CPU memory to use as swap space for VLLM.
*   **`VLLM_ENGINE_KWARGS`:** (Optional) Additional keyword arguments to pass to the VLLM engine. See VLLM documentation for available options.
*  **`VLLM_LOAD_FORMAT`**: (Optional) The format of the model weights to load. Options: `auto`, `pt`, `safetensors`, `npcache`, `dummy`. Default: `auto`.
* **`VLLM_QUANTIZATION`**: (Optional) Quantization method. Options: `awq`, `gptq`, `squeezellm`, `fp8`.
* **`VLLM_DTYPE`**: (Optional) Data type for model weights and activations. Options: `auto`, `half`, `float16`, `bfloat16`, `float`, `float32`. Default: `auto`.
* **`VLLM_MAX_MODEL_LEN`**: (Optional) Model context length. This may need adjustments depending on the model.
* **`VLLM_TRUST_REMOTE_CODE`**: (Optional, but often required) Set to `True` if the model requires custom code execution (trust remote code).

### Example Configuration (within `config.yaml`)

```yaml
model_list:
  - model_name: codellama-vllm
    litellm_params:
      model: codellama/CodeLlama-7b-Instruct-hf
      api_base: http://localhost:8000  #  This will be overridden by OpenShift Route
      use_vllm: True
      vllm_gpu_memory_utilization: 0.8
      vllm_max_model_len: 4096
      vllm_trust_remote_code: True
```

### Example Configuration (within OpenShift Deployment)
```
        env:
        - name: USE_VLLM
          value: "True"
        - name: MODEL_NAME
          value: "codellama/CodeLlama-7b-Instruct-hf"
        - name: VLLM_GPU_MEMORY_UTILIZATION
          value: "0.8"
        - name: VLLM_MAX_MODEL_LEN
          value: "4096"
        - name: VLLM_TRUST_REMOTE_CODE
          value: "True"
```

## Deployment Steps

1.  **Update Deployment:** Modify the OpenShift Deployment (`deploy/kubernetes/base/deployment.yaml`) to include the necessary environment variables for VLLM.  Ensure the `image` points to your LiteLLM image with VLLM support (e.g., `quay.io/takinosh/litellm-proxy:latest`).

2.  **Resource Requests:**  Within the Deployment, specify resource requests and limits for CPU, memory, and GPU.  The GPU request is crucial for VLLM.

    ```yaml
          resources:
            requests:
              memory: "16Gi"  # Adjust as needed
              cpu: "4"       # Adjust as needed
              nvidia.com/gpu: "1"  # Request one GPU
            limits:
              memory: "32Gi" # Adjust as needed
              cpu: "8"      # Adjust as needed
              nvidia.com/gpu: "1"
    ```

3.  **Apply Changes:** Apply the updated Deployment:
    ```bash
    oc apply -f deploy/kubernetes/base/deployment.yaml
    ```

4.  **Verify:** Check the pod status and logs to ensure VLLM is loading the model correctly.

    ```bash
    oc get pods
    oc logs <pod-name> -c proxy
    ```

## Model Management

VLLM can load models from Hugging Face Hub or from a local directory.  For OpenShift deployments, it's generally recommended to use models from Hugging Face Hub or a private model repository. If using a local directory, you'll need to ensure the model files are available within the container (e.g., using a Persistent Volume Claim).

## Scaling

VLLM supports efficient serving of multiple requests.  You can scale the LiteLLM deployment horizontally by increasing the number of replicas in the OpenShift Deployment.  OpenShift's Horizontal Pod Autoscaler can be used to automatically scale the deployment based on resource utilization or custom metrics.

## Troubleshooting

*   **GPU Errors:** Ensure the GPU Operator is correctly installed and that the pods are scheduled on nodes with available GPUs.
*   **Model Loading Errors:** Verify the `MODEL_NAME` and `MODEL_PATH` (if used) are correct. Check the VLLM logs for specific error messages.
*   **Out of Memory Errors:** Adjust `VLLM_GPU_MEMORY_UTILIZATION` or increase the GPU memory request.
*   **Dependency Issues:** Ensure all required dependencies are installed in the container image.
