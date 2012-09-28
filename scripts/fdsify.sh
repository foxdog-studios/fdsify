#!/bin/bash

set -o errexit
set -o nounset

clean='false'
run='true'
setup='true'

usage='
    FDSifty

    Usage:

        $ fdsify.sh [-cRS] [-d desktop_number] USER_1 LOGIN_1 PASSWORD_1 USER_2 LOGIN_2 PASSWORD_2

    -c  clean up before exiting

    -d  the number of the desktop to place the spotify windows on

    -R  do not run Spotify

    -S  do not perform set up
'
desktop_number=0
while getopts ':cd:RS' opt; do
    case "${opt}" in
        c) clean='true' ;;
        d) desktop_number="${OPTARG}" ;;
        R) run='false' ;;
        S) setup='false' ;;
        \?|*)
            echo "${usage}"
            exit 1
            ;;
    esac
done
shift $(( ${OPTIND} - 1 ))

if [[ ${#} -lt 3 ]]; then
    echo "${usage}"
    exit 1
fi

function spotify_pid
{
    pid=$(
        ps --no-header -o pid,comm -u "${1}" \
            | grep spotify \
            | sed 's/^ *//g' \
            | cut --delimiter=' ' --fields=1
    )
    if [[ -z $pid ]]; then
        exit 1
    fi
    echo "${pid}"
}

function spotify_wid
{
    local wid wids

    # Wait for the first proper window.
    while true; do
        wids="$(xdotool search --pid "${1}" 2> /dev/null)"
        if [[ "$(echo "${wids}" | wc -l)" -eq 2 ]]; then
            break
        fi
        sleep 0.1
    done

    # If required, log the user in.
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

    # Find the ID of the main windows.
    main_wid=''
    while [[ -z "${main_wid}" ]]; do
        wids="$(xdotool search --pid "${1}" 2> /dev/null)"
        for wid in ${wids}; do
            if [[ "$(xdotool getwindowname "${wid}")" == \
                  'Spotify Premium - Linux Preview' ]]; then
                main_wid="${wid}"
                break
            fi
        done
        sleep 0.1
    done
    echo "WID for Spodity instance with PID  ${1} is ${main_wid}"
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

users=( ${1} ${4} )
logins=( ${2} ${5} )
passwords=( ${3} ${6} )

# =============================================================================
# = Set up                                                                    =
# =============================================================================

if [[ "${setup}" == 'true' ]]; then
    echo 'Setting up FDSify.'
    for user in ${users[@]}; do
        if ! user_exists "${user}"; then
            echo "Creating user ${user}."
            sudo useradd --create-home --groups audio "${user}"
        fi
    done
fi

# =============================================================================
# = Run                                                                       =
# =============================================================================

if [[ "${run}" == 'true' ]]; then
    wids=( '' )
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

        spotify_wid "${pid}" "${login}" "${password}"
        wids=( "${wids[@]}" "${main_wid}" )
    done
    unset wids[0]

    for wid in ${wids[@]}; do
        wmctrl -i -r "${wid}" -t "${desktop_number}"
    done

    echo 'Launching FDSify'
    ./src/fdsify.py ${wids[@]}

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

