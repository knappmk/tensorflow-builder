#!/bin/bash

function export_env() {
  local envFile=${1:-.env}
  while IFS='=' read -r key temp || [ -n "$key" ]; do
    local isComment='^[[:space:]]*#'
    local isBlank='^[[:space:]]*$'
    [[ $key =~ $isComment ]] && continue
    [[ $key =~ $isBlank ]] && continue
    value=$(eval echo "$temp")
    export $key="$value"
  done < $envFile
}

export_env

if [[ "${USE_GPU}" -eq "1" ]]; then
    HW_TYPE=gpu
else
    HW_TYPE=cpu
fi
if [[ ! -n ${TF_TAG_DOCKERFILE} ]]; then
    export TF_TAG_DOCKERFILE=${TF_TAG}
fi

rm -rf "tensorflow"
docker rm tensorflow-build-${HW_TYPE}-${TF_TAG}
docker rmi tensorflow-builder:${TF_TAG_DOCKERFILE}-${HW_TYPE}

exit 0
