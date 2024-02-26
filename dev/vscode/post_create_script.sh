#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"

#Env setup
sudo apt-get update \
	&& sudo apt-get -y install wget gnupg git make python3-setuptools doxygen \
	&& sudo apt-get -y install cmake ninja

# Install miniconda
export CONDA_DIR="/opt/conda"
sudo wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh \
    && sudo /bin/bash ~/miniconda.sh -b -p /opt/conda

# Put conda in path to use conda activate
export PATH="$CONDA_DIR/bin:$PATH"

# Installing environment for base development dependencies
sudo .ci/env/apt.sh dev-base

# Installing environment for DPCPP development dependencies
sudo .ci/env/apt.sh dpcpp

# Installing environment for clang-format
sudo .ci/env/apt.sh clang-format

# Installing environment for bazel
sudo wget https://github.com/bazelbuild/bazelisk/releases/download/v1.18.0/bazelisk-linux-amd64 \
    && sudo chmod 755 bazelisk-linux-amd64 \
    && sudo mv bazelisk-linux-amd64 /usr/bin/bazel

# Installing openBLAS dependency
.ci/env/openblas.sh

# Installing MKL dependency
./dev/download_micromkl.sh

# Installing oneTBB dependency
./dev/download_tbb.sh

. /opt/conda/etc/profile.d/conda.sh
conda activate base
conda init

sudo bash -c ". /opt/conda/etc/profile.d/conda.sh \
	&& conda activate base \
	&& conda install -y conda-forge::mpi4py"

echo "" >> ~/.bashrc
echo '. ${WORKSPACE_FOLDER:-/workspaces/oneDAL}/dev/vscode/source_debug_env.sh' >> ~/.bashrc
