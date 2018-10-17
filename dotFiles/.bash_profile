set -o vi

alias vi='TERM=screen-bce vim'

export LANG=C

# Set the bash prompt
source ~/bash_prompt.sh

export MYSQL_PS1="\u@\d \R:\m:\s> "

# causes `ls` to color different types of contents (dir, executable, etc.).
export CLICOLOR=1
