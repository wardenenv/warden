# Setup history search ability (only bind when a tty is present)
if [ -t 1 ]; then
    bind '"\e[A":history-search-backward'
    bind '"\e[B":history-search-forward'
fi
