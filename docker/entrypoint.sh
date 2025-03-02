#!/bin/bash

# Function to check if PostgreSQL is ready
wait_for_postgres() {
    echo "Waiting for PostgreSQL to be ready..."
    max_retries=30
    counter=0
    
    while [ $counter -lt $max_retries ]
    do
        if pg_isready -h "$DATABASE_HOST" -p "${DATABASE_PORT:-5432}"; then
            echo "PostgreSQL is ready!"
            return 0
        fi
        echo "PostgreSQL is not ready yet. Retrying... ($((counter + 1))/$max_retries)"
        counter=$((counter + 1))
        sleep 2
    done
    
    echo "Failed to connect to PostgreSQL after $max_retries attempts"
    return 1
}

# Function to run migrations with retries
run_migrations() {
    echo "Running database migrations..."
    max_retries=3
    counter=0
    
    while [ $counter -lt $max_retries ]
    do
        if python3 litellm/proxy/prisma_migration.py; then
            echo "Migration script ran successfully!"
            return 0
        fi
        echo "Migration failed. Retrying... ($((counter + 1))/$max_retries)"
        counter=$((counter + 1))
        sleep 5
    done
    
    echo "Failed to run migrations after $max_retries attempts"
    return 1
}

# Ensure we have necessary environment variables
if [ -z "$DATABASE_HOST" ]; then
    echo "ERROR: DATABASE_HOST environment variable is not set"
    exit 1
fi

# Configure permissions for OpenShift
if [ "$(id -u)" != "0" ]; then
    echo "Running as non-root user, ensuring proper permissions..."
    # Ensure the directory exists and has correct permissions
    mkdir -p /opt/app-root/src/.postgresql
    chmod 700 /opt/app-root/src/.postgresql
fi

# Main execution flow
echo "Current directory: $(pwd)"

# Wait for PostgreSQL
if ! wait_for_postgres; then
    exit 1
fi

# Run migrations
if ! run_migrations; then
    exit 1
fi

# If we get here, everything succeeded
echo "Initialization completed successfully"
