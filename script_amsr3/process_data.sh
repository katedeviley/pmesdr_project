#!/bin/bash
# =============================================================================
# Script: process_data.sh
# Description: Process AMSR3 input files into gridded outputs using GSX & PMESDR.
# Usage: ./process_data.sh YYYYMMDDHH
# =============================================================================
set -e  # Exit on error
source ./config.sh
source "$CONDA_SH"
conda activate "$CONDA_ENV"

# ----------------------------
# Argument Parsing
# ----------------------------

if [ $# -eq 1 ]; then
    DATEHOUR="$1"
    DATE="${DATEHOUR:0:8}"
    START_HOUR="${DATEHOUR:8:2}"
else
    echo "Usage: $0 YYYYMMDDHH"
    exit 1
fi

# ----------------------------
# Configuration
# ----------------------------

INPUT_DIR_1B="$DATA_DIR/$DATE/S$START_HOUR/input/"
INPUT_DIR_1C="$DATA_DIR/$DATE/S$START_HOUR/input/1C"
OUTPUT_DIR="$DATA_DIR/$DATE/S$START_HOUR/output/"

GSX_DIR="$OUTPUT_DIR/gsx/"
META_DIR="$OUTPUT_DIR/meta"
SETUP_DIR="$OUTPUT_DIR/setup"

rm -rf "$OUTPUT_DIR"
mkdir -p "$GSX_DIR" "$META_DIR" "$SETUP_DIR" "$OUTPUT_DIR"

START_DATE=$(date -d "$DATE" +%j)
YEAR=$(date -d "$DATE" +%Y)

GROUP_NAMES=(
  "N"
  "S"
)

REGION_FILES=(
  "${REF_DIR}/E2N_amsr3.def"
  "${REF_DIR}/E2S_amsr3.def"
) # adjust region if needed

THRESHOLDS=(
  -8 -8
)

BOX_SIZES=(
  250 250
)

# ----------------------------
# Main Processing Steps
# ----------------------------

# Step 1: Generate GSX from 1B
echo "Generating GSX files from ${INPUT_DIR_1B}"
for f in "$INPUT_DIR_1B"/*; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    base=${base%.*}

    out="$GSX_DIR/${base}.nc"
    "$GSX" AMSR3 "$f" "$out"
done

GSX_LIST="$META_DIR/gsx_list.txt"
find "$GSX_DIR" -name '*.nc' > "$GSX_LIST"

# Step 2: Generate file.meta and .setup files in parallel for multiple regions
echo "Generating file.meta and .setup files for all regions..."
for i in "${!GROUP_NAMES[@]}"; do
(
    GROUP="${GROUP_NAMES[$i]}"
    REGION="${REGION_FILES[$i]}"
    THRESHOLD="${THRESHOLDS[$i]}"
    BOX_SIZE="${BOX_SIZES[$i]}"

    REGION_NAME=$(basename "$REGION" .def)

    echo "Processing group: $GROUP"

    "$MEAS_META_MAKE" -t -8 -r 0 \
      "$META_DIR/file_${GROUP}.meta" GOSATGW \
      "$START_DATE" "$START_DATE" "$YEAR" \
      "$REGION" "$GSX_LIST"

     "$MEAS_META_SETUP" -b 80 \
        "$META_DIR/file_${GROUP}.meta" "$SETUP_DIR"
) &
done
wait

# Step 3: Process .setup files
echo "Processing .setup files with meas_meta_sir..."
for setup in "$SETUP_DIR"/*.setup; do
    [ -e "$setup" ] || continue
    "$MEAS_META_SIR" "$setup" "$OUTPUT_DIR"
done

echo "Processing complete for DATEHOUR=$DATEHOUR"