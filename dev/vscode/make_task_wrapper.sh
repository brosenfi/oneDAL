#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"

cmd_args=("$@")

. /opt/conda/etc/profile.d/conda.sh

conda activate base

. $THIS_DIR/source_default_env.sh

make "${cmd_args[@]}"
