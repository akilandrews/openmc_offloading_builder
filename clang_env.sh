#!/bin/bash

# GCC
module load gcc/13.3.1
export GCC=$(which gcc)
export GCC_DIR=${GCC%/bin/gcc}

# ROCm
module load rocm/6.4.0

# LLVM (installed)
root_dir=$(pwd)
clang_dir=$(readlink -f "$root_dir/../local/clang")
export PATH=$clang_dir/bin:$GCC_DIR/bin:$PATH
add_lib_paths=$clang_dir/lib:$clang_dir/lib/x86_64-unknown-linux-gnu:$clang_dir/lib/amdgcn-amd-amdhsa:$clang_dir/lib64:$GCC_DIR/lib/gcc/x86_64-redhat-linux/12:$GCC_DIR/lib64
export LIBRARY_PATH=$add_lib_paths:$LIBRARY_PATH
export LD_LIBRARY_PATH=$add_lib_paths:$LD_LIBRARY_PATH
export LLVM_DIR=$(readlink -f "$root_dir/../llvm-build")

# Features runtime
export LIBOMPTARGET_INFO=$((0x1 | 0x10)) 
