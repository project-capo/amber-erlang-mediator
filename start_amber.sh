#!/bin/bash

set -x

export __dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mv ${__dir}/log/ ${__dir}/log-$(date +%s)/
mkdir ${__dir}/log/



cd ${__dir}
$(run_erl -daemon ${__dir}/pipes/ ${__dir}/log/ \
    'erl -boot start_sasl \
        -pa ${__dir}/apps/*/ebin \
        -pa ${__dir}/deps/*/ebin \
        -mnesia ${__dir}/priv/mnesia \
        -s mnesia \
        -s amber \
        -heart')
