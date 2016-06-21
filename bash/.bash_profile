HISTFILESIZE=1000000000
HISTSIZE=9999

export NVM_DIR="$HOME/.nvm"
. "$(brew --prefix nvm)/nvm.sh"
. `brew --prefix`/etc/profile.d/z.sh
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;
