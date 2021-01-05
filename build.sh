#!/usr/bash
set -e

if [[ "${USE_GPU}" = "1" ]] && [[ "${USE_NVIDIA_NCCL}" = "1" ]]; then
  apt update && apt install -y libnccl2 libnccl-dev && rm -rf /var/lib/lists/*
  export NCCL_VERSION=$(dpkg-query -W -f='${Version}\n' libnccl2 | sed 's/^\([0-9]\.[0-9]\)\..*/\1/')
fi
cd /
if [[ ! -d "tensorflow" ]]; then
  git clone --depth 1 --branch ${TF_TAG} "https://github.com/tensorflow/tensorflow.git"
fi
TF_ROOT=/tensorflow
cd $TF_ROOT

export TMP=/tmp

# Python path options
export PYTHON_BIN_PATH=$(which python)
export PYTHON_LIB_PATH="$($PYTHON_BIN_PATH -c 'import site; print(site.getsitepackages()[0])')"
export PYTHONPATH=${TF_ROOT}/lib
export PYTHON_ARG=${TF_ROOT}/lib

# Compilation parameters
# Some parameters might be depricated in newer versions of TensorFlow
export TF_NEED_CUDA=0
export TF_NEED_GCP=0  # might get disabled using --config=nogcp
export TF_CUDA_COMPUTE_CAPABILITIES=7.5,7.0,6.1,5.2,5.0,3.5,3.0
export TF_NEED_HDFS=0  # might get disabled using --config=nohdfs
export TF_NEED_OPENCL=0
export TF_NEED_JEMALLOC=1  # Need to be disabled on CentOS 6.6
export TF_ENABLE_XLA=0
export TF_NEED_VERBS=0
export TF_CUDA_CLANG=0
export TF_DOWNLOAD_CLANG=0
export TF_NEED_MKL=0
export TF_DOWNLOAD_MKL=0
export TF_NEED_MPI=0
export TF_NEED_S3=1
export TF_NEED_KAFKA=1
export TF_NEED_GDR=0
export TF_NEED_OPENCL_SYCL=0
export TF_SET_ANDROID_WORKSPACE=0
export TF_NEED_AWS=0  # might get disabled using --config=noaws
export TF_NEED_IGNITE=0
export TF_NEED_ROCM=0

# Compiler options
export GCC_HOST_COMPILER_PATH=$(which gcc)

# Here you can edit this variable to set any optimizations you want.
# export CC_OPT_FLAGS="-march=native"
export CC_OPT_FLAGS="-mmmx -msse -msse2 -msse3 -mssse3 -msse4 -msse4a -msse4.1 -msse4.2 -mavx -mavx2 -mfpmath=both"

if [[ "$USE_GPU" = "1" ]]; then
  # Cuda parameters
  export CUDA_HOME="/usr/local/cuda"
  export CUDA_TOOLKIT_PATH=$CUDA_HOME
  # export CUDNN_INSTALL_PATH=$CUDA_HOME
  # export TF_CUDA_VERSION="$CUDA_VERSION"
  # export TF_CUDNN_VERSION="$CUDNN_VERSION"
  export TF_NEED_CUDA=1
  export TF_NEED_TENSORRT=0

  if [[ "${USE_NVIDIA_NCCL}" = "1" ]]; then
    export TF_NCCL_VERSION=$NCCL_VERSION
    # export NCCL_INSTALL_PATH=$CUDA_HOME
  else
    export BAZEL_OPT_ARGS="${BAZEL_OPT_ARGS} --config=nonccl"
  fi

  # Those two lines are important for the linking step.
  export LD_LIBRARY_PATH="$CUDA_TOOLKIT_PATH/lib64:${LD_LIBRARY_PATH}"
  ldconfig
fi

# Compilation
./configure

if [ "$USE_GPU" -eq "1" ]; then

  bazel build --config=cuda \
              --linkopt="-lrt" \
              --linkopt="-lm" \
              --host_linkopt="-lrt" \
              --host_linkopt="-lm" \
              --action_env="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" \
              --jobs=${BAZEL_JOB_COUNT} \
              --local_cpu_resources=${BAZEL_CPU_RESOURCES} \
              --local_ram_resources=${BAZEL_RAM_RESOURCES} \
              ${BAZEL_OPT_ARGS} \
              //tensorflow/tools/pip_package:build_pip_package

  PACKAGE_NAME=tensorflow-gpu
  SUBFOLDER_NAME="${TF_TAG}"

else

  bazel build --linkopt="-lrt" \
              --linkopt="-lm" \
              --host_linkopt="-lrt" \
              --host_linkopt="-lm" \
              --action_env="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" \
              --jobs=${BAZEL_JOB_COUNT} \
              --local_cpu_resources=${BAZEL_CPU_RESOURCES} \
              --local_ram_resources=${BAZEL_RAM_RESOURCES} \
              ${BAZEL_OPT_ARGS} \
              //tensorflow/tools/pip_package:build_pip_package

  PACKAGE_NAME=tensorflow
  SUBFOLDER_NAME="${TF_TAG}"

fi

mkdir -p "/wheels/$SUBFOLDER_NAME"

bazel-bin/tensorflow/tools/pip_package/build_pip_package "/wheels/$SUBFOLDER_NAME" --project_name "$PACKAGE_NAME"

# Fix wheel folder permissions
chmod -R 777 /wheels/

exit 0
