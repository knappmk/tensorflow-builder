#!/bin/bash
set -e

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
function build_image() {
    # clone tensorflow github repository containing Dockerfile
    echo ">> Clone tensorflow for build Dockerfile"
    if [[ -d "tensorflow" ]]; then
        rm -rf "tensorflow"
    fi
    git clone --depth 1 --branch ${TF_TAG_DOCKERFILE} "https://github.com/tensorflow/tensorflow.git"
    docker build --build-arg USE_PYTHON_3_NOT_2=${USE_PYTHON_3_NOT_2} --build-arg BAZEL_VERSION -f tensorflow/tensorflow/tools/dockerfiles/dockerfiles/devel-${HW_TYPE}.Dockerfile -t tensorflow-builder:${TF_TAG_DOCKERFILE}-${HW_TYPE} tensorflow/tensorflow/tools/dockerfiles
    rm -rf "tensorflow"
}
function start_container() {
    docker run -v "$(pwd)/wheels:/wheels" -v "$(pwd):/scripts" --env-file "$(pwd)/.env" -it --name tensorflow-build-${HW_TYPE}-${TF_TAG} tensorflow-builder:${TF_TAG_DOCKERFILE}-${HW_TYPE} bash /scripts/build.sh
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

# build docker image for build
echo ">> Build docker image for build"
if [[ "$(docker images -q tensorflow-builder:${TF_TAG_DOCKERFILE}-${HW_TYPE} 2> /dev/null)" == "" ]]; then
    build_image
else
    read -p "Should the image be rebuild [yN]? " yn
    case $yn in
        [Yy]* ) build_image;;
        * ) ;;
    esac
fi

# run build in docker
echo ">> Run build inside container"
if [[ "$(docker ps -aq -f name=tensorflow-build-${HW_TYPE}-${TF_TAG})" ]]; then
    read -p "Should the existing container be deleted first [yN]? " yn
    case $yn in
        [Yy]* ) docker rm tensorflow-build-${HW_TYPE}-${TF_TAG}; start_container;;
        * ) docker start -ai tensorflow-build-${HW_TYPE}-${TF_TAG};;
    esac
else
    start_container
fi

exit 0
