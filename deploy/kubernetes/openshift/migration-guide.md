# Migrating LiteLLM from Podman to OpenShift

This document outlines the steps to migrate LiteLLM from a local Podman deployment to an OpenShift cluster.

## Prerequisites

* Access to an OpenShift cluster
* `oc` CLI tool installed and configured
* Ensure you have the Kubernetes deployment files located in the `deploy/kubernetes` directory of this repository.

## Migration Steps

1. **Export Podman Configuration (if applicable):**
   - If you have specific configurations in your Podman setup (e.g., environment variables, volumes), document them as you will need to re-apply them in OpenShift. In most cases, LiteLLM configurations are managed via `config.yaml` and environment variables, which will be configured in OpenShift using ConfigMaps and Secrets.

2. **Prepare OpenShift Deployment Files:**
   - Navigate to the `deploy/kubernetes/openshift` directory.
   - Review and customize the Kubernetes deployment files, specifically:
     - `deploy/kubernetes/base/deployment.yaml`: Defines the LiteLLM proxy deployment. Pay attention to resource requests/limits and environment variables.
     - `deploy/kubernetes/base/service.yaml`: Defines the service to expose the LiteLLM proxy.
     - `deploy/kubernetes/overlays/dev/config-map.yaml`: Contains the `config.yaml` for LiteLLM. Customize this with your desired settings.
     - `deploy/kubernetes/overlays/dev/litellm-secret.yaml` and `deploy/kubernetes/overlays/dev/litellm-db-secret.yaml`:  Manage sensitive information like the master key and database URL. Ensure these secrets are properly configured for your OpenShift environment.
   - **Important:**  Pay close attention to the `image:` tag in `deployment.yaml` to ensure it points to the correct LiteLLM proxy image you intend to deploy.

3. **Create OpenShift Project (Namespace):**
   - Use the OpenShift CLI (`oc`) to create a new project (namespace) for LiteLLM:
     ```bash
     oc new-project litellm
     ```
     Replace `litellm` with your desired project name.

4. **Apply Deployment Files:**
   - From the root of the repository, apply the Kubernetes manifests using `kustomize`:
     ```bash
     oc apply -k deploy/kubernetes/overlays/dev/
     ```
     This command will deploy LiteLLM proxy, service, configmap, and secrets to your OpenShift project.

5. **Verify Deployment:**
   - Check if the pods are running:
     ```bash
     oc get pods -n litellm
     ```
     Wait until all pods are in `Running` status.
   - Check the service status:
     ```bash
     oc get svc -n litellm
     ```
     Verify that the `litellm-proxy` service is created and has an external endpoint if you configured it to be exposed externally.
   - Access LiteLLM proxy endpoint:
     - If you exposed the service externally, find the external URL and access the LiteLLM proxy health endpoint (e.g., `http://<external-ip>:<port>/health`) to ensure it's running correctly.

## Post-Migration Steps

* **Monitoring:** Set up monitoring for your LiteLLM deployment in OpenShift to track resource usage, request latency, and error rates.
* **Scaling:**  Adjust the number of replicas in `deployment.yaml` to scale your LiteLLM proxy deployment based on your traffic needs.
* **Persistence:** If you are using a database for LiteLLM (e.g., for logging or rate limiting), ensure persistent storage is correctly configured in your OpenShift environment for the database.
* **Security:** Review and enhance security configurations as needed for your OpenShift environment, such as network policies and security contexts.

## Troubleshooting

* **ImagePullBackOff:** If pods are stuck in `ImagePullBackOff`, check if the container image name in `deployment.yaml` is correct and if the OpenShift cluster has access to pull the image.
* **Configuration Errors:** If the LiteLLM proxy fails to start, check the pod logs (`oc logs <pod-name> -n litellm`) for any configuration errors related to `config.yaml` or environment variables.
* **Database Connection Issues:** If LiteLLM cannot connect to the database, verify the database URL in the `litellm-db-secret` and ensure the database is accessible from within the OpenShift cluster.
* **Service Access Issues:** If you cannot access the LiteLLM proxy service, check the service definition in `service.yaml` and ensure that network policies or OpenShift routes are configured to allow access to the service.

This guide provides a general outline. Specific steps might vary based on your Podman setup and OpenShift environment. Always refer to the official OpenShift documentation for detailed instructions on OpenShift operations.
