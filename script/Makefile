# =============================================================================
# AMSR2 Data Processing Pipeline Makefile
# =============================================================================
# Orchestrates the full AMSR2 processing workflow from raw satellite
# data download to final product generation and optional publication.
#
# WORKFLOW STAGES:
#   1. download   -> Fetch AMSR2 1B/1C satellite data
#   2. process    -> Run GSX + PMESDR gridding pipeline
#   3. geotiff    -> Convert processed grids into GeoTIFF products
#   4. collect    -> Organize and move output products
#   5. clean      -> Remove intermediate files to save disk space
#   6. post       -> Upload final GeoTIFF products to external server
#
# TARGETS:
#   make all      -> Runs full pipeline EXCEPT posting (safe local run)
#   make full     -> Runs everything including post/upload step
#
# DATE INPUT:
#   DATEHOUR format: YYYYMMDDHH
#
#   Example:
#     make all DATEHOUR=2026041312
#
#   Default behavior:
#     Automatically selects:
#       - current hour
#       - OR previous day 24-hour cycle if before 05 UTC
#
# NOTES:
#   - Requires conda environment activated inside scripts (not Makefile)
#   - All paths and credentials should be defined in config.sh
# =============================================================================

SHELL := /bin/bash

.PHONY: all full download process geotiff collect clean post

# ----------------------------
# Date and Hour Calculation
# ----------------------------

ifndef DATEHOUR
DATEHOUR := $(shell \
    h=$$(date +%H); \
    if [ $$h -lt 5 ]; then \
        date -d "yesterday" +%Y%m%d24; \
    else \
        date +%Y%m%d%H; \
    fi)
endif

# ----------------------------
# Core pipeline (NO POST)
# ----------------------------

all: download process geotiff collect #clean

download:
	@echo "Downloading AMSR2 data for $(DATEHOUR)..."
	./download_data.sh $(DATEHOUR)

process:
	@echo "Processing data..."
	./process_data.sh $(DATEHOUR)

geotiff:
	@echo "Converting processed files to GeoTIFFs..."
	./make_geotiff.sh $(DATEHOUR)

collect:
	@echo "Collecting/moving output files..."
	./collect_output.sh $(DATEHOUR)

clean:
	@echo "Cleaning up intermediate files..."
	./clean_data.sh $(DATEHOUR)

# ----------------------------
# FULL pipeline INCLUDING POST
# ----------------------------

full: all post

post:
	@echo "Transferring GeoTiffs to SSEC ftp server for 3.125km data"
	./post_data.sh $(DATEHOUR)