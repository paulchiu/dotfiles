#!/bin/zsh

usage() {
    echo "Usage: $0 <email-address>"
    echo ""
    echo "Check and remove an email address from AWS SES suppression list"
    echo ""
    echo "Arguments:"
    echo "  email-address    The email address to check and remove from suppression"
    echo ""
    echo "Examples:"
    echo "  $0 user@example.com"
    echo "  $0 rory.keegan@solotel.com.au"
    echo ""
    echo "Prerequisites:"
    echo "  - AWS CLI v2 must be installed and configured"
    echo "  - Appropriate AWS SES permissions required"
}

if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
    exit 0
fi

EMAIL="$1"

if [[ -z "$EMAIL" ]]; then
    echo "Error: Email address is required"
    usage
    exit 1
fi

echo "Checking suppression status for: $EMAIL"
if aws sesv2 get-suppressed-destination --email-address "$EMAIL" 2>/dev/null; then
    echo ""
    echo "Email is suppressed. Removing from suppression list..."
    if aws sesv2 delete-suppressed-destination --email-address "$EMAIL"; then
        echo "Successfully removed $EMAIL from suppression list"
    else
        echo "Failed to remove $EMAIL from suppression list"
        exit 1
    fi
else
    echo "Email $EMAIL is not in the suppression list"
fi