#!/bin/bash

# Used as $EDITOR/$VISUAL. Adds -w (wait) only for /tmp/ files so that CLI tools
# like `git commit` block until the editor closes, while normal `code` invocations
# return immediately.

OPTS=""
if [[ "$1" == /tmp/* ]]; then
    OPTS="-w"
fi

code ${OPTS:-} -a "$@"
