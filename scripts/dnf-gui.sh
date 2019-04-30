#!/bin/sh

# Install apt-get GUI applications
sudo dnf update \
&& sudo dnf install -y \
  xclip \
  gvim \
  gpaste \
  gnome-shell-extension-gpaste \
  gnome-tweaks
