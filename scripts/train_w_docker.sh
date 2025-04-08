#!/bin/bash

DOCKER_IMAGE_NAME=$1
EXPERIMENT_NAME=$2
EXPERIMENT_PARAMS=$[@!]


MAX_RAM_USAGE=30 # 30 GB

CACHE_LLMS_DATASETS="/llms"


docker run --rm \
           --memory=${MAX_RAM_USAGE}g \
           --gpus ... \
           ${DOCKER_IMAGE_NAME} \
           ${EXPERIMENT_NAME} \
           ${EXPERIMENT_PARAMS}

