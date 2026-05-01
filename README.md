# AMSR2 Processing Pipeline

## Submodules

This project is built on the `pmesdr` library:

- Original repo: [nsidc/pmesdr](https://github.com/nsidc/pmesdr)

- Fork used here: [katedeviley/pmesdr](https://github.com/katedeviley/pmesdr)

## Installation 

Install the pipeline by cloning the repo. To ensure all dependencies are downloaded in one step, use the --recurse-submodules flag:

``` bash
git clone --recurse-submodules https://github.com/katedeviley/pmesdr_project.git
```

If you previously cloned without the recursive flag, or if the pmesdr folder appears empty, run:
```bash
git submodule update --init --recursive
```

Once the submodules are initialized, follow the specific build and environment instructions found in the installation section of [pmesdr/README.md](./pmesdr/README.md).

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

### 2. Data Acquisition

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

### 3. Processing (PMESDR-based)

Using the PMESDR framework:
- Geolocation correction
- Scan-to-grid transformation
- Orbit stitching and alignment
- Time filtering within the selected window

### 4. Output Generation

Final products are written to:

    output/

Includes:
- NetCDF intermediate products
- Derived geophysical fields
- GeoTIFF conversion (via make_geotiff.sh)

### 5. Post-Processing

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

- Download: `make download DATEHOUR=YYYYMMDDHH`
- Process: `make process DATEHOUR=YYYYMMDDHH`
- GeoTIFF: `make geotiff DATEHOUR=YYYYMMDDHH`
- Cleanup: `make clean DATEHOUR=YYYYMMDDHH`

## Automation

This pipeline is designed to run automatically using `cron`.

Example cron entry:

```Bash
# Run pipeline at 2,8,14,20
0 2,8,14,20 * * * cd /path/to/project && make full >> logs/pipeline.log 2>&1
```

# Adding AMSR3

To add a new sensor or data producer (e.g., GCOM-W2 or future microwave instruments), follow the detailed guide in:
[add_sensor_producer/new_sensor_producer_instructions.md](./add_sensor_producer/new_sensor_producer_instructions.md)

### AMSR3 Integration Note 

If you are using the `katedeviley/pmesdr` fork, **skip Steps 1–6** of the integration guide. The core channel mapping and 89 GHz combination logic are already implemented in this framework; you can begin at **Step 7**.