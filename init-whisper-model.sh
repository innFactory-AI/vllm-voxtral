#!/bin/bash
set -e

echo "=== Speaches Whisper Model Initialization ==="

# Configuration
API_URL="http://localhost:8000"
MAX_WAIT=60
CHECK_INTERVAL=2

# Map common model names to full Hugging Face model paths
declare -A MODEL_MAP=(
    ["tiny"]="Systran/faster-whisper-tiny"
    ["base"]="Systran/faster-whisper-base"
    ["small"]="Systran/faster-whisper-small"
    ["medium"]="Systran/faster-whisper-medium"
    ["large"]="Systran/faster-whisper-large-v3"
    ["turbo"]="Systran/faster-distil-whisper-large-v3"
)

# Get the model from environment variable, default to base
MODEL_NAME="${WHISPER__MODEL:-base}"

# Map to full model path if it's a short name
if [[ -n "${MODEL_MAP[$MODEL_NAME]}" ]]; then
    FULL_MODEL_PATH="${MODEL_MAP[$MODEL_NAME]}"
    echo "Model '${MODEL_NAME}' mapped to '${FULL_MODEL_PATH}'"
else
    # Assume it's already a full path (e.g., user/model-name)
    FULL_MODEL_PATH="${MODEL_NAME}"
    echo "Using full model path: '${FULL_MODEL_PATH}'"
fi

# URL-encode the model path (replace / with %2F)
ENCODED_MODEL_PATH="${FULL_MODEL_PATH//\//%2F}"

echo "Waiting for Speaches API to be ready..."

# Wait for API to be ready
elapsed=0
while [ $elapsed -lt $MAX_WAIT ]; do
    if curl -s -f "${API_URL}/health" > /dev/null 2>&1 || curl -s -f "${API_URL}/v1/models" > /dev/null 2>&1; then
        echo "✓ API is ready!"
        break
    fi
    echo "  Waiting for API... (${elapsed}s/${MAX_WAIT}s)"
    sleep $CHECK_INTERVAL
    elapsed=$((elapsed + CHECK_INTERVAL))
done

if [ $elapsed -ge $MAX_WAIT ]; then
    echo "⚠ Warning: API did not respond within ${MAX_WAIT}s, proceeding anyway..."
fi

# Check if model is already downloaded
echo "Checking if model '${FULL_MODEL_PATH}' is already available..."
if curl -s "${API_URL}/v1/models" | grep -q "\"id\".*\"${FULL_MODEL_PATH}\""; then
    echo "✓ Model '${FULL_MODEL_PATH}' is already downloaded"
else
    echo "Downloading model '${FULL_MODEL_PATH}'..."
    
    # Download the model
    HTTP_CODE=$(curl -s -o /tmp/download_response.json -w "%{http_code}" -X POST "${API_URL}/v1/models/${ENCODED_MODEL_PATH}")
    
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
        echo "✓ Model '${FULL_MODEL_PATH}' downloaded successfully!"
    else
        echo "⚠ Warning: Failed to download model (HTTP ${HTTP_CODE})"
        echo "Response: $(cat /tmp/download_response.json)"
        echo "The container will start anyway, but you may need to download the model manually."
    fi
fi

echo "=== Initialization Complete ==="
echo ""

# Execute the original command (passed as arguments to this script)
exec "$@"
