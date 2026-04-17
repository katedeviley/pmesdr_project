#!/bin/bash
# =============================================================================
# Script: clean_data.sh
# Description: Cleans up intermediate files from the processing pipeline for a given date and hour. This is typically called by the Makefile after processing is complete.
# Usage: ./clean_data.sh [YYYYMMDDHH]
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

rm -rf $DATA_DIR/$DATE/S$START_HOUR/output/gsx \
	$DATA_DIR/$DATE/S$START_HOUR/output/meta \
	$DATA_DIR/$DATE/S$START_HOUR/output/setup \
  $DATA_DIR/$DATE/S$START_HOUR/input \