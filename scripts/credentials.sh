#!/bin/bash

set -o errexit
set -o nounset

readonly REPO="$(
    readlink -f -n -- "$(
        dirname -- "$(
            readlink -f -- "${BASH_SOURCE[0]}"
        )"
    )/../"
)"

cd -- "${REPO}"

mkdir -p config/
rm -f config/credentials

while true; do
    read -p 'Unix user: ' user
    read -p 'Spotify user: ' login
    read -p 'Spotify password: ' password
    echo "${user}" "${login}" "${password}" >> config/credentials
    read -p 'Another? [y]: ' response
    if [[ "${response}" != 'y' ]]; then
        break
    fi
done

