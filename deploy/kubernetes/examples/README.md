# Using ConfigMap for LiteLLM Additional Configurations

To add additional configuration files for LiteLLM, you can modify the `config-map.yaml` file located in `deploy/kubernetes/overlays/dev/`.

### Example ConfigMap Structure

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: litellm-config
data:
  config.yaml: |
    model_list:
      - model_name: gpt-4
        litellm_params:
          model: mistralai/Mistral-7B-Instruct-v0.1
          api_base: http://localhost:8000

    litellm_settings:
      drop_params: True
      max_retries: 3
      success_callback: ["logging"]
```

### Adding Additional Configuration Files

1. Open the `config-map.yaml` file in your favorite editor.
2. Add new key-value pairs under the `data` section, where the key is the filename and the value is the file content.
3. Save the changes and apply the ConfigMap using the following command:

```bash
oc apply -f deploy/kubernetes/overlays/dev/config-map.yaml
```

### Example: Adding a Custom Logging Configuration

```yaml
data:
  logging.conf: |
    [loggers]
    keys=root,litellm

    [handlers]
    keys=consoleHandler

    [formatters]
    keys=simpleFormatter

    [logger_root]
    level=DEBUG
    handlers=consoleHandler

    [logger_litellm]
    level=INFO
    handlers=consoleHandler
    qualname=litellm
    propagate=0

    [handler_consoleHandler]
    class=StreamHandler
    level=DEBUG
    formatter=simpleFormatter
    args=(sys.stdout,)

    [formatter_simpleFormatter]
    format=%(asctime)s - %(name)s - %(levelname)s - %(message)s
    datefmt=%Y-%m-%d %H:%M:%S
```

4. Apply the updated ConfigMap:

```bash
oc apply -f deploy/kubernetes/overlays/dev/config-map.yaml
```

5. Restart the LiteLLM deployment to apply the new configuration:

```bash
oc rollout restart deployment/litellm-proxy
```

### Notes

- Ensure that the filenames and content are correctly formatted in the ConfigMap.
- After updating the ConfigMap, you may need to restart the affected pods for the changes to take effect.
