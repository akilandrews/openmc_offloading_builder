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
fi

# Build OpenMC Monte Carlo
if [[ "$1" == "compile" ]]; then
    source clang_env.sh
    root_dir="$(pwd)"
    source ${root_dir}/hdf5/env.sh
    export HDF5_ROOT=${root_dir}/install114/ci-StdShar-Clang
    OPENMC_TARGET=llvm_pp4ogpc

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
    -Dprofile=on"
    # -DCMAKE_BUILD_TYPE=RelWithDebInfo

    # Check if OPENMC_CXX_FLAGS is set and not empty
    if [ ! -z "${OPENMC_CXX_FLAGS}" ]; then
        # Append CXX flags to the cmake command
        echo -e "\033[31mWARNING: OPENMC_CXX_FLAGS has been set. This"          \
            "overwrites CMakePresets.json commands for ${OPENMC_TARGET}, so you"\
            " will need to manually include them in your redefinition.\033[0m "
        cmake_cmd+=" -DCMAKE_CXX_FLAGS=\"${OPENMC_CXX_FLAGS}\""
    fi

    # Check if OPENMC_LD_FLAGS is set and not empty
    if [ ! -z "${OPENMC_LD_FLAGS}" ]; then
        # Append linker flags to the cmake command
        echo -e "\033[31mWARNING: OPENMC_LD_FLAGS has been set. This overwrites"\
            " CMakePresets.json commands for ${OPENMC_TARGET}, so you will need"\
            " to manually include them in your redefinition.\033[0m "
        cmake_cmd+=" -DCMAKE_EXE_LINKER_FLAGS=\"${OPENMC_LD_FLAGS}\""
        cmake_cmd+=" -DCMAKE_MODULE_LINKER_FLAGS=\"${OPENMC_LD_FLAGS}\""
    fi

    # Finally, run the cmake command with optionally added flags
    eval $cmake_cmd ..

    # Compile and install
    make VERBOSE=1
    make install
fi
