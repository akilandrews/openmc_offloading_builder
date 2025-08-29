#!/bin/bash

set -e

root_dir="$(pwd)"
source $root_dir/spack_env.sh
source $root_dir/clang_env.sh #TODO remove

# Directories - customize to your development environment
llvm_install_dir=$(readlink -f "$root_dir/../")
prefix=$llvm_install_dir/local/clang
build_dir=$llvm_install_dir/llvm-build
export LLVM_PROJECT=$llvm_install_dir/llvm-project
export LLVM_SRC=${LLVM_PROJECT}/llvm
echo "--INFO-- LLVM project directory ${LLVM_PROJECT}"

# Create directories
mkdir -p ${prefix} && mkdir -p ${build_dir}
echo "--INFO-- Install directory $prefix"
echo "--INFO-- Build directory $build_dir"

# CMake configuration and generation
projects="clang;clang-tools-extra;compiler-rt;lld"
runtimes="libc;openmp;offload;libunwind"
cmake_options="                                                                 \
        -DBUILD_SHARED_LIBS=ON                                                  \
        -DCLANG_DEFAULT_LINKER=lld                                              \
        -DCMAKE_INSTALL_PREFIX=${prefix}                                        \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo                                           \
        -DCMAKE_C_COMPILER_LAUNCHER=/usr/bin/ccache                             \
        -DCMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache                           \
        -DLIBOMPTARGET_ENABLE_DEBUG=ON                                          \
        -DLIBOMPTARGET_DEVICE_ARCHITECTURES=gfx90a                              \
        -DLLVM_APPEND_VC_REV=OFF                                                \
        -DLLVM_CCACHE_BUILD=ON                                                  \
    -DLLVM_CCACHE_DIR=$llvm_install_dir/cache                                   \
        -DLLVM_ENABLE_ASSERTIONS=ON                                             \
        -DLLVM_ENABLE_PROJECTS=${projects}                                      \
        -DLLVM_ENABLE_RUNTIMES=${runtimes}                                      \
        -DLLVM_OPTIMIZED_TABLEGEN=ON                                            \
    -DLLVM_RUNTIME_TARGETS=default;amdgcn-amd-amdhsa                            \
    -DLLVM_TARGETS_TO_BUILD=X86;AMDGPU                                          \
        -DLLVM_USE_LINKER=lld                                                   \
    -DRUNTIMES_amdgcn-amd-amdhsa_LLVM_ENABLE_RUNTIMES=libc"
    # -DLIBOMPTARGET_DEVICE_ARCHITECTURES=gfx906
pushd ${build_dir}
cmake -G "Ninja" ${cmake_options} -S ${LLVM_SRC} -B ${build_dir}

# Ninja build and install
ninja
ninja install

# Post instructions
echo Installation Complete. Add the following to your environment.
echo export PATH=${prefix}/bin:'$PATH'
echo export LIBRARY_PATH=${prefix}/lib:'$LIBRARY_PATH'
echo export LD_LIBRARY_PATH=${prefix}/lib:'$LD_LIBRARY_PATH'
