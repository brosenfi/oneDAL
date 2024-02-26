#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"

if [[ "${VSCODE__DEBUG_ENV_SET:-""}" == "yes" ]]; then
    echo "VSCode debug env already set, re-open terminal."
    return 0
fi

export VSCODE__DEBUG_ENV_SET="yes"

export MPIROOT=$CONDA_PREFIX
export ONEAPI_ROOT=/opt/intel/oneapi

if [[ "$CURRENT_COMPILER" =~ ^("icc"|"icx")$ ]]; then
    source /opt/intel/oneapi/compiler/latest/env/vars.sh
    source /opt/intel/oneapi/debugger/latest/env/vars.sh
    RELEASE_FOLDER="${WORKSPACE_FOLDER:-/workspaces/oneDAL}/__release_lnx"
else
    RELEASE_FOLDER="${WORKSPACE_FOLDER:-/workspaces/oneDAL}/__release_lnx_${CURRENT_COMPILER}"
fi

source /opt/intel/oneapi/tbb/latest/env/vars.sh intel64
export LD_LIBRARY_PATH="${RELEASE_FOLDER}/daal/latest/lib/intel64:${RELEASE_FOLDER}/tbb/latest/lib/intel64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
