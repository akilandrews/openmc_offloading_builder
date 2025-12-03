#!/usr/bin/env bash

openmc_dir=$(readlink -f "${BASH_SOURCE[0]}")
export HDF5_ROOT=${openmc_dir}/install/ci-StdShar-Clang
export LD_LIBRARY_PATH=${openmc_dir}/openmc/install/lib64:$LD_LIBRARY_PATH
export PATH=${openmc_dir}/openmc/install/bin:$PATH
export OPENMC_CROSS_SECTIONS=${openmc_dir}/nndc_hdf5/cross_sections.xml
export OMP_TARGET_OFFLOAD=MANDATORY
