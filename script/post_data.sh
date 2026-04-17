#!/bin/bash
# =============================================================================
# Script: post_data.sh
# Upload GeoTIFF files to SSEC FTP
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

OUTPUT_DIR="$DATA_DIR/$DATE/S$START_HOUR/output/geotiff"

#---------------------------
# Upload files
# ---------------------------

for f in "$OUTPUT_DIR"/*.tif; do
    echo "Uploading $f"
    curl -T "$f" \
        "ftp://ftp.ssec.wisc.edu/pub/GCOMW1_AMSR2/" \
        --user anonymous:kdeviley@ssec.wisc.edu
done