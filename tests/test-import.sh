#!/usr/bin/env bash

# Ensure Podman machine is running on macOS
ensure_podman_machine() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Checking Podman machine status on macOS..."
        if ! podman machine list | grep -q "Running"; then
            echo "No running Podman machine found. Starting one..."
            podman machine start
        else
            echo "Podman machine is already running."
        fi
    fi
}

# Setup suite: Start PostgreSQL container
setup_suite() {
    # Set database environment variables
    export DB_HOST=localhost
    export DB_PORT=5432
    export DB_USER=postgres
    export DB_PASSWORD=postgres
    export DB_NAME=gtfs
    export URL_DATA="https://www.vbb.de/vbbgtfs"
    export WORKDIR=/tmp

    ensure_podman_machine
    echo "Starting PostgreSQL container..."
    podman run -d --name postgres-gtfso-import-test \
        -e POSTGRES_USER=${DB_USER} \
        -e POSTGRES_PASSWORD=${DB_PASSWORD} \
        -p 5432:5432 \
        postgres:latest
    sleep 10
}

# Test: Check if the import script runs successfully
test_import_script() {
    # Run the import script
    bash ../import.sh
    local exit_code=$?

    # Check if the script exited successfully
    assert "test $exit_code -eq 0" "import.sh failed with exit code $exit_code"

    # Verify that tables were created in the database
    local tables=$(podman exec -i postgres-gtfso-import-test psql -U postgres -d gtfs -c "\dt" | grep "public" | wc -l)
    assert "test $tables -gt 0" "Expected tables to be created in the database"
}

# Teardown suite: Stop and remove PostgreSQL container
teardown_suite() {
    echo "Stopping PostgreSQL container..."
    podman stop postgres-gtfso-import-test
    podman rm postgres-gtfso-import-test
}
