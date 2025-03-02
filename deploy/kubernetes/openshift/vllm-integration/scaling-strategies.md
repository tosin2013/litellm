# LiteLLM: Scaling Strategies on OpenShift with VLLM

This document outlines strategies for scaling a LiteLLM deployment on OpenShift, with a focus on deployments using VLLM for efficient model serving.

## Horizontal Pod Autoscaling (HPA)

The primary mechanism for scaling LiteLLM on OpenShift is Horizontal Pod Autoscaling (HPA). HPA automatically adjusts the number of pods in a Deployment based on observed metrics.

### Metrics for Scaling

Several metrics can be used to trigger scaling:

1.  **CPU Utilization:**  This is a standard metric and is readily available.  You can set a target CPU utilization percentage, and HPA will add or remove pods to maintain that target.

2.  **Memory Utilization:** Similar to CPU utilization, HPA can scale based on memory usage.

3.  **Custom Metrics:**  For more fine-grained control, you can use custom metrics.  Examples relevant to LiteLLM and VLLM include:
    *   **Request Rate:** The number of incoming requests per second.
    *   **Request Latency:** The average time taken to process a request.
    *   **GPU Utilization:** (If using GPUs) The percentage of GPU resources being used.
    *   **VLLM Queue Length:** (If using VLLM) The number of requests waiting in the VLLM queue.

### Configuring HPA

HPA is configured using a `HorizontalPodAutoscaler` resource.  Here's an example:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: litellm-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: litellm-proxy  #  Name of your LiteLLM Deployment
  minReplicas: 1         # Minimum number of pods
  maxReplicas: 10        # Maximum number of pods
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Target CPU utilization (70%)
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
# Example for custom metrics (requires Prometheus and custom metrics adapter)
#  - type: Pods
#    pods:
#      metric:
#        name: vllm_queue_length
#      target:
#        type: AverageValue
#        averageValue: 5  # Target average queue length of 5
```

**Explanation:**

*   `scaleTargetRef`: Specifies the Deployment to scale.
*   `minReplicas` and `maxReplicas`: Define the minimum and maximum number of pods.
*   `metrics`:  Defines the metrics to use for scaling.  The example shows CPU and memory utilization. You can add custom metrics as needed.

**Applying the HPA:**

```bash
oc apply -f hpa.yaml  # Assuming the above configuration is saved in hpa.yaml
```

## Vertical Pod Autoscaling (VPA)

Vertical Pod Autoscaling (VPA) automatically adjusts the resource *requests* and *limits* for the containers within a pod.  While HPA adds or removes pods, VPA changes the resources allocated to existing pods. VPA can be useful for optimizing resource utilization, but it's generally less dynamic than HPA for handling fluctuating workloads. VPA is less commonly used with VLLM than HPA.

## Considerations for VLLM

*   **GPU Resources:** When using VLLM with GPUs, ensure that your OpenShift cluster has sufficient GPU resources and that the GPU Operator is properly configured.
*   **Warm-up:**  VLLM may require a warm-up period to load the model and optimize performance.  Consider this when setting scaling thresholds.
*   **Request Batching:** VLLM can benefit from request batching.  If your application can batch requests, this can improve throughput and efficiency.
* **Monitoring:** It is critical to have good monitoring in place.

## Monitoring

Effective scaling requires monitoring.  Use OpenShift's built-in monitoring tools (Prometheus, Grafana) or integrate with external monitoring solutions to track:

*   CPU and memory utilization of the LiteLLM pods.
*   GPU utilization (if applicable).
*   Request rate and latency.
*   VLLM-specific metrics (queue length, cache hit rate, etc.).

By monitoring these metrics, you can fine-tune the HPA configuration and ensure that your LiteLLM deployment scales effectively to meet demand.
