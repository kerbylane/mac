#!/usr/bin/env bash

# Produces a prompt just the way I want it. This relies on setting the one
# variable MY_HOST_NAME before calling it if I want the prompt to set the
# window title with a particular tag for the host.  Otherwise window titles
# will be set with the actual host name.

# The general flow is that after the user hits enter the function before_commands()
# is invoked.  That records the starting time of the command.  When the command
# ends the function post_commands() is invoked.  That records the duration of the
# command.  When the prompt is displayed by PS1 the function
# time_range_presentation() is run.  That determines the end time and generates
# the desired time data presentation.  See notes on that function for details.

# color constants (https://en.wikipedia.org/wiki/ANSI_escape_code)
# regular colors
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
LIGHT_YELLOW="\033[0;93m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"

# bold colors
BLACK_BOLD="\033[1;30m"
RED_BOLD="\033[1;31m"
GREEN_BOLD="\033[1;32m"
YELLOW_BOLD="\033[1;33m"
BLUE_BOLD="\033[1;34m"
MAGENTA_BOLD="\033[1;35m"
CYAN_BOLD="\033[1;36m"
WHITE_BOLD="\033[1;37m"

NONE="\033[0m" # Resets to default colors

# background colors
#BGK="\033[40m"
#BGR="\033[41m"
#BGG="\033[42m"
#BGY="\033[43m"
#BGB="\033[44m"
#BGM="\033[45m"
#BGC="\033[46m"
#BGW="\033[47m"

DATE_FORMAT="%m/%d %H:%M:%S"
FIRST_COMMAND=true

# grab the git branch name of the current directory
git_branch() {
    echo $(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
}

# Returns a string representation of a time given in seconds.
function seconds_to_time() {
    date --date="@${1}" +"$DATE_FORMAT"
}

# Returns the number of seconds from a given time (date).
function time_to_seconds() {
    date --date="${1}" +"%s"
}

# Return a string representation of the current time.
function now() {
    date +"$DATE_FORMAT"
}

# Returns a string representation of a number of seconds. If the number of seconds
# is less than 1 hour the format is MM:SS.  If it is more than an hour the format
# is H:MM:SS.
function duration_to_string() {
    local output=""
    local dur=$1
    if (( dur > 3600 )); then
        (( hours = dur / 3600 ))
        output="${hours}:"
        (( dur = dur % 3600 ))
    fi

    (( min = dur / 60 ))
    (( sec = dur % 60 ))
    printf "${output}%02d:%02d" "${min}" "${sec}"
}

# Commands to be run before executing commands.
function before_commands {
    if [[ $FIRST_COMMAND = true ]]; then
        FIRST_COMMAND=false
    else
        return
    fi
    printf '\033[0m' # This turns colors off before the commands runs
    timer=${timer:-$SECONDS} # this syntax provides a default of $SECONDS if timer isn't set
    time_start=$(now)
}

# Commands to be run after the next user command and before displaying the prompt.
function precmd {
    # it seems that these must be very limited in order to avoid causing the trap
    # we use to call before_commands to be invoked.  But that may be due to how
    # I was testing it.
    (( timer_duration = SECONDS - timer ))
    unset timer
    FIRST_COMMAND=true
}

# produces the string we want to show the time of the last command.
function time_range_presentation() {
    # examples
    #  If dur == 0 sec just print the time
    #                                                              10/16 21:48:42
    #  if hours are the same only print distinct MM:SS
    #   10/16 21:48:42 - 10/16 21:57:02 ->           10/16 21:48:42 - 57:02 - dur
    #  if days are the same only print distinct HH:MM:SS
    #   10/16 21:48:42 - 10/16 23:57:02 ->        10/16 21:48:42 - 23:57:02 - dur
    #  otherwise print both fully
    #   10/16 21:48:42 - 10/17 01:57:02 ->  10/16 21:48:42 - 10/17 01:57:02 - dur

    [[ -z ${timer_duration} ]] && return 0

    (( timer_duration == 0 )) && printf "${time_start}" && return 0

    local dur_string=$(duration_to_string ${timer_duration})

    local start_seconds=$(time_to_seconds "$time_start")
    local end_seconds=$(( start_seconds + timer_duration ))
    local time_end=$(seconds_to_time ${end_seconds})

    local START_PART=${time_start:0:8}
    local END_PART=${time_end:0:8}
    local END_STRING=
    if [[ "${START_PART}" = "${END_PART}" ]]; then
        # It's the same hour, copy the end MM:SS
        END_STRING="${time_end:9}"
    else
        START_PART=${time_start:0:5}
        END_PART=${time_end:0:5}
        if [ "${START_PART}" = "${END_PART}" ]; then
            # It's the same date, copy the end time
            END_STRING="${time_end:6}"
        fi
    fi

    # If we haven't set END_STRING by now there are not enough similarities
    # that we want to shorten anything.
    [[ -z ${END_STRING} ]] && END_STRING="${time_end}"

    printf "${time_start} - ${END_STRING} | ${dur_string}"
}

# Set MY_HOST_NAME in ~/.bash_profile to the name you want in your window title bar
# Otherwise the actual host name will be used.
function title_bar() {
    if [[ -z ${MY_HOST_NAME} ]]; then
        PROMPT_COLOR=${GREEN_BOLD}
        case ${TERM} in
            xterm*|rxvt*)
                TITLEBAR="\033]0;\h:${PWD/#$HOME/~}\007"
                ;;
            *)
                # This is what screen uses.
                # You can change this by putting the following into ~/.screenrc
                # term xterm
                TITLEBAR=""
                ;;
        esac
    else
        TITLEBAR="\033]0;${MY_HOST_NAME}:${PWD}\007"
        PROMPT_COLOR=${CYAN_BOLD}
    fi
}

function full_prompt() {
    # Roughly we want the output to look like this:
    # "${TITLEBAR}${PROMPT_COLOR}\w ${YELLOW}\$(git_branch)\t${MAGENTA}\$(time_range_presentation)${NONE}\n> "
    title_bar # update variables for the title bar
    local time_range="$(time_range_presentation)"
    local branch=$(git_branch)
    local dir="${PWD/#$HOME/~}"
    if [[ -z ${branch} ]] || (( ${#branch} == 0 )); then
        local right_tab_width=$(( ${COLUMNS} - ${#dir} ))
        printf "${TITLEBAR}${PROMPT_COLOR}%s${MAGENTA}%*s${UC}\n> " \
            "${dir}" ${right_tab_width} "${time_range}"
    else
        local right_tab_width=$(( ${COLUMNS} - ${#dir} - ${#branch} - 1 ))
        printf "${TITLEBAR}${PROMPT_COLOR}%s ${GREEN}%s${MAGENTA}%*s${UC}\n> " \
            "${dir}" "${branch}" ${right_tab_width} "${time_range}"
    fi
}

# user's color
UC=${YELLOW}
[ $UID -eq "0" ] && UC=${RED}   # root's color

# This trap command causes before_commands to be executed before any command is run
trap 'before_commands' DEBUG

# extra backslash in front of \$() to force execution
PS1='$(full_prompt)'
