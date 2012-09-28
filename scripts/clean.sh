#!/bin/bash

set -o errexit
set -o nounset
clean='false'

readonly REPO="$(
    readlink -f -n -- "$(
        dirname -- "$(
            readlink -f -- "${BASH_SOURCE[0]}"
        )"
    )/../"
)"

user1="${1}"
user2="${2}"

