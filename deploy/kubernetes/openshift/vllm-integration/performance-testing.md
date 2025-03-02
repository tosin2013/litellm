# LiteLLM: Performance Testing and Optimization on OpenShift with VLLM

This document provides guidance on performance testing and optimization for LiteLLM deployments on OpenShift, particularly when using VLLM for model serving.

## Performance Testing Tools

Several tools can be used for performance testing:

*   **`locust`:** A popular open-source load testing tool written in Python.  It allows you to define user behavior in code and simulate many concurrent users.
*   **`wrk`:** A modern HTTP benchmarking tool capable of generating significant load.
*   **`hey`:**  A simple HTTP load generator.
*   **`vegeta`:** A versatile HTTP load testing tool written in Go.
* **`jmeter`** Another popular open-source load testing tool written in Java.

For LiteLLM, `locust` is often a good choice because it allows you to easily define complex request patterns and simulate realistic user behavior. However, any of the listed tools can be used depending on your specific needs.

## Testing Methodology

1.  **Define Metrics:** Determine the key performance indicators (KPIs) you want to measure.  Common metrics include:
    *   **Throughput (Requests/Second):** The number of requests the system can handle per second.
    *   **Latency (Response Time):** The time it takes for the system to respond to a request.
    *   **Error Rate:** The percentage of requests that result in errors.
    *   **Resource Utilization:** CPU, memory, and GPU utilization (if applicable).

2.  **Establish a Baseline:** Before making any optimizations, establish a baseline performance level.  This will help you measure the impact of your changes.

3.  **Load Testing:** Use a load testing tool (e.g., `locust`) to simulate realistic user traffic.  Start with a low load and gradually increase it to identify performance bottlenecks.

4.  **Monitoring:**  During load testing, monitor the KPIs defined in step 1. Use OpenShift's built-in monitoring tools (Prometheus, Grafana) or integrate with external monitoring solutions.

5.  **Analyze Results:** Identify performance bottlenecks.  Are requests slow?  Is CPU, memory, or GPU utilization high?  Are there errors?

6.  **Optimize:** Based on the analysis, make targeted optimizations.  See the "Optimization Strategies" section below.

7.  **Retest:** After making optimizations, retest to measure the impact of your changes.

## Optimization Strategies

### LiteLLM Configuration

*   **`max_batch_size`:**  If using VLLM, experiment with different `max_batch_size` values. Larger batch sizes can improve throughput but may increase latency.
*   **`num_workers`:** Adjust the number of worker processes in the LiteLLM configuration.
* **Caching:** Enable LiteLLM's built-in caching to reduce the number of requests to the underlying model.

### VLLM Configuration

*   **`gpu_memory_utilization`:**  Tune this parameter to find the optimal balance between GPU memory usage and performance.
*   **`swap_space`:**  Adjust the CPU swap space allocated to VLLM.
*   **`max_model_len`:** Set this to the maximum context length supported by your model.
* **`load_format`**: Experiment with different model weight loading formats.
* **`quantization`**: Consider using quantization to reduce model size and improve performance.

### OpenShift Configuration

*   **Horizontal Pod Autoscaling (HPA):** Configure HPA to automatically scale the number of LiteLLM pods based on load.
*   **Resource Requests and Limits:**  Set appropriate resource requests and limits for CPU, memory, and GPU (if applicable).
*   **Node Affinity/Anti-Affinity:**  Use node affinity or anti-affinity to control pod placement and ensure optimal resource utilization. For example, you might want to ensure that LiteLLM pods with GPU requirements are scheduled on nodes with GPUs.
* **Networking:** Use a performant network configuration.

### Model-Specific Optimizations

*   **Model Selection:** Choose a model that is appropriate for your use case and performance requirements. Smaller, more efficient models may be suitable for some applications.
*   **Prompt Engineering:** Optimize your prompts to be concise and efficient.
*   **Quantization:** If not already using VLLM quantization, consider using other quantization techniques to reduce model size and improve inference speed.

### Code Optimizations
* Use asynchronous programming with `async` and `await` to handle concurrent requests efficiently.
* Profile your code to identify performance bottlenecks.

## Example `locustfile.py`

```python
from locust import HttpUser, task, between
import json

class LiteLLMUser(HttpUser):
    wait_time = between(1, 3)  # Simulate user think time

    @task
    def completion(self):
        headers = {"Content-Type": "application/json"}
        data = {
            "model": "codellama/CodeLlama-7b-Instruct-hf", # Replace with your model
            "messages": [
                {"role": "user", "content": "Write a python function to do [TASK]"}
            ]
        }
        with self.client.post("/chat/completions", headers=headers, data=json.dumps(data), catch_response=True) as response:
            if response.status_code != 200:
                response.failure(f"Request failed with status code {response.status_code}: {response.text}")

# Run with: locust -f locustfile.py --host=<your-openshift-route-url>
```

**Remember to replace `<your-openshift-route-url>` with the actual URL of your OpenShift Route.**

This example demonstrates a basic load test using `locust`. You can customize the request data, headers, and user behavior to simulate your specific use case. You would run this *after* deploying to OpenShift.
