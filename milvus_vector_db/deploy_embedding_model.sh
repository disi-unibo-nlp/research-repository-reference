#!/bin/bash

echo "Loading embeddings model..."
infinity_emb v2 \
    --host 0.0.0.0 \
    --model-id $EMB_MODEL_NAME \
    --url-prefix /v1 \
    --batch-size $EMB_MODEL_MAX_BATCH \
    --port $EMB_PORT > /dev/null 2>&1 &