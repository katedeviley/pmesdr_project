#!/bin/bash
# =============================================================================
# Script: process_amsr2_data.sh
# Description: Downloads AMSR2 1C (NASA) and 1B (JAXA) data for a given
#              6-hour window. Defaults to the last full quarter day if no
#              date argument is provided.
# Usage: ./process_amsr2_data.sh [YYYYMMDDHH]
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
# Local Output Dir
# ---------------------------

DEST_1B_DIR="${DATA_DIR}/${DATE}/S${START_HOUR}/input/1B"
DEST_1C_DIR="${DATA_DIR}/${DATE}/S${START_HOUR}/input/1C"
OUTPUT_DIR="${DATA_DIR}/${DATE}/S${START_HOUR}/output"

mkdir -p "$DEST_1C_DIR" "$DEST_1B_DIR"
rm -rf "${OUTPUT_DIR:?}/"*

# ---------------------------
# Download 1C Data (NASA PPS)
# ---------------------------

# 1C files pattern: V.<DATE>-S*
EXISTING_1C=$(ls "$DEST_1C_DIR"/*V.${DATE}-S* 2>/dev/null || true)

if [ -n "$EXISTING_1C" ]; then
  echo "1C files for $DATEHOUR are already present. Skipping downloads."
else 
  rm -rf "$DEST_1C_DIR"/*
  echo "Downloading 1C data from NASA PPS for $DATEHOUR..."

  # List all files
  FILE_LIST=$(curl -4 --ftp-ssl \
    --user "$PPS_USERNAME:$PPS_USERNAME" \
    --fail --retry 5 --retry-delay 15 --retry-connrefused \
    "$PPS_URL" 2>/dev/null)

  if [ -z "$FILE_LIST" ]; then
    echo "ERROR: Could not retrieve file list from PPS."
    exit 1
  fi

  # FILES_TO_DOWNLOAD=$(awk '{print $NF}' <<< "$FILE_LIST" | grep -E "V.${DATE}-S")
  if [ "$START_HOUR" -gt 16 ]; then
    FILES_TO_DOWNLOAD=$(awk '{print $NF}' <<< "$FILE_LIST" | grep -E "V\.(${DATE}|${YESTERDAY})-S")
  else
      FILES_TO_DOWNLOAD=$(awk '{print $NF}' <<< "$FILE_LIST" | grep -E "V\.${DATE}-S")
  fi
  
  for file in $FILES_TO_DOWNLOAD; do
    curl -4 --ftp-ssl \
      --user "$PPS_USERNAME:$PPS_USERNAME" \
      --max-time 1800 --fail --retry 5 --retry-delay 15 --retry-connrefused \
      --continue-at - "${PPS_URL}${file}" \
      -o "$DEST_1C_DIR/$file"
  done
  echo "PPS (NASA) 1C downloads complete."
fi 

# ---------------------------
# Download 1B Data (G-Portal)
# ---------------------------

# 1B files pattern: GW1AM2_<DATE>*.h5
mkdir -p "$DEST_1B_DIR"
cd "$DEST_1B_DIR" || exit 1
EXISTING_1B=$(ls "$DEST_1B_DIR"/GW1AM2_${DATE}*.h5 2>/dev/null || true)
            
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
cd /nrt/GCOM-W/GCOM-W.AMSR2/L1B/global
mget GW1AM2_${DATE}*.h5
$( [ "$START_HOUR" -gt 16 ] && echo "mget GW1AM2_${YESTERDAY}*.h5" )
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

cd "$BASE_DIR"

