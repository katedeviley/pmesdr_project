#!/bin/bash
# =============================================================================
# Script: collect_output.sh
# Description: Collects and organizes output files from the processing pipeline.
# Usage: ./collect_output.sh YYYYMMDDHH
# =============================================================================
set -e # Exit on error
source ./config.sh

# ---------------------------
# Argument Parsing
# ---------------------------

if [ $# -eq 1 ]; then
  if [[ $1 =~ ^[0-9]{10}$ ]]; then
    DATEHOUR="$1"
    DATE="${1:0:8}"
    START_HOUR="${1:8:2}"
  else
    echo "Usage: $0 [YYYYMMDDHH]"
    exit 1
  fi
fi

# ----------------------------
# Configuration
# ----------------------------

LOCAL_OUTPUT_DIR="$DATA_DIR/$DATE/S$START_HOUR/output"
FINAL_DIR="$FINAL_OUTPUT_DIR/${DATE}/S${START_HOUR}"
mkdir -p "$FINAL_DIR"

# -----------------------------
# Collect and Move Files
# -----------------------------

MAX_ATTEMPTS=3
ATTEMPT=1
SUCCESS=false

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  if compgen -G "$LOCAL_OUTPUT_DIR"/*.nc > /dev/null; then
    cp "$LOCAL_OUTPUT_DIR"/*.nc "$FINAL_DIR/" 2>/dev/null || true
  fi

  if compgen -G "$LOCAL_OUTPUT_DIR"/geotiff/* > /dev/null; then
    cp -r "$LOCAL_OUTPUT_DIR"/geotiff/ "$FINAL_DIR" 2>/dev/null || true
  fi

  if compgen -G "$FINAL_DIR"/*.nc > /dev/null && \
     compgen -G "$FINAL_DIR"/geotiff/* > /dev/null; then
    SUCCESS=true
    break
  fi

  echo "Attempt $ATTEMPT failed. Retrying..."
  ATTEMPT=$((ATTEMPT + 1))
  sleep 2
done

if [ "$SUCCESS" = true ]; then
  echo "Files copied successfully to $FINAL_DIR."
else
  echo "Error: Files not copied after $MAX_ATTEMPTS attempts."
  exit 1
fi

