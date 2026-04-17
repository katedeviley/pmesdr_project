#!/bin/bash
#


# Load necessary modules to run gdal
module purge
module load gcc/11.2 hdf/4.2.15 hdf5/1.12.2 netcdf4/4.8.1 gdal/3.12.1
  
# Create GeoTiffs from NetCDF files 
fname=NSIDC0630_SIR_EASE2_N3.125km_GCOMW1_AMSR2_M_36H_20260106_2601090539_v2.0.nc
path_out=/data/kdeviley/
gdal_translate -of GTiff -b 1 NETCDF:"$path_out$fname":TB $path_out${fname::-2}tif  

# Transfer GeoTiffs to SSEC ftp server for 3.125km data only      
curl -T $path_out${fname::-2}tif ftp://ftp.ssec.wisc.edu/pub/GCOMW1_AMSR2/ --user anonymous:tomg@ssec.wisc.edu      
