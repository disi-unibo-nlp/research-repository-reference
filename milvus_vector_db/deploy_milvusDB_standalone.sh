#!/bin/bash

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Deploy Milvus database in standalone mode"
    echo
    echo "Options:"
    echo "  -f, --config-file PATH      Docker configuration file path"
    echo "                              (default: vector_db_configuration/milvus.yaml)"
    echo "  -h, --help                  Display this help message"
    exit 1
}

# Default values
DOCKER_CONFIGURATION_FILE_PATH="milvus_vector_db/milvus.yaml"

# Parse command line arguments
while getopts "f:h-:" opt; do
    case "${opt}" in
        -)
            case "${OPTARG}" in
                config-file) DOCKER_CONFIGURATION_FILE_PATH="$2"; shift 2;;
                help) usage;;
                *) usage;;
            esac;;
        f) DOCKER_CONFIGURATION_FILE_PATH=$OPTARG;;
        h) usage;;
        *) usage;;
    esac
done

# Validate required parameters
if [ ! -f "$DOCKER_CONFIGURATION_FILE_PATH" ]; then
    echo "Error: Docker configuration file not found: $DOCKER_CONFIGURATION_FILE_PATH"
    exit 1
fi

echo "Building Docker Compose configuration file"
docker compose -f $DOCKER_CONFIGURATION_FILE_PATH build

echo "Starting Docker image creation"
docker compose -f $DOCKER_CONFIGURATION_FILE_PATH up -d