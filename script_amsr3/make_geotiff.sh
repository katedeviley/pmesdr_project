#!/bin/bash
# =============================================================================
# Script Name: make_geotiff.sh
# Description: Convert AMSR3 NetCDF files (.nc) to GeoTIFF format (.tif)
# Usage: ./make_geotiff.sh YYYYMMDDHH
# =============================================================================
set -e # Exit on error
source ./config.sh

# ---------------------------
# Argument Parsing
# ---------------------------

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

OUTPUT_DIR="$DATA_DIR/$DATE/S$START_HOUR/output"
mkdir -p "$OUTPUT_DIR/geotiff"

# ------------------------------
# Convert .nc to GeoTIFF
# ------------------------------

# Load GDAL if needed
module purge
module load gcc/11.2 hdf/4.2.15 hdf5/1.12.2 netcdf4/4.8.1 gdal/3.12.1

MAX_ATTEMPTS=3

for ncfile in "$OUTPUT_DIR"/*.nc; do
    [ -e "$ncfile" ] || continue
    tiffile="$OUTPUT_DIR/$(basename "${ncfile%.nc}.tif")"
    echo "Converting $(basename "$ncfile") → $(basename "$tiffile")"

    ATTEMPT=1
    SUCCESS=false

    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        if gdal_translate -of GTiff -b 1 NETCDF:"$ncfile":TB "$tiffile"; then
            SUCCESS=true
            break
        fi

        echo "  Attempt $ATTEMPT failed. Retrying..."
        ATTEMPT=$((ATTEMPT + 1))
        sleep 2
    done

    if [ "$SUCCESS" = false ]; then
        echo "ERROR: Failed to convert $(basename "$ncfile") after $MAX_ATTEMPTS attempts."
        exit 1
    fi
done

mv "$OUTPUT_DIR"/*.tif "$OUTPUT_DIR/geotiff/"
echo "GeoTIFF generation complete."