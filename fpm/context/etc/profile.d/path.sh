## these images use n versions (use same node as root); add /usr/local/bin to root $PATH
if [ $EUID = 0 ]; then
  PATH=$(echo "$PATH" | sed -E 's#(/usr/local/sbin)#\1:/usr/local/bin#')
fi

## support packages installed via pip into --user context
export PATH=~/.local/bin:$PATH

## support packages installed via `composer global require <packages>`
export PATH=~/.composer/vendor/bin:$PATH
