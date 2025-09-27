#!/bin/sh
set -eu

# Configuration
MINIO_ALIAS="local"
MINIO_URL="http://minio:9000"
MINIO_ACCESS_KEY="minioadmin"
MINIO_SECRET_KEY="minioadmin123"
BUCKET_NAME="tfstate"

# Wait for MinIO to be reachable (up to ~60s)
i=0
until mc alias set "$MINIO_ALIAS" "$MINIO_URL" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" >/dev/null 2>&1; do
  i=$((i+1))
  if [ "$i" -ge 30 ]; then
    echo "MinIO not ready after 60s" >&2
    exit 1
  fi
  echo "Waiting for MinIO..."
  sleep 2
done

# Ensure alias is configured (idempotent)
mc alias set "$MINIO_ALIAS" "$MINIO_URL" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY"

# Create bucket if it doesn't exist
if ! mc ls "$MINIO_ALIAS/$BUCKET_NAME" >/dev/null 2>&1; then
  mc mb "$MINIO_ALIAS/$BUCKET_NAME"
  # Optionally make it public for downloads (not recommended for tfstate)
  # mc anonymous set download "$MINIO_ALIAS/$BUCKET_NAME"
fi

echo "MinIO bucket $BUCKET_NAME ready."