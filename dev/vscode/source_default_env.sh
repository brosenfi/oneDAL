#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"

export MPIROOT=$CONDA_PREFIX
export ONEAPI_ROOT=/opt/intel/oneapi

if [ "$CURRENT_COMPILER" == "icc" ]; then
	source /opt/intel/oneapi/compiler/latest/env/vars.sh
	source /opt/intel/oneapi/debugger/latest/env/vars.sh
fi
source /opt/intel/oneapi/tbb/latest/env/vars.sh intel64
