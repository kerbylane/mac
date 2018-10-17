#!/usr/bin/env bash

# Produces a prompt just the way I want it. This relies on setting the one
# variable MY_HOST_NAME before calling it if I want the prompt to set the
# window title with a particular tag for the host.  Otherwise window titles
# will be set with the actual host name.

# color constants (https://en.wikipedia.org/wiki/ANSI_escape_code)
# regular colors
BLACK="\[\033[0;30m\]"
RED="\[\033[0;31m\]"
GREEN="\[\033[0;32m\]"
YELLOW="\[\033[0;33m\]"
BLUE="\[\033[0;34m\]"
MAGENTA="\033[0;35m"
CYAN="\[\033[0;36m\]"
WHITE="\[\033[0;37m\]"

# bold colors
BLACK_BOLD="\[\033[1;30m\]"
RED_BOLD="\[\033[1;31m\]"
GREEN_BOLD="\[\033[1;32m\]"
YELLOW_BOLD="\[\033[1;33m\]"
BLUE_BOLD="\[\033[1;34m\]"
MAGENTA_BOLD="\[\033[1;35m\]"
CYAN_BOLD="\[\033[1;36m\]"
WHITE_BOLD="\[\033[1;37m\]"

NONE="\[\033[0m\]" # Resets to default colors

# background colors
#BGK="\[\033[40m\]"
#BGR="\[\033[41m\]"
#BGG="\[\033[42m\]"
#BGY="\[\033[43m\]"
#BGB="\[\033[44m\]"
#BGM="\[\033[45m\]"
#BGC="\[\033[46m\]"
#BGW="\[\033[47m\]"

DATE_FORMAT="%m/%d %H:%M:%S"

# grab the git branch name of the current directory
git_branch() {
    echo $(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
}

# Returns a string representation of a time given in seconds.
function seconds_to_time() {
    gdate --date="@${1}" +"$DATE_FORMAT"
}

# Returns the number of seconds from a given time (date).
function time_to_seconds() {
    gdate --date="${1}" +"%s"
}

# Return a string representation of the current time.
function now() {
    gdate +"$DATE_FORMAT"
}

# Commands to be run before executing commands.
function before_commands {
    timer=${timer:-$SECONDS} # this syntax provides a default of $SECONDS if timer isn't set
    time_start=$(now)
}

# Returns a string representation of a number of seconds. If the number of seconds
# is less than 1 hour the format is MM:SS.  If it is more than an hour the format
# is H:MM:SS.
function duration_to_string() {
    local output=""
    local dur=$1
    if (( $dur > 3600 )); then
        hours=$(( $dur / 3600 ))
        output="${hours}:"
        dur=$(( $dur % 3600 ))
    fi

    min=$(( $dur / 60 ))
    sec=$(( $dur % 60 ))
    printf "${output}%02d:%02d" "${min}" "${sec}"
}

# produces the string we want to show the time of the last command.
function time_range_presentation() {
    # examples
    #  If dur < 1 sec just print the time
    #                                                              10/16 21:48:42
    #  if hours are the same only print distinct MM:SS
    #   10/16 21:48:42 - 10/16 21:57:02 ->           10/16 21:48:42 - 57:02 - dur
    #  if days are the same only print distinct HH:MM:SS
    #   10/16 21:48:42 - 10/16 23:57:02 ->        10/16 21:48:42 - 23:57:02 - dur
    #  otherwise print both fully
    #   10/16 21:48:42 - 10/17 01:57:02 ->  10/16 21:48:42 - 10/17 01:57:02 - dur

    [[ -z $timer_duration ]] && return 0

    if (( $timer_duration == 0 )); then
        printf "${time_start}"
        return 0
    fi

    # echo "timer_duration: $timer_duration"
    local dur_string=$(duration_to_string $timer_duration)

    local start_seconds=$(time_to_seconds "$time_start")
    # echo "got start_seconds: $start_seconds"
    local end_seconds=$(( $start_seconds + $timer_duration ))
    # echo "got end_seconds: $end_seconds"
    local time_end=$(seconds_to_time $end_seconds)
    # echo "got time_end: $time_end"
    # everything is the same from month through hours
    local START_PART=${time_start:0:8}
    local END_PART=${time_end:0:8}
    if [ "$START_PART" = "$END_PART" ]; then
        # echo "same through hours"
        printf "${time_start} - ${time_end:9}|${dur_string}"
        return 0
    fi

    # month and date are the same
    local START_PART=${time_start:0:5}
    local END_PART=${time_end:0:5}
    if [ "$START_PART" = "$END_PART" ]; then
        # echo "same through date"
        printf "${time_start} - ${time_end:6}|${dur_string}"
        return 0
    fi

    # not enough similarities that we want to shorten anything
    printf "${time_start} - ${time_end}|${dur_string}"
}

# Commands to be run after the next user command and before displaying the prompt.
function post_commands {
    # it seems that these must be very limited in order to avoid causing the trap
    # we use to call before_commands to be invoked.  But that may be due to how
    # I was testing it.
    timer_duration=$(( $SECONDS - $timer ))
    unset timer
}

# Set MY_HOST_NAME in ~/.bash_profile to the name you want in your window title bar
# Otherwise the actual host name will be used.
if [[ -z $MY_HOST_NAME ]]; then
    PROMPT_COLOR=${GREEN_BOLD}
    case $TERM in
        xterm*|rxvt*)
            TITLEBAR='\[\033]0;\h:${PWD}\007\]'
            ;;
        *)
            # This is what screen uses.
            # You can change this by putting the following into ~/.screenrc
            # term xterm
            TITLEBAR=""
            ;;
    esac
else
    TITLEBAR='\[\033]0;${MY_HOST_NAME}:${PWD}\007\]'
    PROMPT_COLOR=${CYAN_BOLD}
fi

# user's color
UC=$WHITE
[ $UID -eq "0" ] && UC=$RED   # root's color

# This trap command causes before_commands to be executed before any command is run
trap 'before_commands' DEBUG

# PROMPT_COMMAND is always eval-ed just after the last command finishes and
# before printing out the next prompt
if [[ -z $PROMPT_COMMAND ]]; then
    PROMPT_COMMAND="post_commands"
else
    PROMPT_COMMAND="$PROMPT_COMMAND; post_commands"
fi

# The color is set by that bit after $TITLEBAR, ${EMK}.  That goes all the way until ${NONE}
PS1="${TITLEBAR}${MAGENTA}\$(time_range_presentation) ${PROMPT_COLOR}\w ${YELLOW}\$(git_branch)${NONE}\n> "
# extra backslash in front of \$() to force execution
