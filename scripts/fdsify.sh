#!/bin/bash

set -o errexit
set -o nounset

clean='false'
run='true'
setup='true'

usage='
    FDSifty

    Usage:

        $ fdsify.sh [-cRS] USER_1 [USER_2 ...]

    -c  Clean up before existing.

    -R  Do not run Spotify.

    -S  Do not perform set up.
'

while getopts ':cRS' opt; do
    case "${opt}" in
        c) clean='true' ;;
        R) run='false' ;;
        S) setup='false' ;;
        \?|*)
            echo "${usage}"
            exit 1
            ;;
    esac
done
shift $(( ${OPTIND} - 1 ))

if [[ ${#} -lt 1 ]]; then
    echo "${usage}"
    exit 1
fi

function user_exists
{
    cut --delimiter=: --fields=1 /etc/passwd | grep --quiet -- "${1}"
}

function user_pids
{
    ps -o pid -U "${1}" h
}

users=(${@})

# =============================================================================
# = Set up                                                                    =
# =============================================================================

if [[ "${setup}" == 'true' ]]; then
    echo 'Setting up FDSify.'
    for user in ${users[@]}; do
        if ! user_exists "${user}"; then
            echo "Creating user ${user}."
            sudo useradd --create-home "${user}"
        fi
    done
fi

# =============================================================================
# = Run                                                                       =
# =============================================================================

if [[ "${run}" == 'true' ]]; then
    echo 'Running FDSify.'
    for user in "${users[@]}"; do
        echo "Launching Spotify as ${user}."
        sudo su "${user}" spotify &> /dev/null &
    done
    echo -n 'Waiting for all Spotify instances to exit ... '
    wait
    echo 'done.'
fi

# =============================================================================
# = Clean up                                                                  =
# =============================================================================

if [[ "${clean}" == 'true' ]]; then
    echo 'Cleaning up.'
    for user in ${users[@]}; do
        if user_exists "${user}"; then
            if pids=$(user_pids "${user}"); then
                echo "Killing all processes owned by ${user}."
                sudo kill -9 ${pids}
            fi

            echo "Deleting user ${user}."
            sudo userdel --remove "${user}" 2> /dev/null
        fi
    done
fi

