#!/bin/zsh

# Function to generate GitHub URL for a given file path
generate_github_url() {
    # Extract the repository name from the file path
    local repo_name=$(echo $1 | cut -d'/' -f1)

    # Remove the repository name from the file path
    local file_path_without_repo=$(echo $1 | cut -d'/' -f2-)

    # Construct the GitHub URL
    local github_url="https://github.com/mr-yum/${repo_name}/blob/main/${file_path_without_repo}"

    # Print the GitHub URL
    echo $github_url
}

# Function to handle command-line options
handle_options() {
    local file_path=$1
    local action=$2

    # Generate the GitHub URL
    local github_url=$(generate_github_url $file_path)

    # Perform the specified action
    case $action in
        -o)
            # Open the URL in the default web browser
            open $github_url
            ;;
        -c)
            # Copy the URL to the clipboard
            echo $github_url | pbcopy
            ;;
        *)
            echo "Invalid option: $action"
            exit 1
            ;;
    esac
}

# Check if a file path is provided
if [[ -z $1 ]]; then
    echo "Usage: $0 <file_path> [-o|-c]"
    exit 1
fi

# Check if an action is specified
if [[ -n $2 ]]; then
    handle_options $1 $2
else
    # Generate and print the GitHub URL
    generate_github_url $1
fi

