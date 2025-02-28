# Stage 1: Builder
FROM registry.access.redhat.com/ubi8/python-39:latest as builder

# Set the working directory
WORKDIR /opt/app-root/src

# Install build dependencies
COPY --chown=1001:0 requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir build

# Copy the source code
COPY --chown=1001:0 . .

# Build Admin UI
RUN chmod +x docker/build_admin_ui.sh && ./docker/build_admin_ui.sh

# Build the package
RUN rm -rf dist/* && python -m build

# Stage 2: Runtime
FROM registry.access.redhat.com/ubi8/python-39:latest as runtime

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    PIP_NO_CACHE_DIR=1 \
    PRISMA_BINARY_CACHE_DIR=/opt/app-root/src/.prisma \
    HOME=/opt/app-root/src

WORKDIR /opt/app-root/src

# Copy necessary files from builder and source
COPY --from=builder --chown=1001:0 /opt/app-root/src/dist/*.whl .
COPY --chown=1001:0 . .

# Install application and dependencies
RUN pip install --no-cache-dir *.whl && \
    pip install --no-cache-dir -r requirements.txt && \
    rm -f *.whl && \
    # Install additional dependencies
    pip install --no-cache-dir redisvl==0.0.7 --no-deps && \
    pip uninstall jwt -y && \
    pip uninstall PyJWT -y && \
    pip install PyJWT==2.9.0 --no-cache-dir && \
    # Install Prisma and configure
    pip install --no-cache-dir nodejs-bin prisma && \
    # Build Admin UI
    chmod +x docker/build_admin_ui.sh && \
    ./docker/build_admin_ui.sh && \
    # Generate Prisma client
    mkdir -p .prisma && \
    prisma generate

# Create health check endpoint
RUN echo $'from fastapi import FastAPI\n\
app = FastAPI()\n\
\n\
@app.get("/health")\n\
async def health_check():\n\
    return {"status": "healthy"}' > health_check.py

# Expose port
EXPOSE 4000/tcp

# Set permissions for OpenShift
USER 1001

# Add OpenShift specific labels
LABEL io.openshift.expose-services="4000:http" \
      io.openshift.tags="python,web" \
      io.k8s.description="LiteLLM Proxy Server" \
      io.openshift.non-scalable="false"

# Health check configuration will be handled in the Kubernetes/OpenShift deployment config

ENTRYPOINT ["docker/prod_entrypoint.sh"]
CMD ["--port", "4000"]
