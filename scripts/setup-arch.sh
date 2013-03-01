#!/bin/bash

# Copyright 2013 Foxdog Studios Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset

install_aur_packages=false

function usage
{
    echo '
    Install dependencies and set up repository

    Usage:

        $ setup-arch.sh [-a]

    -a  install AUR packages
'
    exit 1
}

while getopts :a opt; do
    case "${opt}" in
        a) install_aur_packages=true ;;
        \?|*) usage ;;
    esac
done
unset opt

shift $(( OPTIND - 1 ))

if [[ "${#}" -ne 0 ]]; then
    usage
fi

readonly REPO="$(
    realpath -- "$(
        dirname -- "$(
            realpath -- "${BASH_SOURCE[0]}"
        )"
    )/.."
)"

cd -- "${REPO}"

sudo pacman --needed --noconfirm -Sy \
        python \
        tk \
        wmctrl \
        xdotool

if $install_aur_packages; then
    yaourt --needed --noconfirm -Sy \
            ffmpeg-spotify \
            spotify
fi
unset install_aur_packages

echo '
Manual instructions:

    - You must use XMonad compiled with extended window manager hints.
'

