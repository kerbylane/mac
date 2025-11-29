#!/usr/bin/env zsh
#

# --- 1. ZSH SETUP ---

autoload -Uz add-zsh-hook
zmodload zsh/datetime # required for strftime

# --- 2. CONFIGURATION & GLOBALS ---
# DATE_FORMAT="%m/%d %H:%M:%S"
LAST_COMMAND_DURATION=0
COMMAND_START_SECONDS=$EPOCHSECONDS
COMMAND_ISSUED=false # track whether or not a command was run so we can update time correctly

if [[ -z ${MY_HOST_NAME} ]]; then
    PROMPT_COLOR="%F{green}"
else
    PROMPT_COLOR="%F{cyan}%B"
fi

# --- 3. UTILITY FUNCTIONS ---

function git_branch() {
    echo $(git rev-parse --abbrev-ref HEAD 2> /dev/null)
}

function seconds_to_time() {
    strftime "%m/%d %H:%M:%S" $1
}

function duration_to_string() {
    local dur=$1
    local output=""
    if (( dur > 3600 )); then
        (( hours = dur / 3600 ))
        output="${hours}:"
        (( dur = dur % 3600 ))
    fi

    (( min = dur / 60 ))
    (( sec = dur % 60 ))
    printf "${output}%02d:%02d" "${min}" "${sec}"
}

# --- 5. TIMING HOOKS ---

function zsh_prompt_preexec {
    # Run just before the command is executed. If no command is submitted this is not run.
    # That's why I'm using COMMAND_ISSUED, so zsh_prompt_precmd does the right thing.
    COMMAND_START_SECONDS=$EPOCHSECONDS
    COMMAND_ISSUED=true
}

function zsh_prompt_precmd {
    # Run just before presenting the prompt.
    if [[ $COMMAND_ISSUED == true ]]; then
        LAST_COMMAND_DURATION=$(( EPOCHSECONDS - COMMAND_START_SECONDS ))
    else
        LAST_COMMAND_DURATION=0
        # set COMMAND_START_SECONDS so that the current time is displayed
        COMMAND_START_SECONDS=$EPOCHSECONDS
    fi
    COMMAND_ISSUED=false
}

# --- 6. PROMPT DISPLAY FUNCTIONS ---

function time_range_presentation() {
    local time_start=$(seconds_to_time $COMMAND_START_SECONDS)
    
    (( LAST_COMMAND_DURATION == 0 )) && printf $time_start && return 0
    
    # figure out time_end
    local start_seconds=$COMMAND_START_SECONDS
    local end_seconds=$(( start_seconds + LAST_COMMAND_DURATION ))
    local time_end=$(seconds_to_time ${end_seconds})

    local END_STRING="${time_end}"
    # Can we simplify the END_STRING?
    local START_PART=${time_start[1,8]}
    local END_PART=${time_end[1,8]}

    if [[ "${START_PART}" == "${END_PART}" ]]; then
        # If the hours are the same only present the %m:%s
        END_STRING="${time_end[10,-1]}" 
    else
        # If the dates are the same only include the %h:%m:%s
        START_PART=${time_start[1,5]}
        END_PART=${time_end[1,5]}
        if [ "${START_PART}" == "${END_PART}" ]; then
            END_STRING="${time_end[7,-1]}"
        fi
    fi

    local dur_string=$(duration_to_string ${LAST_COMMAND_DURATION})

    printf "${time_start} - ${END_STRING} | ${dur_string}"
}

# Sets global TITLEBAR
function title_bar() {
    # Want it to be [hostname]:path or [hostname]:[git branch]:path
    local dir="${PWD/#$HOME/~}"
    
    local host_part=$MY_HOST_NAME
    [[ -z $host_part ]] && host_part=$(hostname -s)
    
    local branch=$(git_branch)
    [[ -n $branch ]] && branch=":$branch"
    
    TITLEBAR=$'%{\e]0;'"${host_part}${branch}:${dir}"$'\a%}'
}

function full_prompt() {
    title_bar 
    
    local time_range="$(time_range_presentation)"
    local time_length=${#time_range}
    
    local branch=$(git_branch)
    [[ -n $branch ]] && branch=" $branch"
    local branch_length=${#branch}
    
    local dir="${PWD/#$HOME/~}"
    local dir_length=${#dir}
    
    # Do we need to trim dir?
    # The space available for dir is dir_space. Including an extra 1 for padding.
    local dir_space=$(( COLUMNS - dir_length - branch_length - time_length - 1 ))
    if (( dir_space < 0 )); then
        dir_space=$(( dir_space - 3 ))
        dir="...${dir: -dir_space}"
    fi
    dir_length=${#dir}

    local padding_len=$(( COLUMNS - dir_length - branch_length - time_length))
    local padding
    printf -v padding "%*s" $padding_len ""
    
    local user_color="%F{yellow}"
    [ $UID -eq "0" ] && user_color="%F{red}%B"
    
    # Use printf to output the final string.
    # PROMPT_SUBST will expand the %F codes.
    # The ${TITLEBAR} variable now contains the correct,
    # wrapped escape sequence.
    printf "%s%s%s%s%s%s%s%s\n%s> " \
        "${TITLEBAR}" \
        "${PROMPT_COLOR}" \
        "${dir}" \
        "%F{green}%B" \
        "${branch}" \
        "%F{magenta}%b" \
        "${padding}" \
        "${time_range}" \
        "%f" # %f resets all
}

# --- 7. EXECUTION ---
setopt PROMPT_SUBST

add-zsh-hook preexec zsh_prompt_preexec
add-zsh-hook precmd zsh_prompt_precmd

PS1='$(full_prompt)'