#!/bin/zsh

# Script to regenerate zsh completion caches and other cached values
# Run this after updating tools (fzf, jj, codex, mkcert)

set -e

echo "🔄 Refreshing zsh caches..."

# Create completions directory if it doesn't exist
mkdir -p ~/.zsh/completions

# Regenerate completion files
echo "  📦 Regenerating fzf completions..."
fzf --zsh > ~/.zsh/completions/_fzf.zsh 2>&1

echo "  📦 Regenerating jj completions..."
jj util completion zsh > ~/.zsh/completions/_jj.zsh 2>&1

echo "  📦 Regenerating codex completions..."
codex completion zsh > ~/.zsh/completions/_codex.zsh 2>&1

# Regenerate mkcert cache
echo "  🔐 Regenerating mkcert cache..."
mkcert -CAROOT > ~/.zsh/.mkcert_caroot 2>&1

echo "✅ Zsh caches refreshed successfully!"
echo "   Open a new terminal to see the changes."
