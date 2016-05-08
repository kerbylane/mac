bash_prompt() {

    # color constants
    # regular colors
    local K="\[\033[0;30m\]"    # black
    local R="\[\033[0;31m\]"    # red
    local G="\[\033[0;32m\]"    # green
    local Y="\[\033[0;33m\]"    # yellow
    local B="\[\033[0;34m\]"    # blue
    local M="\[\033[0;35m\]"    # magenta
    local C="\[\033[0;36m\]"    # cyan
    local W="\[\033[0;37m\]"    # white
    
    # emphasized (bolded) colors
    local EMK="\[\033[1;30m\]"
    local EMR="\[\033[1;31m\]"
    local EMG="\[\033[1;32m\]"
    local EMY="\[\033[1;33m\]"
    local EMB="\[\033[1;34m\]"
    local EMM="\[\033[1;35m\]"
    local EMC="\[\033[1;36m\]"
    local EMW="\[\033[1;37m\]"
    
    # background colors
    local BGK="\[\033[40m\]"
    local BGR="\[\033[41m\]"
    local BGG="\[\033[42m\]"
    local BGY="\[\033[43m\]"
    local BGB="\[\033[44m\]"
    local BGM="\[\033[45m\]"
    local BGC="\[\033[46m\]"
    local BGW="\[\033[47m\]"
    
    if [[ $(hostname -s) = Rajah ]]; then
        local TITLEBAR='\[\033]0;LAPTOP:${PWD}\007\]'
        local PROMPT_COLOR=${EMC}
    else
        local PROMPT_COLOR=${EMG}
        case $TERM in
            xterm*|rxvt*)
                # This adds user to the title
                # local TITLEBAR='\[\033]0;\u:${PWD}\007\]'
                # I want the host name
                local TITLEBAR='\[\033]0;\h:${PWD}\007\]'
                ;;
            *)
                # This is what screen uses.
                # You can change this by putting the following into ~/.screenrc
                # term xterm
                local TITLEBAR=""
                ;;
        esac
    fi
    local NONE="\[\033[0m\]"    # unsets color to term's fg color
    
    local UC=$W         # user's color
    [ $UID -eq "0" ] && UC=$R   # root's color
    
    # PS1="$TITLEBAR${EMC}$(date +"%Y/%m/%d %H:%M:%S") | \${PWD}${EMK}${UC} ${NONE}\n> "
    
    # The color is set by that bit after $TITLEBAR, ${EMK}.  That goes all the way until ${NONE}
    # PS1="$TITLEBAR${PROMPT_COLOR}$(date +"%Y/%m/%d %H:%M:%S") | \${PWD}${NONE}\n> "
    PS1="$TITLEBAR${PROMPT_COLOR}\d \t | \${PWD}${NONE}\n> "
    # without colors: PS1="[\u@\h \${NEW_PWD}]\\$ "
    # extra backslash in front of \$ to make bash colorize the prompt
}
