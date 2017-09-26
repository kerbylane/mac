set -o vi

alias vi='TERM=screen-bce vim'

export LANG=C

# Set the bash prompt
source ~/bash_prompt.sh
bash_prompt

export JAVA_HOME=$(/usr/libexec/java_home)

export MYSQL_PS1="\u@\d \R:\m:\s> "

# causes `ls` to color different types of contents (dir, executible, etc.).
export CLICOLOR=1
