# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/paul/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="spaceship"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# OPTIMIZED: Removed zsh-nvm plugin for lazy loading
plugins=(git)
autoload -U add-zsh-hook

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

HISTFILESIZE=1000000000
HISTSIZE=9999

# OPTIMIZED: NVM lazy loading - only initialize when needed
export NVM_DIR="$HOME/.nvm"
_nvm_lazy_load() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm() { _nvm_lazy_load; nvm "$@"; }
node() { _nvm_lazy_load; node "$@"; }
npm() { _nvm_lazy_load; npm "$@"; }
npx() { _nvm_lazy_load; npx "$@"; }

export PATH="/usr/local/bin:/usr/local/sbin:~/bin:/Applications/Visual Studio Code.app/Contents/Resources/app/bin:/Applications/WebStorm.app/Contents/MacOS:~/.local/bin:$(go env GOPATH)/bin:$PATH"


# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# OPTIMIZED: NVM autoloader - now uses lazy-loaded version
load-nvmrc() {
  [[ -a .nvmrc ]] || return
  # Only load NVM if we actually need to switch versions
  if command -v nvm >/dev/null 2>&1; then
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$node_version" ]; then
        nvm use
      fi
    elif [ "$node_version" != "$(nvm version default)" ]; then
      echo "Reverting to nvm default version"
      nvm use default
    fi
  fi
}
add-zsh-hook chpwd load-nvmrc
# OPTIMIZED: Don't run load-nvmrc on shell startup
# load-nvmrc

function ya() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
source ~/.aliases
eval "$(starship init zsh)"

# OPTIMIZED: rbenv lazy loading
_rbenv_lazy_load() {
  unset -f ruby gem bundle rake
  eval "$(rbenv init - zsh)"
}
ruby() { _rbenv_lazy_load; ruby "$@"; }
gem() { _rbenv_lazy_load; gem "$@"; }
bundle() { _rbenv_lazy_load; bundle "$@"; }
rake() { _rbenv_lazy_load; rake "$@"; }

eval "$(zoxide init zsh)"

# OPTIMIZED: Cached mkcert output - regenerate cache with: mkcert -CAROOT > ~/.zsh/.mkcert_caroot
if [[ -f ~/.zsh/.mkcert_caroot ]]; then
  export NODE_EXTRA_CA_CERTS="$(cat ~/.zsh/.mkcert_caroot)/rootCA.pem"
else
  export NODE_EXTRA_CA_CERTS="$(mkcert -CAROOT)/rootCA.pem"
fi

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
# https://github.com/anthropics/claude-code/issues/40#issuecomment-2688171192
# export NODE_EXTRA_CA_CERTS=/etc/ssl/cert.pem

# Secret keys
[ -f "$HOME/.env.secret" ] && source "$HOME/.env.secret"

# pnpm
export PNPM_HOME="/Users/paul/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Created by `pipx` on 2025-01-27 08:40:10
export PATH="$PATH:/Users/paul/.local/bin"

# Custom functions
fpath=($HOME/.zsh/functions $fpath)
local autoload_functions=(
    fzf_to_context
    to_timezone
    cd_up_parent
    write_pull_request
    create_pull_request
    jj_rewrite_revision
)
autoload -Uz $autoload_functions

# OPTIMIZED: Use pre-generated completion files instead of command substitution
# Regenerate with: fzf --zsh > ~/.zsh/completions/_fzf.zsh
# Regenerate with: jj util completion zsh > ~/.zsh/completions/_jj.zsh
# Regenerate with: codex completion zsh > ~/.zsh/completions/_codex.zsh
[[ -f ~/.zsh/completions/_fzf.zsh ]] && source ~/.zsh/completions/_fzf.zsh || source <(fzf --zsh)
[[ -f ~/.zsh/completions/_jj.zsh ]] && source ~/.zsh/completions/_jj.zsh || source <(jj util completion zsh)
[[ -f ~/.zsh/completions/_codex.zsh ]] && source ~/.zsh/completions/_codex.zsh || source <(codex completion zsh)

# pip autocompletions
fpath+=~/.zfunc; autoload -Uz compinit; compinit

zstyle ':completion:*' menu select

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"

mryum_output=$(mryum export 2>/dev/null) && eval "$mryum_output"
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export GPG_TTY=$(tty)
