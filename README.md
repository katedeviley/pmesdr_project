# AMSR2 Processing Pipeline

## Submodules

This project is built on the `pmesdr` library:

- Original repo: https://github.com/nsidc/pmesdr

- Fork used here: https://github.com/katedeviley/pmesdr

## Data Directory Structure

All data is organized by date and processing window:

    DATA_DIR/
    └── YYYYMMDD/
        └── SHH/
            ├── input/
            │   ├── 1B/   (JAXA Level 1B)
            │   └── 1C/   (NASA PPS Level 1C)
            └── output/

Example:

    DATA_DIR/20240101/S06/input/1B

## Pipeline Overview

### 1. Time Window Initialization

- Input is provided as `YYYYMMDDHH`
- The system derives:
    - processing date (`DATE`)
    - time window (`START_HOUR`)
    - previous day (`YESTERDAY`) when needed
- Data is organized into 6-hour slots

### 1. Data Acquisition

For each time window, the pipeline downloads:
- Level 1B (JAXA G-Portal)
    - AMSR2 / AMSR3 raw swath data
- Level 1C (NASA PPS)
    - calibrated / processed swath products

Key features:
- Skips download if files already exist locally
- Automatically retries failed transfers (SFTP / FTP)
- Includes optional previous-day retrieval for late orbits (`START_HOUR > 16`)

Organizes inputs into:

    input/1B
    input/1C

### 2. Processing (PMESDR-based)

Using the PMESDR framework:
- Geolocation correction
- Scan-to-grid transformation
- Orbit stitching and alignment
- Time filtering within the selected window

### 3. Output Generation

Final products are written to:

    output/

Includes:
- NetCDF intermediate products
- Derived geophysical fields
- GeoTIFF conversion (via make_geotiff.sh)

### 4. Post-Processing

- Final processed products are moved to a designated final output directory for storage.
- Intermediate processing files (temporary NetCDF, staging files, and raw intermediates) are removed after processing.
- Outputs are marked as ready for distribution and can be posted to SSEC for downstream use.

## Configuration

The pipeline is controlled via a central configuration file:

    config.sh

This file defines:
- Directory structure (`DATA_DIR`, `BASE_DIR`).
- External data access credentials (NASA PPS / JAXA G-Portal).
- Runtime parameters used across all scripts.

# How to Run the Pipeline

This project is controlled through a Makefile, which orchestrates all processing steps.

If no `DATEHOUR` is provided, the Makefile automatically selects:

- current hour, or
- previous day 24Z if early morning processing

### Run all Pipeline (Download → Process → GeoTIFF → Collect → Clean)

    make all DATEHOUR=YYYYMMDDHH

### Run Full Pipeline (Download → Process → GeoTIFF → Collect → Clean → Post)

    make full DATEHOUR=YYYYMMDDHH

### Run Individual Steps

Download data:

    make download DATEHOUR=YYYYMMDDHH

Process data:

    make process DATEHOUR=YYYYMMDDHH

Generate GeoTIFF outputs:

    make geotiff DATEHOUR=YYYYMMDDHH

Collect outputs:

    make collect DATEHOUR=YYYYMMDDHH

Post to SSEC:

    make post DATEHOUR=YYYYMMDDHH

## Automation

This pipeline is designed to run automatically using `cron`.

Example cron entry:

```Bash
# Run pipeline at 2,8,14,20
0 2,8,14,20 * * * cd /path/to/project && make full >> logs/pipeline.log 2>&1
```

# Adding AMSR3

If you are adding a new sensor or data producer (e.g., AMSR3, GCOM-W2, or any future microwave instrument), follow the instructions in:

    add_sensor_producer/new_sensor_producer_instructions.md

### AMSR3 Integration Note 

For AMSR3, if this repository was cloned from:

    https://github.com/katedeviley/pmesdr

then **skip Steps 1–6** in the sensor integration guide and begin at Step 7. These steps are already implemented in the base PMESDR framework.