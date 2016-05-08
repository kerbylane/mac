# export PS1='\e[0;36m\]\d \t | LAPTOP:\w\[\e[0m\]\n> '

set -o vi

alias vi='TERM=screen-bce vim'

export LANG=C

# Set the bash prompt
source ~/bash_prompt.sh
bash_prompt

export JAVA_HOME=$(/usr/libexec/java_home)

export MYSQL_PS1="\u@\d \R:\m:\s> "

export PATH=/usr/local/git/bin:$PATH:~/bin

