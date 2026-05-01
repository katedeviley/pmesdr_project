#!/bin/bash
# =============================================================================
# Script: process_data.sh
# Description: Process AMSR2 input files into gridded outputs using GSX & PMESDR.
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
# Temp Local Directories
# ----------------------------

INPUT_DIR_1C="$DATA_DIR/$DATE/S$START_HOUR/input/1C"
INPUT_DIR_1B="$DATA_DIR/$DATE/S$START_HOUR/input/1B"
OUTPUT_DIR="$DATA_DIR/$DATE/S$START_HOUR/output/"

GSX_DIR="$OUTPUT_DIR/gsx"
GSX_DIR_1C="$GSX_DIR/gsx_1C"
GSX_DIR_1B="$GSX_DIR/gsx_1B"
COMBINED_DIR="$GSX_DIR/gsx_combined"

META_DIR="$OUTPUT_DIR/meta"
SETUP_DIR="$OUTPUT_DIR/setup"

rm -rf "$OUTPUT_DIR"
mkdir -p "$GSX_DIR_1C" "$GSX_DIR_1B" "$COMBINED_DIR" "$META_DIR" "$SETUP_DIR"

START_DATE=$(date -d "$DATE" +%j)
YEAR=$(date -d "$DATE" +%Y)

GROUP_NAMES=(
  "N_6_10GHz"
  "N_18GHz"
  "N_23GHz"
  "N_36GHz"
  "N_89GHz"
  "S_6_10GHz"
  "S_18GHz"
  "S_23GHz"
  "S_36GHz"
  "S_89GHz"
)

REGION_FILES=(
  "${REF_DIR}/E2N_AMSR_6_10GHz.def"
  "${REF_DIR}/E2N_AMSR_18GHz.def"
  "${REF_DIR}/E2N_AMSR_23GHz.def"
  "${REF_DIR}/E2N_AMSR_36GHz.def"
  "${REF_DIR}/E2N_AMSR_89GHz.def"

  "${REF_DIR}/E2S_AMSR_6_10GHz.def"
  "${REF_DIR}/E2S_AMSR_18GHz.def"
  "${REF_DIR}/E2S_AMSR_23GHz.def"
  "${REF_DIR}/E2S_AMSR_36GHz.def"
  "${REF_DIR}/E2S_AMSR_89GHz.def"
) # adjust region if needed

THRESHOLDS=(
  -8 -8 -8 -8 -16
  -8 -8 -8 -8 -16
)

BOX_SIZES=(
  20 22 26 24 20
  20 22 26 24 20
)

# ----------------------------
# Main Processing Steps
# ----------------------------

# Step 1: Generate GSX from 1C
echo "Generating GSX files from 1C..."
for f in "$INPUT_DIR_1C"/*; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    base=${base%.*}

    out="$GSX_DIR_1C/L${base}.nc.partial"
    "$GSX" AMSR-L1C "$f" "$out"
done

# Step 2: Generate GSX from 1B
echo "Generating GSX files from 1B..."
for f in "$INPUT_DIR_1B"/*; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    base=${base%.*}

    out="$GSX_DIR_1B/${base}.nc.partial"
    "$GSX" AMSR-JAXA "$f" "$out"
done

# Step 3: Combine 1C & 1B GSX
echo "Combining GSX files..."
for f in "$GSX_DIR_1C"/*.nc.partial; do
    [ -e "$f" ] || continue
    combine_amsr_l1c_jaxa AMSR2 "$f" "$GSX_DIR_1B" "$COMBINED_DIR"
done

GSX_LIST="$META_DIR/gsx_list.txt"
find "$COMBINED_DIR" -name '*.nc' > "$GSX_LIST"

# Step 4 & 5: Generate file.meta and .setup files in parallel for multiple regions
echo "Generating file.meta and .setup files for all regions..."
for i in "${!GROUP_NAMES[@]}"; do
(
    GROUP="${GROUP_NAMES[$i]}"
    REGION="${REGION_FILES[$i]}"
    THRESHOLD="${THRESHOLDS[$i]}"
    BOX_SIZE="${BOX_SIZES[$i]}"

    REGION_NAME=$(basename "$REGION" .def)

    echo "Processing group: $GROUP"

    "$MEAS_META_MAKE" -t $THRESHOLD -r 0 \
      "$META_DIR/file_${GROUP}.meta" GCOMW1 \
      "$START_DATE" "$START_DATE" "$YEAR" \
      "$REGION" "$GSX_LIST"

     "$MEAS_META_SETUP" -b "$BOX_SIZE" \
        "$META_DIR/file_${GROUP}.meta" "$SETUP_DIR"
) &
done
wait

# Step 6: Process .setup files
echo "Processing .setup files with meas_meta_sir..."
for setup in "$SETUP_DIR"/*.setup; do
    [ -e "$setup" ] || continue
    "$MEAS_META_SIR" "$setup" "$OUTPUT_DIR"
done

echo "Processing complete for DATEHOUR=$DATEHOUR"