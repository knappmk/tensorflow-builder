# tensorflow-builder

This repository contains bash scripts that will automate **generic** TensorFlow builds using docker.
The script is designed to create a `.whl` file which can be installed via `pip`.

The default build parameters are set to support CPU instruction sets:
- MMX
- SSE, SSE2, SSE3, SSSE3, SSE4A, SSE4.1, SSE4.2
- AVX, AVX2

For GPU support defaults for compute capabilities are:
- 3.0, 3.5
- 5.0, 5.2
- 6.1
- 7.0, 7.5

## Requirements

- `git`
- `docker`

## Usage

1. Clone this repository
   ```bash
   git clone https://github.com/knappmk/tensorflow-builder.git
   ```
1. Modify `.env` to set general build parameters (`TF_TAG` works with tags and branches) <br>
   _Hint for building with GPU support:_<br>
   Check out for which CUDA version you want to build the wheel file. If you want to replace the existing TensorFlow pip package, have a look at the [release notes](https://github.com/tensorflow/tensorflow/releases) to figure out for which CUDA and cuDNN version it was build. After finding the relevant versions check out if the [`devel-gpu.Dockerfile`](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/dockerfiles/dockerfiles/devel-gpu.Dockerfile) file contains matching versions (select your desired branch or tag first). If not you might consider using a version of the Dockerfile in another branch or tag therefore set `TF_TAG_DOCKERFILE` and `TF_BAZEL_VERSION` accordingly. Especially use the same Bazel version as used in the desired build version of TensorFlow (can also be found in the original Dockerfile).
1. Edit the bash script `build.sh` to modify TensorFlow compilation parameters
1. Start the procedure by invoking the bash script `start.sh`
   ```bash
   bash start.sh
   ```

## Hints

- The build process goes hand in hand with high CPU and memory usage<br>
  The resource usage can be controlled using the general build parameters `BAZEL_JOB_COUNT`, `BAZEL_RAM_RESOURCES`. For reference a ajob count of 8 consumes up to 25 GB of memory when building TensorFlow 2.1. I encountered that setting `BAZEL_RAM_RESOURCES` might still get ignored and the bazel build still overfloods the memory (until freeze). You might consider to set up an additional swap file:
  ```bash
  dd if=/dev/zero of=/swapfile-tmp.img bs=10240 count=1M  # for 10 GB
  chmod 600 /swapfile-tmp.img
  mkswap /swapfile-tmp.img
  swapon /swapfile-tmp.img
  ```
- The compilation can take very long depending on your parameters
- The final file can be found in the `wheels` folder
- Tested TensorFlow build configurations can be found [here](https://www.tensorflow.org/install/source#tested_build_configurations)
- If you want an optimized build for your machine only change parameter `CC_OPT_FLAGS` to `-march=native` and set `TF_CUDA_COMPUTE_CAPABILITIES` to match your GPU
- For CPU optimization flags have a look at the [GNU Compiler Options](https://gcc.gnu.org/onlinedocs/gcc-5.5.0/gcc/x86-Options.html#x86-Options)
- For GPU compute capabilities you can have a look at the [CUDA Wikipedia article](https://en.wikipedia.org/wiki/CUDA#GPUs_supported)

## Procedure

The shell script will perform the following tasks:
- Clone TensorFlow github repository to a local folder
- Build the docker image using the `Dockerfile` provided by the TensorFlow repository (not all versions are available on [hub.docker.com](https://hub.docker.com/r/tensorflow/tensorflow/))
- Start the build process in a container
- Store the final `whl` file in the mounted directory
- Cleanup docker
- Remove cloned repository

## Tested parameters

| TF | Python |  GPU | TF Dockerfile | Bazel version | Bazel optional parameters | Comment |
| --- | --- | --- | --- | --- | --- | --- |
| v2.1.0 | 3 | Yes | v2.1.0 | 0.29.1 | --config=noaws --config=nogcp --config=nohdfs | OK |
| v2.1.0 | 3 | No | v2.1.0 | 0.29.1 | --config=noaws --config=nogcp --config=nohdfs | OK |
| v2.1.0 | 3 | Yes | r2.2 | 0.29.1 | --config=noaws --config=nogcp --config=nohdfs --config=nonccl | OK |
| v2.1.0 | 3 | No | r2.2 | 0.29.1 | --config=noaws --config=nogcp --config=nohdfs --config=nonccl | OK |

## Credits

The compose build file and sources for TensorFlow can be found in the github [tensorflow](https://github.com/tensorflow/tensorflow) repository.<br>
The build file is inspired by bash files that can be found in the [docker-tensorflow-builder](https://github.com/hadim/docker-tensorflow-builder) repository.

