#!/bin/bash
OPTS=""
if [[ "$1" == /tmp/* ]]; then
    OPTS="-w"
fi

/opt/homebrew/bin/code ${OPTS:-} -a "$@"
