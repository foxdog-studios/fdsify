#!/bin/bash

set -o errexit
set -o nounset

clean='false'
run='true'
setup='true'

usage='
    FDSifty

    Usage:

        $ fdsify.sh [-cRS] USER_1 LOGIN_1 PASSWORD_1 [...]

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

function spotify_pid
{
    pid=$(
        ps --no-header -o pid,comm -u "${1}" \
            | grep spotify \
            | cut --delimiter=' ' --fields=1
    )
    if [[ -z $pid ]]; then
        exit 1
    fi
    echo "${pid}"
}

function spotify_wid
{
    while true; do
        wids="$(xdotool search --pid "${1}" 2> /dev/null)"
        if [[ "$(echo "${wids}" | wc -l)" -eq 2 ]]; then
            break
        fi
        sleep 0.1
    done
    for wid in ${wids}; do
        if xdotool getwindowgeometry "${wid}" | grep --quiet 320x405; then
            echo "Logging in for user ${1}"
            xdotool type --window "${wid}" "${2}"
            xdotool key --window "${wid}" Tab
            xdotool type --window "${wid}" "${3}"
            xdotool key --window "${wid}" Return
            break
        fi
    done
}

function user_exists
{
    cut --delimiter=: --fields=1 /etc/passwd | grep --quiet -- "${1}"
}

function user_pids
{
    ps --no-header -o pid -u "${1}"
}

# =============================================================================
# = User details                                                              =
# =============================================================================

users=( '' )
logins=( '' )
passwords=( '' )

while [[ ${#} -gt 0 ]]; do
    users=( ${users[@]} ${1} )
    logins=( ${logins[@]} ${2} )
    passwords=( ${passwords[@]} ${3} )
    shift 3
done

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
    echo 'Running FDSify'

    pids=( '' )
    for (( i = 0 ; i < "${#users[@]}" ; i++ )); do
        user="${users[$i]}"
        login="${logins[$i]}"
        password="${passwords[$i]}"

        echo "Launching Spotify as ${user}"
        sudo su "${user}" spotify &> /dev/null &
        while ! pid=$(spotify_pid "${user}"); do
            sleep 0.1
        done
        echo "PID of ${user}'s Spotify is ${pid}"
        pids=( "${pids[@] }" "${pid}" )

        spotify_wid "${pid}" "${login}" "${password}"
    done
    unset pids[0]

    echo -n 'Waiting for all Spotify instances to exit ... '
    wait
    echo 'done'
fi

# =============================================================================
# = Clean up                                                                  =
# =============================================================================

if [[ "${clean}" == 'true' ]]; then
    echo 'Cleaning up'
    for user in ${users[@]}; do
        if user_exists "${user}"; then
            if pids=$(user_pids "${user}"); then
                echo "Killing all processes owned by ${user}"
                sudo kill -9 ${pids}
            fi

            echo "Deleting user ${user}"
            sudo userdel --remove "${user}" 2> /dev/null
        fi
    done
fi

