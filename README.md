# tensorflow-builder

This repository contains bash scripts that will automate generic TensorFlow builds using docker.
The script is designed to create a `.whl` file which can be installed via `pip`.

## Requirements

- `git`
- `docker`

## Usage

1. Clone this repository
   ```bash
   git clone https://github.com/knappmk/tensorflow-builder.git
   ```
1. Modify `.env` to set general build parameters (`TENSORFLOW_TAG` works with tags and branches)
1. Edit the bash script `build.sh` to modify TensorFlow compilation parameters
1. Start the procedure by invoking the bash script `start.sh`
   ```bash
    bash start.sh
   ```

## Hints

- The build process goes hand in hand with high CPU and memory usage<br>
  The resource usage can be controlled using the general build parameters `BAZEL_JOB_COUNT`, `BAZEL_RAM_RESOURCES`. For reference a ajob count of 8 consumes up to 25 GB of memory when building TensorFlow 2.1. You might consider to set up an additional swap file:
  ```bash
  dd if=/dev/zero of=/swapfile-tmp.img bs=10240 count=1M  # for 10 GB
  chmod 600 /swapfile-tmp.img
  mkswap /swapfile-tmp.img
  swapon /swapfile-tmp.img
  ```
- The compilation can take very long depending on your parameters
- The final file can be found in the `wheels` folder

## Procedure

The shell script will perform the following tasks:
- Clone TensorFlow github repository to a local folder
- Build the docker image using the `Dockerfile` provided by the TensorFlow repository (not all versions are available on [hub.docker.com](https://hub.docker.com/r/tensorflow/tensorflow/))
- Install NCCL in a new container
- Start the build process in that container
- Store the final `whl` file in the mounted directory
- Cleanup docker
- Remove cloned repository

## Credits

The compose build file and sources for TensorFlow can be found in the github [tensorflow repository](https://github.com/tensorflow/tensorflow).<br>
The build file is inspired by bash files that can be found in the [docker-tensorflow-builder](https://github.com/hadim/docker-tensorflow-builder) repository.

