#!/bin/bash
# Enable Touch ID for sudo and for the GUI auth dialogs raised by pkg-based
# Homebrew casks. /etc/pam.d/sudo already ships with "auth include sudo_local";
# writing sudo_local rather than editing sudo itself survives macOS updates.
set -e

sudo tee /etc/pam.d/sudo_local >/dev/null <<'PAM'
auth       sufficient     pam_tid.so
PAM
sudo chmod 644 /etc/pam.d/sudo_local

echo "Touch ID for sudo enabled."
