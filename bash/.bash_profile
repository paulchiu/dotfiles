HISTFILESIZE=1000000000
HISTSIZE=9999
export PS1="[\! \u:\w] "
alias ls="ls -Gh"
alias l="ls -lGh"
alias la="ls -lGah"
alias ll="ls -Gh"
alias v=vim
alias hs="history | grep "
alias gcam="git commit -a -m"
alias glg="git lg"
export NVM_DIR="$HOME/.nvm"
. "$(brew --prefix nvm)/nvm.sh"
. `brew --prefix`/etc/profile.d/z.sh
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
