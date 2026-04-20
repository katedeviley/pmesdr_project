#!/bin/bash
# =============================================================================
# PMESDR / AMSR2 Processing Pipeline Configuration
# =============================================================================
# Central configuration file for the AMSR2 processing pipeline.
# Defines environment variables used across:
#     - download scripts (NASA PPS + JAXA G-Portal)
#     - GSX conversion step
#     - PMESDR gridding pipeline (meas_meta tools)
#     - Makefile execution workflow
#     - output generation and post-processing
#
# USAGE:
#   This file is sourced by all pipeline scripts:
#     source ./config.sh
#
# =============================================================================
source ../my_config.sh

# ============================= CONDA ENVIRONMENT =============================
export CONDA_ENV="pmesdrEnv"
export CONDA_SH="${HOME}/miniconda3/etc/profile.d/conda.sh"

# ============================ DIRECTORY STRUCTURE ============================
# BASE_DIR:
#   Root directory 
#   Example structure:
#   /BASE_DIR/
#       ├── DATA_DIR/
#       ├── PMESDR_TOP_DIR/
#       └── script/
export BASE_DIR="${HOME}/pmesdr_project"

# DATA_DIR:
#   Root directory for all data products (input/output)
#   /DATA_DIR/
#   └── YYYYMMDD/
#       └── SHH/
#           ├── input/  
#           └── output/
export DATA_DIR="${BASE_DIR}/data"

# PMESDR_TOP_DIR:
#   Root directory of PMESDR source code
export PMESDR_TOP_DIR="${BASE_DIR}/pmesdr"

# ============================= EXECUTABLE PATHS ==============================
export GSX="${HOME}/miniconda3/envs/${CONDA_ENV}/bin/gsx"
export MEAS_META_MAKE="${PMESDR_TOP_DIR}/src/prod/meas_meta_make/meas_meta_make"
export MEAS_META_SETUP="${PMESDR_TOP_DIR}/src/prod/meas_meta_setup/meas_meta_setup"
export MEAS_META_SIR="${PMESDR_TOP_DIR}/src/prod/meas_meta_sir/meas_meta_sir"

# =============================== DATA SOURCES ================================
# NASA PPS:
export PPS_URL="ftp://jsimpsonftps.pps.eosdis.nasa.gov/data/1C/AMSR2/"
export PPS_USERNAME="${MY_PPS_USERNAME}" # change to your username

# JAXA G-Portal:
export GPORTAL_USERNAME="${MY_GPORTAL_USERNAME}"  # change to your username
export PRIVATE_KEY_PATH="${MY_PRIVATE_KEY_PATH}"  # change to your path

# ============================== REFERENCE FILES ==============================
export REF_DIR="${BASE_DIR}/script/ref"

# ============================= OUTPUT DIRECTORY ==============================
export FINAL_OUTPUT_DIR="${FINAL_OUTPUT_DIR}" # change to your final output dir