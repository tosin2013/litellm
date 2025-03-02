# Podman Configuration for LiteLLM

## System Requirements
- RHEL 9.5
- Podman 5.2.2+
- SELinux enabled (enforcing mode)
- User namespace configured for rootless containers

## Storage Configuration
The storage configuration (`config/storage.conf`) is optimized for LiteLLM deployment:
- Uses overlay2 storage driver
- Configures proper storage locations for rootless mode
- Sets up storage quotas and auto-extension

## Network Configuration
The network configuration (`config/network.conf`) establishes:
- Dedicated bridge network "litellm-net"
- DNS configuration for container communication
- IPv4 subnet configuration ready for scaling

## SELinux Configuration
The following SELinux contexts are required:

```bash
# Container process contexts
container_t
container_init_t

# Volume contexts
container_file_t

# Network contexts
container_net_t
```

### SELinux Policy Configuration
1. Container Process Labels:
```bash
semanage fcontext -a -t container_runtime_exec_t /usr/bin/podman
semanage fcontext -a -t container_runtime_exec_t /usr/bin/crun
```

2. Storage Volume Labels:
```bash
semanage fcontext -a -t container_file_t "/home/lab-user/.local/share/containers/storage(/.*)?"
```

3. Network Access:
```bash
setsebool -P container_connect_any 1
```

## Implementation Steps

1. Apply Storage Configuration:
```bash
mkdir -p ~/.config/containers
cp deploy/podman/config/storage.conf ~/.config/containers/storage.conf
```

2. Create Network:
```bash
podman network create litellm-net \
  --driver bridge \
  --subnet 172.24.0.0/16 \
  --gateway 172.24.0.1 \
  --ip-range 172.24.1.0/24
```

3. Verify Configuration:
```bash
podman system info
podman network ls
```

4. Container Security Context:
- Use `--security-opt label=type:container_t`
- Set resource limits using `--cpus` and `--memory`
- Enable health checks

## OpenShift Migration Considerations
This configuration is designed to facilitate migration to OpenShift:
- Network configuration maps to OpenShift SDN
- Storage configuration aligns with persistent volumes
- Security contexts map to SCCs (Security Context Constraints)
- Resource limits align with OpenShift quotas

## Troubleshooting

### SELinux Denials
Check for SELinux denials:
```bash
ausearch -m AVC,USER_AVC -ts recent
```

### Storage Issues
Verify storage setup:
```bash
podman system df
podman info --format='{{.Store.GraphRoot}}'
```

### Network Connectivity
Test network configuration:
```bash
podman network inspect litellm-net
```

## Maintenance

### Regular Cleanup
```bash
podman system prune --volumes
podman network prune
```

### Storage Management
Monitor storage usage:
```bash
du -sh ~/.local/share/containers/storage
podman system df
