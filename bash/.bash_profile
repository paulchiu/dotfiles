HISTFILESIZE=1000000000
HISTSIZE=9999

# Set paths
export NVM_DIR="$HOME/.nvm"
export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"

# Load brew specific start-up scripts
if [[ -e /usr/local/bin/brew ]]; then
    . "/usr/local/opt/nvm/nvm.sh"
    . /usr/local/etc/profile.d/z.sh
fi

## Load z if installed
if [[ -e ~/bin/z.sh ]]; then
    . ~/bin/z.sh
fi

# Load start-up files
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;
