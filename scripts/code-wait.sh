#!/bin/bash
OPTS=""
if [[ "$1" == /tmp/* ]]; then
    OPTS="-w"
fi

code ${OPTS:-} -a "$@"
