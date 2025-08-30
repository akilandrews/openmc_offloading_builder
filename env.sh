#!/bin/bash  

root_dir=$(pwd)
export HDF5_ROOT=${root_dir}/install/ci-StdShar-Clang
export LD_LIBRARY_PATH=${root_dir}/openmc/install/lib64:$LD_LIBRARY_PATH
export PATH=${root_dir}/openmc/install/bin:$PATH
export OPENMC_CROSS_SECTIONS=${root_dir}/nndc_hdf5/cross_sections.xml
export OMP_TARGET_OFFLOAD=MANDATORY
