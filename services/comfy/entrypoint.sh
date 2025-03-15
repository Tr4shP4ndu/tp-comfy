#!/bin/bash

set -Eeuo pipefail

declare -A MOUNTS

MOUNTS["/root/.cache"]="/data/.cache"
MOUNTS["${ROOT}/output"]="/data/output/"
MOUNTS["${ROOT}/input"]="/data/input/"
MOUNTS["${ROOT}/custom_nodes"]="/data/custom_nodes/"
MOUNTS["${ROOT}/models/ultralytics"]="/data/models/ultralytics"

# Create and mount directories
for to_path in "${!MOUNTS[@]}"; do
  from_path="${MOUNTS[${to_path}]}"
  rm -rf "${to_path}"
  if [ ! -d "$from_path" ]; then
    mkdir -vp "$from_path"
  fi
  mkdir -vp "$(dirname "${to_path}")"
  ln -sT "${from_path}" "${to_path}"
  echo "Mounted $(basename "${from_path}")"
done

exec "$@"
