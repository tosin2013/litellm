#!/bin/bash
cd /opt/app-root/src
exec uvicorn litellm.proxy.proxy_server:app --host 0.0.0.0 "$@"
