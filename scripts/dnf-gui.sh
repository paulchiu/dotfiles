#!/bin/sh

# Install apt-get GUI applications
sudo dnf update \
&& sudo dnf install -y \
  xclip \
  gvim \
  gpaste \
  gnome-shell-extension-gpaste \
  gnome-tweaks

# Install better fonts (to be tested)
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf copr enable dawid/better_fonts
dnf install fontconfig-enhanced-defaults fontconfig-font-replacements
