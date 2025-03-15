#!/bin/bash

set -Eeuo pipefail

declare -A MOUNTS

MOUNTS["/root/.cache"]="/data_simple/.cache"
MOUNTS["${ROOT}/output"]="/data_simple/output/"
MOUNTS["${ROOT}/input"]="/data_simple/input/"
MOUNTS["${ROOT}/models"]="/data_simple/models/"
MOUNTS["${ROOT}/custom_nodes"]="/data_simple/custom_nodes/"
MOUNTS["${ROOT}/models/ultralytics"]="/data_simple/models/ultralytics"

for to_path in "${!MOUNTS[@]}"; do
  from_path="${MOUNTS[${to_path}]}"
  rm -rf "${to_path}"
  if [ ! -d "$from_path" ]; then
    mkdir -vp "$from_path"
  fi
  mkdir -vp "$(dirname "${to_path}")"
  ln -sT "${from_path}" "${to_path}"
  echo Mounted $(basename "${from_path}")
done

# Install dependencies from each custom_nodes folder
# for dir in /data_simple/custom_nodes/*; do
#     if [ -d "$dir" ]; then
#         if [ -f "$dir/requirements.txt" ]; then
#             echo "Installing dependencies for $dir"
#             python3 -m pip install -r "$dir/requirements.txt"
#         fi
#     fi
# done

exec "$@"
