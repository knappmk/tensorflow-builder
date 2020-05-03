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
function start_container() {
    docker run -v "$(pwd)/wheels:/wheels" -v "$(pwd):/scripts" -v "$(pwd)/tensorflow:/tensorflow" --env-file "$(pwd)/.env" -it --name tensorflow-${HW_TYPE}-build-${TENSORFLOW_TAG} tensorflow-${HW_TYPE}-builder:${TENSORFLOW_TAG} bash /scripts/build.sh
}

export_env

if [[ "${USE_GPU}" -eq "1" ]]; then
    HW_TYPE=gpu
else
    HW_TYPE=cpu
fi

# Clone tensorflow github repo
echo ">> Clone tensorflow repo"
if [[ ! -d "tensorflow" ]]; then
    git clone --depth 1 --branch ${TENSORFLOW_TAG} "https://github.com/tensorflow/tensorflow.git"
fi

# build docker image for build
echo ">> Build docker image for build"
if [[ "$(docker images -q tensorflow-gpu-builder:${TENSORFLOW_TAG} 2> /dev/null)" == "" ]]; then
    docker build --build-arg USE_PYTHON_3_NOT_2=${USE_PYTHON_3_NOT_2} -f tensorflow/tensorflow/tools/dockerfiles/dockerfiles/devel-${HW_TYPE}.Dockerfile -t tensorflow-${HW_TYPE}-builder:${TENSORFLOW_TAG} tensorflow/tensorflow/tools/dockerfiles
fi

# run build in docker
echo ">> Run build inside container"
if [[ "$(docker ps -aq -f name=tensorflow-${HW_TYPE}-build-${TENSORFLOW_TAG})" ]]; then
    while true; do
        read -p "Should the container be deleted first?" yn
        case $yn in
            [Yy]* ) docker rm tensorflow-${HW_TYPE}-build-${TENSORFLOW_TAG}; start_container; break;;
            [Nn]* ) docker start -ai tensorflow-${HW_TYPE}-build-${TENSORFLOW_TAG}; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
else
    start_container
fi

# docker clean up
echo ">> Docker cleanup"
docker rm tensorflow-${HW_TYPE}-build-${TENSORFLOW_TAG}
docker rmi tensorflow-${HW_TYPE}-builder:${TENSORFLOW_TAG}

# folder cleanup
echo ">> Deleting tensorflow repo"
rm -rf tensorflow

exit 0
