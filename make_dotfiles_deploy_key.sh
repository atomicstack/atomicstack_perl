#!/bin/bash
keyname=$(printf "%s_dotfiles_deploy_%s" $(hostname -s) $(date +%F))
ssh-keygen -C $keyname -f "$HOME/.ssh/${keyname}.pem" -t ed25519 -N ""
