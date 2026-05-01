#!/bin/bash
# =============================================================================
# PMESDR / AMSR3 Processing Pipeline Configuration
# =============================================================================
# Central configuration file for the AMSR3 processing pipeline.
# Defines environment variables used across:
#     - download scripts (JAXA G-Portal)
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
if [ -f "../my_config.sh" ]; then
  source ../my_config.sh
fi

# ============================= CONDA ENVIRONMENT =============================
export CONDA_ENV="pmesdrEnv"
export CONDA_SH="${HOME}/miniconda3/etc/profile.d/conda.sh"

# ============================ DIRECTORY STRUCTURE ============================
# BASE_DIR:
#   Root directory 
#   Example structure:
#   /BASE_DIR/
#       ├── PMESDR_TOP_DIR/
#       ├── REF_DIR/
#       ├── DATA_DIR/
#       └── script_amsr3/
export BASE_DIR="${HOME}/pmesdr_project"

# PMESDR_TOP_DIR:
#   Root directory of PMESDR source code
export PMESDR_TOP_DIR="${BASE_DIR}/pmesdr"

# REF_DIR:
#   Directory of Region definition files
export REF_DIR="${BASE_DIR}/ref"

# DATA_DIR:
#   Root directory for all data products (input/output)
#   /DATA_DIR/
#   └── YYYYMMDD/
#       └── SHH/
#           ├── input/  
#           └── output/
export DATA_DIR="${BASE_DIR}/data_amsr3"

# SCRIPT_DIR:
export SCRIPT_DIR="${BASE_DIR}/script_amsr3"

# ============================= OUTPUT DIRECTORY ==============================
export FINAL_OUTPUT_DIR="${MY_FINAL_OUTPUT_DIR}"  # change to your final output dir

# ============================= EXECUTABLE PATHS ==============================
export GSX="${HOME}/miniconda3/envs/${CONDA_ENV}/bin/gsx"
export MEAS_META_MAKE="${PMESDR_TOP_DIR}/src/prod/meas_meta_make/meas_meta_make"
export MEAS_META_SETUP="${PMESDR_TOP_DIR}/src/prod/meas_meta_setup/meas_meta_setup"
export MEAS_META_SIR="${PMESDR_TOP_DIR}/src/prod/meas_meta_sir/meas_meta_sir"

# =============================== DATA SOURCES ================================
# JAXA G-Portal:
export GPORTAL_DATA_PATH="/nrt/GOSAT-GW/GOSAT-GW.AMSR3/L1B/global"
export GPORTAL_USERNAME="${MY_GPORTAL_USERNAME}"  # change to your username
export PRIVATE_KEY_PATH="${MY_PRIVATE_KEY_PATH}"  # change to your key path

# SSEC:  (for posting data)
export SSEC_URL="ftp://ftp.ssec.wisc.edu/pub/GOSATGW_AMSR3/"
export SSEC_USERNAME="${MY_SSEC_USERNAME}"        # change to your username