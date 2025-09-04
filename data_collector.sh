#!/bin/bash
# Copyright (c) 2025 Lawrence Livermore National Security, LLC and other
# pp4ogpc project developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: MIT

set -e

parameters="<clean|clean-keep|run-baseline|run-variants|get-features>"
if [[ -z "$1" ]]
then
  echo "Usage: $0 $parameters"
  exit 1
else
  export wf_type=$1
fi

# Directories for build and installation (*Note customize to your file system)
root_dir="$(pwd)"
export helpers_dir=$(readlink -f "$HOME/pp4ogpc/helpers")
export rocprof_input="$HOME/pp4ogpc/config/rocprof-input-gfx90a.txt" # Features runtime
jobs_dir=$(readlink -f "$HOME/workspace/jobs")
source $root_dir/clang_env.sh
source $root_dir/env.sh
project_dir=$root_dir/openmc_offloading_benchmarks/progression_tests/small
project="openmc"
results_dir=$project_dir/results

# Number of samples to collect (*Note minimum 2)
num_runs=3 # 100
num_sizes=$num_runs
if [[ $num_sizes -lt 16 ]]; then num_sizes=16; fi
run_cmd="openmc --event $project_dir"

# Begin workflow type
echo "--INFO-- Begin workflow $wf_type"
msg=""
start_time=$(date '+%s')

if [[ $wf_type == "clean" ]] || [[ $wf_type == "clean-keep" ]]; then
  echo "--INFO-- Remove prior results (may contain core dumps)"
  rm -f flux-*.out ${jobs_dir}/run-*.out ${jobs_dir}/get-*.out
  if [[ $wf_type == "clean-keep" ]]; then #TODO remove
    find ${project_dir}/results -maxdepth 1 -name "run*" | grep -v "run0"       \
    | xargs --no-run-if-empty rm -rf
  elif [[ $wf_type == "clean" ]]; then
    find ${project_dir} -maxdepth 1 -type d -name 'results'                     \
      | xargs --no-run-if-empty rm -rf
  fi
  msg="--INFO-- Completed clean"
elif [[ $wf_type == "run-baseline" ]] || [[ $wf_type == "run-variants" ]]  ||   \
  [[ $wf_type == "get-features" ]]; then

  # Generate job arguments for run baselines and get features, run variants
  case $wf_type in

    "run-baseline")
      mkdir -p ${results_dir}
      cp $project_dir/compile_results.txt ${results_dir}
      flux submit -n 1 -c 1 -g 1 --quiet --flags=waitable -o mpibind=off        \
        -o cpu-affinity=per-task -o gpu-affinity=per-task                       \
        --output=$jobs_dir/$wf_type-{{id}}.out                                  \
        $helpers_dir/run_benchmark.sh "$results_dir 0 $project 0 0 $run_cmd"
      flux job wait --all
      ;;

    "run-variants")
      tripcount=$(python3 $helpers_dir/get_tripcount.py                         \
          -f "$results_dir/run0/run_results.txt")
      block_sizes=($(python3 $helpers_dir/get_block_sizes.py -n $num_sizes))
      for (( index=1; index<num_runs; index++ )); do
          block_size=${block_sizes[$((index - 1))]}
          flux submit -n 1 -c 1 -g 1 --quiet --flags=waitable -o mpibind=off    \
            -o cpu-affinity=per-task -o gpu-affinity=per-task                   \
            --output=$jobs_dir/$wf_type-{{id}}.out                              \
            $helpers_dir/run_benchmark.sh                                       \
            "$results_dir $index $project $tripcount $block_size $run_cmd"
          flux job wait --all
      done
      ;;

    "get-features")
      python3 $helpers_dir/get_features.py -d $results_dir -n $num_runs
      ;;

    *)
      echo "--ERROR-- Usage: $0 $parameters"
      ;;

  esac
  msg="--INFO-- Completed $project submission jobs $wf_type"
fi

# Display total execution time
end_time=$(date '+%s')
total_time=$(bc -l <<< "($end_time - $start_time) / 60")
printf "%s in %.2f mins\n" "$msg" "$total_time"
 