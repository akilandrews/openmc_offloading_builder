#!/bin/bash

# Clone OpenMC source, benchmarks repository, OpenMC's cross section data files
if [[ "$1" == "download" ]]; then
    if [[ ! -d "openmc" ]]; then  
        git clone --recursive git@github.com:akilandrews/openmc.git
        cd openmc
        git checkout pp4ogpc
        cd ..
    fi

    if [[ ! -d "openmc_offloading_benchmarks" ]]; then  
        git clone https://github.com/jtramm/openmc_offloading_benchmarks.git
    fi

    if [[ ! -d "nndc_hdf5" ]]; then  
        wget https://anl.box.com/shared/static/vht6ub1q27hujkqpz1k0s48lrv44op0v.tgz
        tar -xzvf vht6ub1q27hujkqpz1k0s48lrv44op0v.tgz
        rm vht6ub1q27hujkqpz1k0s48lrv44op0v.tgz
    fi

    if [[ ! -d "hdf5" ]]; then
        git clone git@github.com:akilandrews/hdf5.git
        cd hdf5
        git checkout pp4ogpc
        cd ..
    fi
fi

# Build OpenMC Monte Carlo
if [[ "$1" == "compile" ]]; then
    source $HOME/config/clang20_gfx906_env.sh
    root_dir="$(pwd)"
    source ${root_dir}/hdf5/env.sh
    export HDF5_ROOT=${root_dir}/install/ci-StdShar-Clang
    OPENMC_TARGET=llvm_pp4ogpc
    export EXTRA_CFLAGS="--config=$root_dir/openmc/amdgcn-amd-amdhsa.cfg"

    # Create directories and delete old build/install
    echo "build dir:   ./build"
    echo "install dir: ./install"
    cd openmc
    rm -rf build install
    mkdir build install
    cd build

    # Initialize the base cmake command
    cmake_cmd="cmake                                                            \
    --preset=${OPENMC_TARGET}                                                   \
    -DCMAKE_INSTALL_PREFIX=../install                                           \
    -DCMAKE_CXX_STANDARD=17                                                     \
    -DCMAKE_CXX_STANDARD_REQUIRED=ON                                            \
    -DCMAKE_CXX_EXTENSIONS=OFF                                                  \
    -Dprofile=on                                                                \
    -Doptimize=on"
    # -DCMAKE_BUILD_TYPE=RelWithDebInfo

    # Finally, run the cmake command with optionally added flags
    eval $cmake_cmd ..

    # Compile and install
    compile_results_file="$root_dir/openmc_offloading_benchmarks"
    compile_results_file+="/progression_tests/small/compile_results.txt"
    make VERBOSE=1 > $compile_results_file 2>&1
    make install

    # Copy compile results to medium and large simulation folders
    cp $compile_results_file $root_dir/openmc_offloading_benchmarks/progression_tests/medium
    cp $compile_results_file $root_dir/openmc_offloading_benchmarks/progression_tests/large
    cd $root_dir
fi
