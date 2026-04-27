# =============================================================================
# Makefile for AMSR2 data processing pipeline
# =============================================================================
# Configuration
# ----------------------------

SHELL := /bin/bash

.PHONY: all full download process geotiff collect clean post

# ----------------------------
# Date and Hour Calculation
# ----------------------------

# user can override via: make DATEHOUR=YYYYMMDDHH
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
# Targets
# ----------------------------

all: download process geotiff collect #clean

download: 
	@echo "Downloading AMSR3 data for $(DATEHOUR)..."
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