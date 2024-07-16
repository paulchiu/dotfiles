#!/bin/zsh

# Check if the config file exists
if [[ ! -f ".ripgreprc" ]]; then
    echo "Config file .ripgreprc does not exist."
    exit 1
fi

# Check if the rg command is available
if ! command -v rg &> /dev/null; then
    echo "ripgrep (rg) command not found."
    exit 1
fi

# Set the RIPGREP_CONFIG_PATH environment variable
export RIPGREP_CONFIG_PATH=".ripgreprc"

# Check if an argument is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <search_pattern>"
    exit 1
fi

# Execute ripgrep with the provided argument
rg $@
