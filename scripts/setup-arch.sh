#!/bin/bash

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

