#!/bin/bash
# =============================================================================
# Script: download_data.sh
# Description: Downloads AMSR3 1B (JAXA) data for a given time.
# Usage: ./download_data.sh [YYYYMMDDHH]
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

YESTERDAY=$(date -d "$DATE -1 day" +%Y%m%d)

# ---------------------------
# Configuration
# ---------------------------

DEST_1B_DIR="$DATA_DIR/$DATE/S$START_HOUR/input/"
OUTPUT_DIR="${DATA_DIR}/${DATE}/S${START_HOUR}/output"

mkdir -p "$DEST_1B_DIR"
rm -rf "${OUTPUT_DIR:?}/"*

# ---------------------------
# Download 1B Data (G-Portal)
# ---------------------------

# 1B files pattern: GW1AM2_<DATE>*.h5
mkdir -p "$DEST_1B_DIR"
cd "$DEST_1B_DIR" || exit 1
EXISTING_1B=$(ls "$DEST_1B_DIR"/GAASP_L1B_${DATE}*.h5 2>/dev/null || true)
            
if [ -n "$EXISTING_1B" ]; then
  echo "1B files for $DATEHOUR are already present. Skipping downloads."
else
  rm -rf "$DEST_1B_DIR"/*
  echo "Downloading 1B data from JAXA G-Portal for $DATEHOUR..."

  max_attempts=5
  attempt=1

  until sftp -oBatchMode=yes -oConnectTimeout=60 \
    -i "$PRIVATE_KEY_PATH" \
    -oPort=2051 \
    "$GPORTAL_USERNAME"@ftp.gportal.jaxa.jp <<EOF
cd "$GPORTAL_DATA_PATH"
mget GAASP_L1B_${DATE}*.h5
$( [ "$START_HOUR" -gt 16 ] && echo "mget GAASP_L1B_${YESTERDAY}*.h5" )
bye
EOF
  do
      if (( attempt >= max_attempts )); then
          echo "ERROR: SFTP failed after $attempt attempts."
          exit 1
      fi

      echo "Attempt $attempt failed. Retrying in 60 seconds..."
      sleep 60
      ((attempt++))
  done

  echo "G-Portal (JAXA) 1B downloads complete."
fi

cd "$WORKING_DIR"

